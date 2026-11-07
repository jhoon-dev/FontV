import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

@immutable
class FontFace {
  const FontFace({
    required this.id,
    required this.name,
    required this.family,
    required this.style,
  });
  final String id;
  final String name;
  final String family;
  final String style;
  factory FontFace.fromMap(Map<Object?, Object?> map) => FontFace(
    id: map['id'] as String,
    name: map['name'] as String,
    family: map['family'] as String,
    style: map['style'] as String? ?? 'Regular',
  );
  bool matches(String query) {
    final words = query.toLowerCase().trim().split(RegExp(r'\s+'));
    final haystack = '$name $family $style'.toLowerCase();
    return words.every(haystack.contains);
  }
}

class PreviewRequest {
  const PreviewRequest({
    required this.fontId,
    required this.text,
    required this.size,
    required this.color,
    required this.width,
    required this.height,
    this.scale = 2,
  });
  final String fontId;
  final String text;
  final double size;
  final int color;
  final double width;
  final double height;
  final double scale;
  Map<String, Object> toMap() => {
    'fontId': fontId,
    'text': text,
    'size': size,
    'color': color,
    'width': width,
    'height': height,
    'scale': scale,
  };
  String get cacheKey =>
      '$fontId\u0000$text\u0000$size/$color/$width/$height/$scale';
}

class FontService {
  static const channel = MethodChannel('com.isdow.fontv/fonts');
  final _cache = <String, Uint8List>{};
  final _pending = <String, Future<Uint8List>>{};
  int _cacheBytes = 0;
  static const _maxCacheBytes = 12 * 1024 * 1024;
  bool get isDemo =>
      kIsWeb ||
      (defaultTargetPlatform != TargetPlatform.iOS &&
          defaultTargetPlatform != TargetPlatform.android);

  Future<List<FontFace>> loadFonts() async {
    if (isDemo) return demoFonts;
    final rows = await channel.invokeListMethod<Object?>('getFonts');
    final fonts = (rows ?? [])
        .map((row) => FontFace.fromMap(row as Map<Object?, Object?>))
        .toList();
    fonts.sort(
      (a, b) => a.family.toLowerCase().compareTo(b.family.toLowerCase()) != 0
          ? a.family.toLowerCase().compareTo(b.family.toLowerCase())
          : a.name.compareTo(b.name),
    );
    return fonts;
  }

  Future<Uint8List> render(PreviewRequest request) {
    final key = request.cacheKey;
    final cached = _cache.remove(key);
    if (cached != null) {
      _cache[key] = cached;
      return Future.value(cached);
    }
    return _pending.putIfAbsent(key, () async {
      try {
        final data = await channel.invokeMethod<Uint8List>(
          'renderPreview',
          request.toMap(),
        );
        if (data == null) throw StateError('Empty font preview');
        _cache[key] = data;
        _cacheBytes += data.length;
        while (_cacheBytes > _maxCacheBytes && _cache.isNotEmpty) {
          _cacheBytes -= _cache.remove(_cache.keys.first)!.length;
        }
        return data;
      } finally {
        _pending.remove(key);
      }
    });
  }

  static const demoFonts = [
    FontFace(
      id: 'demo:regular',
      name: 'Default Sans',
      family: 'Preview Demo',
      style: 'Regular',
    ),
    FontFace(
      id: 'demo:bold',
      name: 'Default Sans Bold',
      family: 'Preview Demo',
      style: 'Bold',
    ),
    FontFace(
      id: 'demo:italic',
      name: 'Default Sans Italic',
      family: 'Preview Demo',
      style: 'Italic',
    ),
  ];
}

import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'font_service.dart';

/// The OS renders its own fonts, preserving collection indexes and variation axes.
class FontPreview extends StatefulWidget {
  const FontPreview({
    super.key,
    required this.service,
    required this.face,
    required this.text,
    required this.size,
    required this.color,
    this.thumbnail = false,
  });
  final FontService service;
  final FontFace face;
  final String text;
  final double size;
  final Color color;
  final bool thumbnail;
  @override
  State<FontPreview> createState() => _FontPreviewState();
}

class _FontPreviewState extends State<FontPreview> {
  Timer? _timer;
  String? _key;
  Uint8List? _bytes;
  bool _failed = false;
  int _generation = 0;
  void _request(PreviewRequest request) {
    if (_key == request.cacheKey) return;
    _key = request.cacheKey;
    final generation = ++_generation;
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: widget.thumbnail ? 0 : 90), () async {
      try {
        final bytes = await widget.service.render(request);
        if (mounted && generation == _generation) {
          setState(() {
            _bytes = bytes;
            _failed = false;
          });
        }
      } catch (_) {
        if (mounted && generation == _generation) {
          setState(() => _failed = true);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.service.isDemo) {
      return Align(
        alignment: Alignment.topLeft,
        child: Text(
          widget.text,
          maxLines: widget.thumbnail ? 1 : null,
          style: TextStyle(
            fontWeight: widget.face.id == 'demo:bold'
                ? FontWeight.bold
                : FontWeight.normal,
            fontStyle: widget.face.id == 'demo:italic'
                ? FontStyle.italic
                : FontStyle.normal,
            fontSize: widget.size,
            height: 1.35,
            color: widget.color,
          ),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, bounds) {
        if (bounds.maxWidth <= 0 || bounds.maxHeight <= 0) {
          return const SizedBox.shrink();
        }
        _request(
          PreviewRequest(
            fontId: widget.face.id,
            text: widget.text,
            size: widget.size,
            color: widget.color.toARGB32(),
            width: bounds.maxWidth,
            height: bounds.maxHeight,
            scale: MediaQuery.devicePixelRatioOf(context).clamp(1, 3),
          ),
        );
        if (_failed) {
          return Center(
            child: IconButton(
              tooltip: '미리보기 다시 불러오기',
              onPressed: () => setState(() {
                _key = null;
                _failed = false;
              }),
              icon: const Icon(Icons.refresh_rounded),
            ),
          );
        }
        if (_bytes == null) {
          return Center(
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: widget.color.withValues(alpha: .35),
              ),
            ),
          );
        }
        return Image.memory(
          _bytes!,
          fit: BoxFit.fill,
          gaplessPlayback: true,
          excludeFromSemantics: true,
        );
      },
    );
  }

  @override
  void didUpdateWidget(FontPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.face.id != widget.face.id) _bytes = null;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

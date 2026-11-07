import 'font_service.dart';

const _indexOrder = 'ABCDEFGHIJKLMNOPQRSTUVWXYZㄱㄴㄷㄹㅁㅂㅅㅇㅈㅊㅋㅌㅍㅎ#';

/// Groups the already filtered catalog, so search and favorites never reveal
/// faces that did not match the active filter.
List<FontFamilyGroup> groupFontFamilies(List<FontFace> fonts) {
  final families = <String, List<FontFace>>{};
  for (final face in fonts) {
    families.putIfAbsent(face.family, () => []).add(face);
  }
  final groups = families.entries.map((entry) {
    final faces = entry.value
      ..sort((a, b) {
        int regularFirst(FontFace face) =>
            const [
              'regular',
              'normal',
              'roman',
              'book',
            ].contains(face.style.toLowerCase())
            ? 0
            : 1;
        final regular = regularFirst(a).compareTo(regularFirst(b));
        if (regular != 0) return regular;
        final style = a.style.toLowerCase().compareTo(b.style.toLowerCase());
        return style != 0 ? style : a.name.compareTo(b.name);
      });
    return FontFamilyGroup(entry.key, List.unmodifiable(faces));
  }).toList();
  groups.sort((a, b) {
    final section = _indexOrder
        .indexOf(a.indexLabel)
        .compareTo(_indexOrder.indexOf(b.indexLabel));
    return section != 0
        ? section
        : a.family.toLowerCase().compareTo(b.family.toLowerCase());
  });
  return groups;
}

class FontFamilyGroup {
  const FontFamilyGroup(this.family, this.faces);
  final String family;
  final List<FontFace> faces;
  String get indexLabel => fontIndexLabel(family);
}

String fontIndexLabel(String family) {
  final name = family.trimLeft();
  if (name.isEmpty) return '#';
  final letter = name[0].toUpperCase();
  if (RegExp(r'^[A-Z]$').hasMatch(letter)) return letter;
  final code = name.runes.first;
  if (code >= 0xAC00 && code <= 0xD7A3) {
    const initials = [
      'ㄱ',
      'ㄱ',
      'ㄴ',
      'ㄷ',
      'ㄷ',
      'ㄹ',
      'ㅁ',
      'ㅂ',
      'ㅂ',
      'ㅅ',
      'ㅅ',
      'ㅇ',
      'ㅈ',
      'ㅈ',
      'ㅊ',
      'ㅋ',
      'ㅌ',
      'ㅍ',
      'ㅎ',
    ];
    return initials[(code - 0xAC00) ~/ 588];
  }
  if (_indexOrder.contains(letter)) return letter;
  return '#';
}

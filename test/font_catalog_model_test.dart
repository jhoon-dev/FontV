import 'package:flutter_test/flutter_test.dart';
import 'package:font_v/src/font_catalog_model.dart';
import 'package:font_v/src/font_service.dart';

FontFace face(String id, String family, String style) =>
    FontFace(id: id, name: '$family-$style', family: family, style: style);

void main() {
  test('non-adjacent styles form one family with Regular first', () {
    final fonts = [
      face('bold', 'Alpha', 'Bold'),
      face('beta', 'Beta', 'Regular'),
      face('regular', 'Alpha', 'Regular'),
      face('italic', 'Alpha', 'Italic'),
    ];
    final groups = groupFontFamilies(fonts);
    expect(groups.map((g) => g.family), ['Alpha', 'Beta']);
    expect(groups.first.faces.map((f) => f.id), ['regular', 'bold', 'italic']);
    expect(fonts.map((f) => f.id), ['bold', 'beta', 'regular', 'italic']);
    final filtered = groupFontFamilies(
      fonts.where((f) => f.matches('Alpha Bold')).toList(),
    );
    expect(filtered.single.faces.map((f) => f.id), ['bold']);
  });

  test(
    'index supports Latin, Korean initials and other scripts consistently',
    () {
      expect(fontIndexLabel('  apple'), 'A');
      expect(fontIndexLabel('까만고딕'), 'ㄱ');
      expect(fontIndexLabel('한글'), 'ㅎ');
      expect(fontIndexLabel('123 Serif'), '#');
      expect(fontIndexLabel('漢字'), '#');
      final groups = groupFontFamilies([
        face('other', '123 Serif', 'Regular'),
        face('korean', '한글', 'Regular'),
        face('z', 'Zulu', 'Regular'),
        face('a', 'Alpha', 'Regular'),
        face('g', '까만고딕', 'Regular'),
      ]);
      expect(groups.map((g) => g.indexLabel), ['A', 'Z', 'ㄱ', 'ㅎ', '#']);
    },
  );
}

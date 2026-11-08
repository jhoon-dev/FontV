import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:font_v/src/font_export.dart';
import 'package:font_v/src/font_service.dart';

class DeviceFontService extends FontService {
  @override
  bool get isDemo => false;
}

class DemoFontService extends FontService {
  @override
  bool get isDemo => true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  tearDown(() => messenger.setMockMethodCallHandler(FontService.channel, null));
  test(
    'coverage keeps supplementary and combining characters, excluding layout controls',
    () async {
      messenger.setMockMethodCallHandler(FontService.channel, (call) async {
        expect(call.method, 'checkGlyphs');
        expect((call.arguments as Map)['codePoints'], [
          65,
          0xd55c,
          0x1f600,
          101,
          0x301,
        ]);
        return [0x1f600, 0x301];
      });
      final coverage = await DeviceFontService().checkGlyphs(
        'font',
        'A 한😀e\u0301\ufe0f\u200d\n\t',
      );
      expect(coverage.missing, [0x1f600, 0x301]);
      expect(coverage.complete, false);
    },
  );
  test(
    'a missing native result never falsely claims complete coverage',
    () async {
      messenger.setMockMethodCallHandler(
        FontService.channel,
        (_) async => null,
      );
      await expectLater(
        DeviceFontService().checkGlyphs('font', 'A'),
        throwsStateError,
      );
      expect(
        (await DemoFontService().checkGlyphs('demo:regular', 'A')).available,
        false,
      );
    },
  );
  test(
    'typography participates in cache identity and reaches the renderer',
    () async {
      var calls = 0;
      messenger.setMockMethodCallHandler(FontService.channel, (call) async {
        calls++;
        final args = call.arguments as Map;
        expect(args['letterSpacing'], calls == 1 ? 0 : 2);
        return Uint8List.fromList([calls]);
      });
      final service = DeviceFontService();
      const first = PreviewRequest(
        fontId: 'font',
        text: 'AV',
        size: 36,
        color: 0xff111111,
        width: 200,
        height: 100,
      );
      const spaced = PreviewRequest(
        fontId: 'font',
        text: 'AV',
        size: 36,
        color: 0xff111111,
        width: 200,
        height: 100,
        letterSpacing: 2,
        lineHeight: 1.8,
        alignment: PreviewAlignment.right,
      );
      expect(await service.render(first), [1]);
      expect(await service.render(spaced), [2]);
      expect(await service.render(spaced), [2]);
      expect(calls, 2);
    },
  );
  test(
    'PNG export preserves transparent pixels, paper color and optional metadata area',
    () async {
      final recorder = ui.PictureRecorder();
      Canvas(recorder).drawRect(
        const Rect.fromLTWH(0, 0, 8, 8),
        Paint()..color = const Color(0xff00ff00),
      );
      final picture = recorder.endRecording();
      final source = await picture.toImage(108, 72);
      final encoded = await source.toByteData(format: ui.ImageByteFormat.png);
      final preview = encoded!.buffer.asUint8List();
      messenger.setMockMethodCallHandler(
        FontService.channel,
        (_) async => preview,
      );
      final exporter = FontImageExporter(DeviceFontService());
      const face = FontFace(
        id: 'font',
        name: 'Example',
        family: 'Example',
        style: 'Regular',
      );
      const request = PreviewRequest(
        fontId: 'font',
        text: 'AV',
        size: 36,
        color: 0xff111111,
        width: 54,
        height: 36,
      );
      Future<(ui.Image, ByteData)> decode(Uint8List bytes) async {
        final codec = await ui.instantiateImageCodec(bytes);
        final image = (await codec.getNextFrame()).image;
        codec.dispose();
        return (
          image,
          (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!,
        );
      }

      final transparent = await decode(
        await exporter.render(
          face: face,
          request: request,
          paper: Colors.white,
          includeInfo: false,
          transparent: true,
        ),
      );
      final opaque = await decode(
        await exporter.render(
          face: face,
          request: request,
          paper: const Color(0xffff0000),
        ),
      );
      expect(transparent.$2.getUint8(3), 0);
      expect(opaque.$2.getUint8(0), 255);
      expect(opaque.$2.getUint8(3), 255);
      final previewPixel = (48 * transparent.$1.width + 48) * 4;
      expect(transparent.$2.getUint8(previewPixel + 1), 255);
      expect(opaque.$1.height - transparent.$1.height, 156);
      transparent.$1.dispose();
      opaque.$1.dispose();
      source.dispose();
      picture.dispose();
    },
  );
}

import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:font_v/src/font_service.dart';

class NativeTestService extends FontService {
  @override
  bool get isDemo => false;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  tearDown(() => messenger.setMockMethodCallHandler(FontService.channel, null));

  test('channel catalog parses and sorts by family and name', () async {
    messenger.setMockMethodCallHandler(
      FontService.channel,
      (call) async => [
        {'id': 'b', 'name': 'Beta', 'family': 'Beta', 'style': 'Bold'},
        {'id': 'a', 'name': 'Alpha', 'family': 'Alpha', 'style': 'Regular'},
      ],
    );
    final faces = await NativeTestService().loadFonts();
    expect(faces.map((font) => font.id), ['a', 'b']);
  });

  test(
    'identical in-flight previews merge and cached results avoid native work',
    () async {
      final gate = Completer<Uint8List>();
      var requests = 0;
      messenger.setMockMethodCallHandler(FontService.channel, (call) async {
        requests++;
        expect((call.arguments as Map)['fontId'], 'test');
        return gate.future;
      });
      final service = NativeTestService();
      const request = PreviewRequest(
        fontId: 'test',
        text: 'Aa',
        size: 32,
        color: 0xFF000000,
        width: 120,
        height: 80,
      );
      final first = service.render(request);
      final second = service.render(request);
      await Future<void>.delayed(Duration.zero);
      gate.complete(Uint8List.fromList([1, 2, 3]));
      expect(await first, [1, 2, 3]);
      expect(await second, [1, 2, 3]);
      expect(await service.render(request), [1, 2, 3]);
      expect(requests, 1);
    },
  );

  test(
    'failed native render can be retried and color is part of cache identity',
    () async {
      var requests = 0;
      messenger.setMockMethodCallHandler(FontService.channel, (call) async {
        if (++requests == 1) throw PlatformException(code: 'FONT_ERROR');
        return Uint8List.fromList([requests]);
      });
      final service = NativeTestService();
      const dark = PreviewRequest(
        fontId: 'test',
        text: 'Aa',
        size: 32,
        color: 0xFF000000,
        width: 120,
        height: 80,
      );
      const light = PreviewRequest(
        fontId: 'test',
        text: 'Aa',
        size: 32,
        color: 0xFFFFFFFF,
        width: 120,
        height: 80,
      );
      await expectLater(
        service.render(dark),
        throwsA(isA<PlatformException>()),
      );
      expect(await service.render(dark), [2]);
      expect(await service.render(light), [3]);
      expect(requests, 3);
    },
  );
}

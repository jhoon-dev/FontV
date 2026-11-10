import 'dart:io';
import 'package:file_selector_platform_interface/file_selector_platform_interface.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:font_v/src/ads.dart';
import 'package:font_v/src/font_service.dart';

class SavePicker extends FileSelectorPlatform {
  String? path;
  @override
  Future<FileSaveLocation?> getSaveLocation({
    List<XTypeGroup>? acceptedTypeGroups,
    SaveDialogOptions options = const SaveDialogOptions(),
  }) async {
    expect(options.suggestedName, 'FontV.png');
    expect(acceptedTypeGroups!.single.extensions, ['png']);
    return path == null ? null : FileSaveLocation(path!);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late FileSelectorPlatform originalPicker;
  setUp(() => originalPicker = FileSelectorPlatform.instance);
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    FileSelectorPlatform.instance = originalPicker;
    messenger.setMockMethodCallHandler(FontService.channel, null);
  });
  for (final platform in [TargetPlatform.windows, TargetPlatform.macOS]) {
    test('${platform.name} loads real fonts and keeps ads disabled', () async {
      debugDefaultTargetPlatformOverride = platform;
      messenger.setMockMethodCallHandler(FontService.channel, (call) async {
        expect(call.method, 'getFonts');
        return [
          {'id': 'native-face', 'name': 'Native Face', 'family': 'Native'},
        ];
      });
      final service = FontService();
      expect(service.isDemo, false);
      expect((await service.loadFonts()).single.id, 'native-face');
      final ads = AdsController();
      await ads.start();
      expect(ads.supported, false);
      expect(ads.canShowAds, false);
      ads.dispose();
    });
    test('${platform.name} saves PNG to the chosen path and cancels', () async {
      debugDefaultTargetPlatformOverride = platform;
      final directory = await Directory.systemTemp.createTemp('fontv-save-');
      addTearDown(() => directory.delete(recursive: true));
      final file = File('${directory.path}/FontV.png');
      final picker = SavePicker()..path = file.path;
      FileSelectorPlatform.instance = picker;
      // Desktop saving must not call the mobile saveImage channel.
      messenger.setMockMethodCallHandler(FontService.channel, (_) async {
        fail('Desktop saving called the mobile channel');
      });
      final bytes = Uint8List.fromList([137, 80, 78, 71]);
      final service = FontService();
      expect(await service.saveImage(bytes, 'FontV.png'), true);
      expect(await file.readAsBytes(), bytes);
      picker.path = null;
      expect(await service.saveImage(bytes, 'FontV.png'), false);
      expect(await directory.list().length, 1);
    });
  }
  test('unsupported Linux keeps the explicit demo catalog', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    final service = FontService();
    expect(service.isDemo, true);
    expect(await service.loadFonts(), FontService.demoFonts);
  });
}

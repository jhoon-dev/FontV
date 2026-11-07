import 'dart:io';
import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() => integrationDriver(
  onScreenshot: (name, bytes, [args]) async {
    final folder = Directory('artifacts/screenshots')
      ..createSync(recursive: true);
    if (name.contains('android')) {
      // The host capture includes the native video surface as well as Flutter.
      final capture = await Process.run('adb', [
        '-s',
        'emulator-5554',
        'exec-out',
        'screencap',
        '-p',
      ], stdoutEncoding: null);
      if (capture.exitCode != 0) return false;
      bytes = capture.stdout as List<int>;
    }
    await File('${folder.path}/$name.png').writeAsBytes(bytes);
    return true;
  },
);

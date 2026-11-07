import 'package:flutter/material.dart';
import 'src/app.dart';
import 'src/controller.dart';
import 'src/font_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(FontVApp(controller: FontController(service: FontService())));
}

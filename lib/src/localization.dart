import 'package:flutter/widgets.dart';
import '../l10n/app_localizations.dart';
import 'controller.dart';

extension LocalizedContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

extension FontMessages on AppLocalizations {
  String loadIssue(FontLoadIssue issue) => switch (issue) {
    FontLoadIssue.empty => fontLoadEmpty,
    FontLoadIssue.unavailable => fontLoadFailed,
  };
  String storageIssue(FontStorageIssue issue) => switch (issue) {
    FontStorageIssue.read => storageReadFailed,
    FontStorageIssue.write => storageWriteFailed,
  };
  String skinName(FontSkin skin) => switch (skin) {
    FontSkin.pink => themePink,
    FontSkin.red => themeRed,
    FontSkin.green => themeGreen,
    FontSkin.brown => themeBrown,
    FontSkin.purple => themePurple,
  };
}

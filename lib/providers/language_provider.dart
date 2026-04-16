import 'package:flutter/material.dart';
import '../services/hive_service.dart';

class LanguageProvider extends ChangeNotifier {
  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  LanguageProvider() {
    _loadLanguage();
  }

  void _loadLanguage() {
    String? savedLang = HiveService.settingsBox.get('languageCode');
    if (savedLang != null) {
      _locale = Locale(savedLang);
      notifyListeners();
    }
  }

  Future<void> setLanguage(String langCode) async {
    _locale = Locale(langCode);
    await HiveService.settingsBox.put('languageCode', langCode);
    notifyListeners();
  }

  bool get isLanguageSet => HiveService.settingsBox.get('languageCode') != null;
}

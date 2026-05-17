import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Notifier that manages the app locale and persists it to the database.
class LocaleNotifier extends Notifier<Locale?> {
  @override
  Locale? build() => null; // null = use system locale

  void setLocale(Locale locale) {
    state = locale;
  }

  void setFromString(String? languageCode) {
    if (languageCode == null || languageCode.isEmpty) {
      state = null;
      return;
    }
    state = Locale(languageCode);
  }

  String? get languageCode => state?.languageCode;
}

/// Global locale provider.
final localeProvider = NotifierProvider<LocaleNotifier, Locale?>(
  LocaleNotifier.new,
);

/// All supported locales in PocketLedger.
const List<Locale> supportedLocales = [
  Locale('en'), // English
  Locale('hi'), // Hindi
  Locale('ar'), // Arabic (RTL)
];

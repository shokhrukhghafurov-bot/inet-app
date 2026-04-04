import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../core/api/dio_client.dart';
import '../../../core/storage/secure_storage_service.dart';

final localeControllerProvider = ChangeNotifierProvider<LocaleController>((ref) {
  return LocaleController(ref.watch(secureStorageProvider));
});

class LocaleController extends ChangeNotifier {
  LocaleController(this._storage);

  final SecureStorageService _storage;
  Locale _locale = const Locale('ru');

  Locale get locale => _locale;

  Future<void> load() async {
    final value = await _storage.readLocale();
    if (value == null || value.isEmpty) {
      return;
    }
    _locale = Locale(value);
    notifyListeners();
  }

  Future<void> setLanguageCode(String code) async {
    if (_locale.languageCode == code) {
      return;
    }
    _locale = Locale(code);
    await _storage.writeLocale(code);
    notifyListeners();
  }
}

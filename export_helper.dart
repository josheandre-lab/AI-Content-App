import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/services.dart';

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier();
});

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(const AppSettings()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final languageCode = await SecureStorageService.getLanguage();
      final themeModeStr = await SecureStorageService.getThemeMode();
      final apiKey = await SecureStorageService.getApiKey();
      final dailyCount = await SecureStorageService.getDailyUsageCount();
      final lastDate = await SecureStorageService.getLastUsageDate();

      state = state.copyWith(
        language: AppLanguage.fromCode(languageCode),
        themeMode: _parseThemeMode(themeModeStr),
        apiKey: apiKey,
        dailyUsageCount: dailyCount,
        lastUsageDate: lastDate,
      );
    } catch (e) {
      debugPrint('Error loading settings: $e');
    }
  }

  Future<void> setLanguage(AppLanguage language) async {
    await SecureStorageService.setLanguage(language.code);
    state = state.copyWith(language: language);
  }

  Future<void> setThemeMode(ThemeMode themeMode) async {
    await SecureStorageService.setThemeMode(themeMode.name);
    state = state.copyWith(themeMode: themeMode);
  }

  Future<void> setApiKey(String? apiKey) async {
    await SecureStorageService.setApiKey(apiKey);
    state = state.copyWith(apiKey: apiKey);
    await GeminiService.initialize();
  }

  Future<void> deleteApiKey() async {
    await SecureStorageService.deleteApiKey();
    state = state.copyWith(apiKey: null);
    await GeminiService.initialize();
  }

  Future<void> refreshDailyLimit() async {
    final status = await SecureStorageService.checkDailyLimit();
    final dailyCount = await SecureStorageService.getDailyUsageCount();
    final lastDate = await SecureStorageService.getLastUsageDate();
    
    state = state.copyWith(
      dailyUsageCount: dailyCount,
      lastUsageDate: lastDate,
    );
  }

  ThemeMode _parseThemeMode(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}
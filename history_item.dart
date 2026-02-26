import 'package:freezed_annotation/freezed_annotation.dart';
import 'enums/app_language.dart';

part 'app_settings.freezed.dart';

@freezed
class AppSettings with _$AppSettings {
  const factory AppSettings({
    @Default(AppLanguage.english) AppLanguage language,
    @Default(ThemeMode.system) ThemeMode themeMode,
    String? apiKey,
    @Default(0) int dailyUsageCount,
    @Default('') String lastUsageDate,
  }) = _AppSettings;

  const AppSettings._();

  bool get hasApiKey => apiKey != null && apiKey!.isNotEmpty;
  
  bool get isDailyLimitReached => dailyUsageCount >= 3;
  
  int get remainingDailyUsage => (3 - dailyUsageCount).clamp(0, 3);
}

enum ThemeMode { system, light, dark }
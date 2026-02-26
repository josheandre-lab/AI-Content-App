import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_PKCS1Padding,
      storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
    ),
    iOptions: IOSOptions(
      accountName: 'ai_content_assistant_key',
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  static const String _apiKeyKey = 'gemini_api_key';
  static const String _dailyUsageCountKey = 'daily_usage_count';
  static const String _lastUsageDateKey = 'last_usage_date';
  static const String _languageKey = 'app_language';
  static const String _themeModeKey = 'theme_mode';

  // API Key
  static Future<String?> getApiKey() async {
    try {
      return await _storage.read(key: _apiKeyKey);
    } catch (e) {
      debugPrint('Error reading API key: $e');
      return null;
    }
  }

  static Future<void> setApiKey(String? apiKey) async {
    try {
      if (apiKey == null || apiKey.isEmpty) {
        await _storage.delete(key: _apiKeyKey);
      } else {
        await _storage.write(key: _apiKeyKey, value: apiKey.trim());
      }
    } catch (e) {
      debugPrint('Error writing API key: $e');
    }
  }

  static Future<void> deleteApiKey() async {
    try {
      await _storage.delete(key: _apiKeyKey);
    } catch (e) {
      debugPrint('Error deleting API key: $e');
    }
  }

  // Daily Usage
  static Future<int> getDailyUsageCount() async {
    try {
      final value = await _storage.read(key: _dailyUsageCountKey);
      return int.tryParse(value ?? '0') ?? 0;
    } catch (e) {
      debugPrint('Error reading daily usage: $e');
      return 0;
    }
  }

  static Future<void> setDailyUsageCount(int count) async {
    try {
      await _storage.write(key: _dailyUsageCountKey, value: count.toString());
    } catch (e) {
      debugPrint('Error writing daily usage: $e');
    }
  }

  // Last Usage Date (UTC)
  static Future<String> getLastUsageDate() async {
    try {
      return await _storage.read(key: _lastUsageDateKey) ?? '';
    } catch (e) {
      debugPrint('Error reading last usage date: $e');
      return '';
    }
  }

  static Future<void> setLastUsageDate(String date) async {
    try {
      await _storage.write(key: _lastUsageDateKey, value: date);
    } catch (e) {
      debugPrint('Error writing last usage date: $e');
    }
  }

  // Language
  static Future<String> getLanguage() async {
    try {
      return await _storage.read(key: _languageKey) ?? 'en';
    } catch (e) {
      debugPrint('Error reading language: $e');
      return 'en';
    }
  }

  static Future<void> setLanguage(String languageCode) async {
    try {
      await _storage.write(key: _languageKey, value: languageCode);
    } catch (e) {
      debugPrint('Error writing language: $e');
    }
  }

  // Theme Mode
  static Future<String> getThemeMode() async {
    try {
      return await _storage.read(key: _themeModeKey) ?? 'system';
    } catch (e) {
      debugPrint('Error reading theme mode: $e');
      return 'system';
    }
  }

  static Future<void> setThemeMode(String themeMode) async {
    try {
      await _storage.write(key: _themeModeKey, value: themeMode);
    } catch (e) {
      debugPrint('Error writing theme mode: $e');
    }
  }

  // Daily Limit Check
  static Future<DailyLimitStatus> checkDailyLimit() async {
    try {
      final lastDate = await getLastUsageDate();
      final currentDate = _getUtcDateString();
      final usageCount = await getDailyUsageCount();

      // Reset if new day
      if (lastDate != currentDate) {
        await setDailyUsageCount(0);
        await setLastUsageDate(currentDate);
        return DailyLimitStatus(0, 3, false);
      }

      // Check for clock rollback abuse
      if (lastDate.isNotEmpty && currentDate.compareTo(lastDate) < 0) {
        // Clock was rolled back, treat as limit reached for security
        return DailyLimitStatus(usageCount, 0, true);
      }

      final isLimitReached = usageCount >= 3;
      return DailyLimitStatus(usageCount, 3 - usageCount, isLimitReached);
    } catch (e) {
      debugPrint('Error checking daily limit: $e');
      return DailyLimitStatus(0, 3, false);
    }
  }

  static Future<void> incrementDailyUsage() async {
    try {
      final currentCount = await getDailyUsageCount();
      final currentDate = _getUtcDateString();
      await setDailyUsageCount(currentCount + 1);
      await setLastUsageDate(currentDate);
    } catch (e) {
      debugPrint('Error incrementing daily usage: $e');
    }
  }

  static String _getUtcDateString() {
    final now = DateTime.now().toUtc();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  // Clear all data
  static Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      debugPrint('Error clearing storage: $e');
    }
  }
}

class DailyLimitStatus {
  final int used;
  final int remaining;
  final bool isLimitReached;

  const DailyLimitStatus(this.used, this.remaining, this.isLimitReached);
}
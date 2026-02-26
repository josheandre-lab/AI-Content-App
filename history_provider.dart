enum AppLanguage {
  english('English', 'en'),
  turkish('Türkçe', 'tr');

  final String displayName;
  final String code;

  const AppLanguage(this.displayName, this.code);

  static AppLanguage fromCode(String code) {
    return AppLanguage.values.firstWhere(
      (e) => e.code == code.toLowerCase(),
      orElse: () => AppLanguage.english,
    );
  }
}
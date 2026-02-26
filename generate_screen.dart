enum PlatformType {
  youtube('YouTube', 'youtube'),
  shorts('Shorts', 'shorts'),
  reels('Reels', 'reels'),
  tiktok('TikTok', 'tiktok');

  final String displayName;
  final String value;

  const PlatformType(this.displayName, this.value);

  static PlatformType fromString(String value) {
    return PlatformType.values.firstWhere(
      (e) => e.value == value.toLowerCase(),
      orElse: () => PlatformType.youtube,
    );
  }
}
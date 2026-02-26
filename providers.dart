enum DurationType {
  s15('15s', 15, 60, 90),
  s30('30s', 30, 120, 160),
  s60('60s', 60, 220, 320),
  m3('3m', 180, 500, 700),
  m8('8m', 480, 1200, 1600);

  final String displayName;
  final int seconds;
  final int minWords;
  final int maxWords;

  const DurationType(
    this.displayName,
    this.seconds,
    this.minWords,
    this.maxWords,
  );

  static DurationType fromString(String value) {
    return DurationType.values.firstWhere(
      (e) => e.displayName == value,
      orElse: () => DurationType.s60,
    );
  }

  String get wordCountGuideline => '$minWords-$maxWords words';
}
enum ToneType {
  casual('Casual', 'casual'),
  funny('Funny', 'funny'),
  serious('Serious', 'serious'),
  emotional('Emotional', 'emotional'),
  informative('Informative', 'informative'),
  corporate('Corporate', 'corporate');

  final String displayName;
  final String value;

  const ToneType(this.displayName, this.value);

  static ToneType fromString(String value) {
    return ToneType.values.firstWhere(
      (e) => e.value == value.toLowerCase(),
      orElse: () => ToneType.casual,
    );
  }
}
enum GoalType {
  views('Views', 'views'),
  followers('Followers', 'followers'),
  sales('Sales', 'sales'),
  comments('Comments', 'comments');

  final String displayName;
  final String value;

  const GoalType(this.displayName, this.value);

  static GoalType fromString(String value) {
    return GoalType.values.firstWhere(
      (e) => e.value == value.toLowerCase(),
      orElse: () => GoalType.views,
    );
  }
}
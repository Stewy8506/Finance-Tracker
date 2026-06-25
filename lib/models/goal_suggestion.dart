enum GoalSuggestionType {
  increaseSip,
  delayGoal,
  reduceTargetAmount,
  delayPurchases,
}

class GoalSuggestion {
  final String goalId;
  final String goalName;
  final GoalSuggestionType type;
  final String title;
  final String description;
  final String impact;
  final double impactScore; // 0-100 for ranking
  final int targetYear;

  // Payloads for applying
  final double? suggestedSipPct;
  final int? suggestedTargetYear;
  final double? suggestedTargetAmount;
  final List<String>? purchasesToDelay; // List of purchase IDs

  GoalSuggestion({
    required this.goalId,
    required this.goalName,
    required this.type,
    required this.title,
    required this.description,
    required this.impact,
    required this.impactScore,
    required this.targetYear,
    this.suggestedSipPct,
    this.suggestedTargetYear,
    this.suggestedTargetAmount,
    this.purchasesToDelay,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GoalSuggestion &&
          runtimeType == other.runtimeType &&
          goalId == other.goalId &&
          type == other.type &&
          title == other.title &&
          description == other.description &&
          impact == other.impact &&
          impactScore == other.impactScore &&
          targetYear == other.targetYear &&
          suggestedSipPct == other.suggestedSipPct &&
          suggestedTargetYear == other.suggestedTargetYear &&
          suggestedTargetAmount == other.suggestedTargetAmount &&
          _listEquals(purchasesToDelay, other.purchasesToDelay);

  @override
  int get hashCode =>
      goalId.hashCode ^
      type.hashCode ^
      title.hashCode ^
      description.hashCode ^
      impact.hashCode ^
      impactScore.hashCode ^
      targetYear.hashCode ^
      suggestedSipPct.hashCode ^
      suggestedTargetYear.hashCode ^
      suggestedTargetAmount.hashCode ^
      (purchasesToDelay?.join(',').hashCode ?? 0);

  bool _listEquals(List<String>? a, List<String>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

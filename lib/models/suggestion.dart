enum SuggestionType {
  extendEmi,       // stretch EMI duration
  convertToEmi,    // cash → EMI
  delayPurchase,   // push firstYear forward
  spreadMonths,    // change targetMonth to reduce clustering
  reduceInterest,  // pay cash instead of high-interest EMI
  staggerEmis,     // separate overlapping EMIs
  incomeAlign,     // delay to match income growth
  levelSpike,      // move purchase out of a spike year
  goalConflict,    // move purchase away from goal year
  combo,           // pair of suggestions applied together
  opportunityCost, // informational: opportunity cost of purchase
  skipAndInvest,   // informational: skip purchase & invest
  reduceSip,       // temporary SIP reduction
}

class Suggestion {
  final String purchaseId;
  final String purchaseName;
  final SuggestionType type;
  final String title;           // e.g. "Spread out your January purchases"
  final String description;     // e.g. "Move Laptop from Jan to Apr..."
  final String impact;          // e.g. "Frees up ₹45,000 in January"
  final double impactScore;     // 0–100
  final int targetYear;
  
  // The "Apply" payload — exactly what fields to change:
  final int? suggestedEmiMonths;
  final double? suggestedEmiRate;
  final int? suggestedFirstYear;
  final int? suggestedTargetMonth;

  // New fields for Smart Suggestions v2:
  final List<Suggestion>? comboChildren;
  final double? suggestedSipPct;
  final int? sipRestoreYear;

  Suggestion({
    required this.purchaseId,
    required this.purchaseName,
    required this.type,
    required this.title,
    required this.description,
    required this.impact,
    required this.impactScore,
    required this.targetYear,
    this.suggestedEmiMonths,
    this.suggestedEmiRate,
    this.suggestedFirstYear,
    this.suggestedTargetMonth,
    this.comboChildren,
    this.suggestedSipPct,
    this.sipRestoreYear,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Suggestion &&
          runtimeType == other.runtimeType &&
          purchaseId == other.purchaseId &&
          type == other.type &&
          title == other.title &&
          description == other.description &&
          impact == other.impact &&
          impactScore == other.impactScore &&
          targetYear == other.targetYear &&
          suggestedEmiMonths == other.suggestedEmiMonths &&
          suggestedEmiRate == other.suggestedEmiRate &&
          suggestedFirstYear == other.suggestedFirstYear &&
          suggestedTargetMonth == other.suggestedTargetMonth &&
          comboChildren == other.comboChildren &&
          suggestedSipPct == other.suggestedSipPct &&
          sipRestoreYear == other.sipRestoreYear;

  @override
  int get hashCode =>
      purchaseId.hashCode ^
      type.hashCode ^
      title.hashCode ^
      description.hashCode ^
      impact.hashCode ^
      impactScore.hashCode ^
      targetYear.hashCode ^
      suggestedEmiMonths.hashCode ^
      suggestedEmiRate.hashCode ^
      suggestedFirstYear.hashCode ^
      suggestedTargetMonth.hashCode ^
      comboChildren.hashCode ^
      suggestedSipPct.hashCode ^
      sipRestoreYear.hashCode;
}

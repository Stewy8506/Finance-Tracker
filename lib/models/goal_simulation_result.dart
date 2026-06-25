class GoalSimulationResult {
  final int? fundedYearBefore;
  final int? fundedYearAfter;
  final double corpusYear5Before;
  final double corpusYear5After;
  final double corpusYear10Before;
  final double corpusYear10After;

  GoalSimulationResult({
    this.fundedYearBefore,
    this.fundedYearAfter,
    required this.corpusYear5Before,
    required this.corpusYear5After,
    required this.corpusYear10Before,
    required this.corpusYear10After,
  });
}

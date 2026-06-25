class SimulationResult {
  final double corpusYear5Before;
  final double corpusYear5After;
  final double corpusYear10Before;
  final double corpusYear10After;
  final List<int> deficitYearsBefore;  
  final List<int> deficitYearsAfter;   // empty = deficit resolved
  final List<String> goalsDelayed;     // goals that get delayed by applying this
  final List<String> goalsAccelerated; // goals that get funded earlier

  SimulationResult({
    required this.corpusYear5Before,
    required this.corpusYear5After,
    required this.corpusYear10Before,
    required this.corpusYear10After,
    required this.deficitYearsBefore,
    required this.deficitYearsAfter,
    required this.goalsDelayed,
    required this.goalsAccelerated,
  });
}

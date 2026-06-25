import 'package:hive/hive.dart';

part 'suggestion_history.g.dart';

@HiveType(typeId: 7)
class SuggestionHistoryEntry extends HiveObject {
  @HiveField(0)
  String suggestionTitle;

  @HiveField(1)
  String type;

  @HiveField(2)
  double impactScore;

  @HiveField(3)
  DateTime appliedAt;

  @HiveField(4)
  double cashFlowImpact;

  SuggestionHistoryEntry({
    required this.suggestionTitle,
    required this.type,
    required this.impactScore,
    required this.appliedAt,
    required this.cashFlowImpact,
  });
}

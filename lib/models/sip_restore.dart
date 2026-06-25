import 'package:hive/hive.dart';

part 'sip_restore.g.dart';

@HiveType(typeId: 8)
class SipRestore extends HiveObject {
  @HiveField(0)
  double originalSipPct;

  @HiveField(1)
  int restoreYear;

  SipRestore({
    required this.originalSipPct,
    required this.restoreYear,
  });
}

import 'package:hive/hive.dart';
import '../models/user_profile.dart';

const int currentSchemaVersion = 2;

Future<void> runMigrations() async {
  final metaBox = await Hive.openBox('metadata');
  final lastVersion = metaBox.get('schema_version', defaultValue: 1) as int;

  if (lastVersion < 2) {
    final profileBox = Hive.box<UserProfile>('user_profile');
    if (profileBox.isNotEmpty) {
      final profile = profileBox.values.first;
      bool modified = false;
      if (profile.hikeBracketsRaw == null) {
        profile.hikeBracketsRaw = [];
        modified = true;
      }
      if (profile.emergencyFundBalance == null) {
        profile.emergencyFundBalance = 0.0;
        modified = true;
      }
      if (profile.startYear == null) {
        profile.startYear = DateTime.now().year;
        modified = true;
      }
      if (profile.otherAssets == null) {
        profile.otherAssets = 0.0;
        modified = true;
      }
      if (profile.liabilities == null) {
        profile.liabilities = 0.0;
        modified = true;
      }
      if (modified) {
        await profileBox.putAt(0, profile);
      }
    }
    await metaBox.put('schema_version', 2);
  }
}

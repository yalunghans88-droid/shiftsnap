import 'package:hive_ce/hive.dart';

part 'user_preferences.g.dart';

@HiveType(typeId: 3)
class UserPreferences extends HiveObject {
  @HiveField(0)
  int reminderMinutesBefore;

  UserPreferences({
    this.reminderMinutesBefore = 60,
  });
}
import 'package:hive_ce/hive.dart';

part 'scanned_roster.g.dart';

@HiveType(typeId: 2)
class ScannedRoster extends HiveObject {
  @HiveField(0)
  String imagePath;

  @HiveField(1)
  DateTime dateScanned;

  @HiveField(2)
  int? durationDays;

  ScannedRoster({
    required this.imagePath,
    required this.dateScanned,
    this.durationDays,
  });
}
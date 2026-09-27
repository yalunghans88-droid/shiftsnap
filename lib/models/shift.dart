import 'package:hive_ce/hive.dart';

part 'shift.g.dart';

@HiveType(typeId: 1)
class Shift extends HiveObject {
  @HiveField(0)
  String title;

  @HiveField(1)
  DateTime date;

  @HiveField(2)
  String startTime; // "HH:mm"

  @HiveField(3)
  String endTime; // "HH:mm"

  @HiveField(4)
  String? description;

  @HiveField(5)
  bool confirmed;

  Shift({
    required this.title,
    required this.date,
    required this.startTime,
    required this.endTime,
    this.description,
    this.confirmed = false,
  });

  /// Combined start DateTime for sorting and countdowns.
  DateTime get startDateTime {
    final parts = startTime.split(':');
    return DateTime(
      date.year,
      date.month,
      date.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }

  /// Combined end DateTime.
  DateTime get endDateTime {
    final parts = endTime.split(':');
    return DateTime(
      date.year,
      date.month,
      date.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }
}
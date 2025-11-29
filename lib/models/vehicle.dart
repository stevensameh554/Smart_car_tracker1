import 'package:hive/hive.dart';

part 'vehicle.g.dart';

@HiveType(typeId: 2)
class Vehicle {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String deviceId; // Foreign key to Device

  @HiveField(2)
  final String name; // e.g., "Family Car", "Work Van"

  @HiveField(3)
  final String carModel; // e.g., "Toyota Camry"

  @HiveField(4)
  final int currentMileage;

  @HiveField(5)
  final int createdAtMs;

  /// Distances for this vehicle (per-vehicle totals)
  @HiveField(6)
  final int todayDistance;

  @HiveField(7)
  final int yesterdayDistance;

  @HiveField(8)
  final int lastWeekDistance;

  Vehicle({
    required this.id,
    required this.deviceId,
    required this.name,
    required this.carModel,
    required this.currentMileage,
    required this.createdAtMs,
    this.todayDistance = 0,
    this.yesterdayDistance = 0,
    this.lastWeekDistance = 0,
  });
}

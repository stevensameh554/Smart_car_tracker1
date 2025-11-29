// lib/models/maintenance_item.dart
import 'package:hive/hive.dart';

part 'maintenance_item.g.dart';

@HiveType(typeId: 0)
class MaintenanceItem extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  /// interval in kilometers
  @HiveField(2)
  int intervalKm;

  /// interval in days (time-based)
  @HiveField(3)
  int intervalDays;

  /// last service mileage (kilometers)
  @HiveField(4)
  int lastServiceMileage;

  /// last service date stored as milliseconds since epoch
  @HiveField(5)
  int lastServiceDateMs;
  
  /// Optional vehicle id this maintenance item belongs to
  @HiveField(6)
  String? vehicleId;

  MaintenanceItem({
    required this.id,
    required this.name,
    required this.intervalKm,
    required this.intervalDays,
    required this.lastServiceMileage,
    required this.lastServiceDateMs,
    this.vehicleId,
  });

  DateTime get lastServiceDate =>
      DateTime.fromMillisecondsSinceEpoch(lastServiceDateMs);
}

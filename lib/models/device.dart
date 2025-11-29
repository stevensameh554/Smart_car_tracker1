import 'package:hive/hive.dart';

part 'device.g.dart';

@HiveType(typeId: 1)
class Device {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name; // e.g., "My Tesla"

  @HiveField(2)
  final String carModel; // e.g., "Tesla Model 3"

  @HiveField(3)
  final int currentMileage;

  @HiveField(4)
  final int createdAtMs;

  Device({
    required this.id,
    required this.name,
    required this.carModel,
    required this.currentMileage,
    required this.createdAtMs,
  });
}

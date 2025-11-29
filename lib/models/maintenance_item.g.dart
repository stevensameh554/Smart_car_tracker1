// lib/models/maintenance_item.g.dart
// GENERATED CODE - manually provided adapter for Hive

part of 'maintenance_item.dart';

class MaintenanceItemAdapter extends TypeAdapter<MaintenanceItem> {
  @override
  final int typeId = 0;

  @override
  MaintenanceItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (var i = 0; i < numOfFields; i++) {
      final field = reader.readByte();
      fields[field] = reader.read();
    }
    return MaintenanceItem(
      id: fields[0] as String,
      name: fields[1] as String,
      intervalKm: fields[2] as int,
      intervalDays: fields[3] as int,
      lastServiceMileage: fields[4] as int,
      lastServiceDateMs: fields[5] as int,
      vehicleId: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, MaintenanceItem obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.intervalKm)
      ..writeByte(3)
      ..write(obj.intervalDays)
      ..writeByte(4)
      ..write(obj.lastServiceMileage)
      ..writeByte(5)
      ..write(obj.lastServiceDateMs);
    
    // vehicleId
    writer
      ..writeByte(6)
      ..write(obj.vehicleId);
  }
}

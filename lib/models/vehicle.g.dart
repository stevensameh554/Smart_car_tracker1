part of 'vehicle.dart';

class VehicleAdapter extends TypeAdapter<Vehicle> {
  @override
  final int typeId = 2;

  @override
  Vehicle read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Vehicle(
      id: fields[0] as String,
      deviceId: fields[1] as String,
      name: fields[2] as String,
      carModel: fields[3] as String,
      currentMileage: fields[4] as int,
      createdAtMs: fields[5] as int,
      todayDistance: (fields[6] as int?) ?? 0,
      yesterdayDistance: (fields[7] as int?) ?? 0,
      lastWeekDistance: (fields[8] as int?) ?? 0,
    );
  }

  @override
  void write(BinaryWriter writer, Vehicle obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.deviceId)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.carModel)
      ..writeByte(4)
      ..write(obj.currentMileage)
      ..writeByte(5)
      ..write(obj.createdAtMs);
    // distances
    writer
      ..writeByte(6)
      ..write(obj.todayDistance)
      ..writeByte(7)
      ..write(obj.yesterdayDistance)
      ..writeByte(8)
      ..write(obj.lastWeekDistance);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VehicleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

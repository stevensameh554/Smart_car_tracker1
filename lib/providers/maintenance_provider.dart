import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/maintenance_item.dart';

class MaintenanceProvider extends ChangeNotifier {
  static const String boxName = 'maintenance_items';
  int currentMileage = 0;
  int todayDistance = 0;
  // Optional stored distances for other periods (can be wired to real trip history later)
  int yesterdayDistance = 0;
  int lastWeekDistance = 0;

  List<MaintenanceItem> items = [];
  late Box<MaintenanceItem> box;

  // Getter for todayDistance (for dashboard)
  int get todayDistanceValue => todayDistance;

  // Getter for overdueCount (for dashboard)
  int get overdueCount => items.where((i) => isOverdue(i)).length;

  // Return distance for the requested period. Period values: 'Today', 'Yesterday', 'Last week'
  int distanceForPeriod(String period) {
    switch (period) {
      case 'Yesterday':
        // If no explicit value stored, make a reasonable fallback (60% of today)
        return yesterdayDistance > 0 ? yesterdayDistance : (todayDistance * 0.6).round();
      case 'Last week':
        return lastWeekDistance > 0 ? lastWeekDistance : (todayDistance * 4).round();
      case 'Today':
      default:
        return todayDistance;
    }
  }

  // Allow setting distances (useful if/when you add trip history)
  void setDistanceForPeriod(String period, int km) {
    switch (period) {
      case 'Yesterday':
        yesterdayDistance = km;
        break;
      case 'Last week':
        lastWeekDistance = km;
        break;
      case 'Today':
      default:
        todayDistance = km;
        break;
    }
    notifyListeners();
  }

  // Simulate car movement (for dashboard)
  void simulateMovement(int km) {
    currentMileage += km;
    todayDistance += km;
    // Removed call to save();
    notifyListeners();
  }

  // Calculate km left for an item (for dashboard)
  int kmLeft(MaintenanceItem item) {
    return (item.lastServiceMileage + item.intervalKm) - currentMileage;
  }

  Future<void> init() async {
    box = Hive.box<MaintenanceItem>(boxName);
    items = box.values.toList();
    notifyListeners();
  }

  // ADD MAINTENANCE ITEM
  Future<void> addItem({
    required String name,
    required int intervalKm,
    required int intervalDays,
    required int lastServiceMileage,
    required DateTime lastServiceDate,
  }) async {
    final item = MaintenanceItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      intervalKm: intervalKm,
      intervalDays: intervalDays,
      lastServiceMileage: lastServiceMileage,
      lastServiceDateMs: lastServiceDate.millisecondsSinceEpoch,
    );
    await box.put(item.id, item);
    items = box.values.toList();
    notifyListeners();
  }

  // REMOVE MAINTENANCE ITEM
  Future<void> removeItem(String id) async {
    await box.delete(id);
    items = box.values.toList();
    notifyListeners();
  }

  // UPDATE SERVICE NOW
  Future<void> updateServiceNow(String id, int mileageNow) async {
    final item = box.get(id);
    if (item != null) {
      item.lastServiceMileage = mileageNow;
      item.lastServiceDateMs = DateTime.now().millisecondsSinceEpoch;
      await box.put(id, item);
      items = box.values.toList();
      notifyListeners();
    }
  }
  // REMAINING KM
  int remainingKm(MaintenanceItem item) {
    return (item.lastServiceMileage + item.intervalKm) - currentMileage;
  }

  // REMAINING DAYS
  int remainingDays(MaintenanceItem item) {
    final nextDate = DateTime.fromMillisecondsSinceEpoch(item.lastServiceDateMs)
        .add(Duration(days: item.intervalDays));
    return nextDate.difference(DateTime.now()).inDays;
  }

  // SIMULATE MOVEMENT
  // Only one simulateMovement should exist; remove duplicate if present.

  // CHECK IF AN ITEM IS OVERDUE
  bool isOverdue(MaintenanceItem item) {
    return currentMileage >= item.lastServiceMileage + item.intervalKm;
  }

  // HOW MANY KM LEFT
  // (already defined above)

  // COUNT OVERDUE
  // (already defined above)
}

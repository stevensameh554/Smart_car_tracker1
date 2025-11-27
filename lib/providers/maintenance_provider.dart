import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/maintenance_item.dart';

class MaintenanceProvider with ChangeNotifier {
  static const String boxName = 'maintenance_items';
  static const String usersBoxName = 'registered_users';
  
  int currentMileage = 0;
  int todayDistance = 0;
  // Optional stored distances for other periods (can be wired to real trip history later)
  int yesterdayDistance = 0;
  int lastWeekDistance = 0;

  // Authentication state
  bool isAuthenticated = false;
  String? currentUserEmail;
  String? currentUserName;
  String? deviceId;

  List<MaintenanceItem> items = [];
  late Box<MaintenanceItem> box;
  late Box<Map> usersBox; // Store registered users with their credentials

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
  Future<void> simulateMovement(int km) async {
    currentMileage += km;
    todayDistance += km;
    // Persist mileage for current user
    await _saveUserData();
    notifyListeners();
  }

  // Calculate km left for an item (for dashboard)
  int kmLeft(MaintenanceItem item) {
    return (item.lastServiceMileage + item.intervalKm) - currentMileage;
  }

  Future<void> init() async {
    box = Hive.box<MaintenanceItem>(boxName);
    usersBox = Hive.box<Map>(usersBoxName);
    items = box.values.toList();
    notifyListeners();
    // persist change for current user (fire-and-forget)
    _saveUserData();
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
    
    // Save to user-specific box if authenticated
    if (currentUserEmail != null) {
      final userBoxName = 'user_${currentUserEmail}_items';
      try {
        final userBox = await Hive.openBox<MaintenanceItem>(userBoxName);
        await userBox.put(item.id, item);
      } catch (e) {
        print('Error saving item: $e');
      }
    }
    
    items = items..add(item);
    notifyListeners();
  }

  // REMOVE MAINTENANCE ITEM
  Future<void> removeItem(String id) async {
    // Remove from user-specific box if authenticated
    if (currentUserEmail != null) {
      final userBoxName = 'user_${currentUserEmail}_items';
      try {
        final userBox = await Hive.openBox<MaintenanceItem>(userBoxName);
        await userBox.delete(id);
      } catch (e) {
        print('Error removing item: $e');
      }
    }
    
    items.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  // UPDATE SERVICE NOW
  Future<void> updateServiceNow(String id, int mileageNow) async {
    final itemIndex = items.indexWhere((item) => item.id == id);
    if (itemIndex != -1) {
      items[itemIndex].lastServiceMileage = mileageNow;
      items[itemIndex].lastServiceDateMs = DateTime.now().millisecondsSinceEpoch;
      
      // Update in user-specific box if authenticated
      if (currentUserEmail != null) {
        final userBoxName = 'user_${currentUserEmail}_items';
        try {
          final userBox = await Hive.openBox<MaintenanceItem>(userBoxName);
          await userBox.put(id, items[itemIndex]);
        } catch (e) {
          print('Error updating item: $e');
        }
      }
      
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

  // AUTHENTICATION METHODS
  Future<void> signUp(String name, String email, String password, String deviceId) async {
    // Store user credentials in registered users box
    usersBox.put(email, {
      'name': name,
      'email': email,
      'password': password,
      'deviceId': deviceId,
    });
    
    // Automatically sign in after signing up
    currentUserName = name;
    currentUserEmail = email;
    this.deviceId = deviceId;
    isAuthenticated = true;
    
    // Load user-specific data (should be empty for new user)
    await _loadUserData();
    notifyListeners();
  }

  Future<void> signIn(String email, String password) async {
    // Check if user exists and password matches
    final userMap = usersBox.get(email);
    if (userMap != null && userMap['password'] == password) {
      currentUserEmail = email;
      currentUserName = userMap['name'];
      deviceId = userMap['deviceId'];
      isAuthenticated = true;
      
      // Load user-specific data from Hive
      await _loadUserData();
      notifyListeners();
    } else {
      // Invalid credentials
      throw Exception('Invalid email or password');
    }
  }

  Future<void> signOut() async {
    // Save user data before signing out
    await _saveUserData();

    // Clear auth state and data
    currentUserEmail = null;
    currentUserName = null;
    deviceId = null;
    isAuthenticated = false;
    items = [];
    currentMileage = 0;
    todayDistance = 0;
    yesterdayDistance = 0;
    lastWeekDistance = 0;
    notifyListeners();
  }

  // Load user-specific data from storage
  Future<void> _loadUserData() async {
    if (currentUserEmail != null) {
      // Create user-specific box name
      final userBoxName = 'user_${currentUserEmail}_items';
      try {
        final userBox = await Hive.openBox<MaintenanceItem>(userBoxName);
        items = userBox.values.toList();
      } catch (e) {
        // Box doesn't exist yet or failed to open, user has no data
        items = [];
      }
      
      // Also try to load mileage data
      try {
        final mileageBoxName = 'user_${currentUserEmail}_mileage';
        final mileageBox = await Hive.openBox<Map>(mileageBoxName);
        if (mileageBox.containsKey('data')) {
          final data = mileageBox.get('data');
          if (data != null) {
            currentMileage = data['currentMileage'] ?? 0;
            todayDistance = data['todayDistance'] ?? 0;
            yesterdayDistance = data['yesterdayDistance'] ?? 0;
            lastWeekDistance = data['lastWeekDistance'] ?? 0;
          }
        }
      } catch (e) {
        // No mileage box yet or failed to open
        currentMileage = 0;
        todayDistance = 0;
        yesterdayDistance = 0;
        lastWeekDistance = 0;
      }
    }
    notifyListeners();
  }

  // Save user-specific data to storage
  Future<void> _saveUserData() async {
    if (currentUserEmail != null) {
      // Save maintenance items to user-specific box
      final userBoxName = 'user_${currentUserEmail}_items';
      try {
        final userBox = await Hive.openBox<MaintenanceItem>(userBoxName);
        await userBox.clear();
        for (var item in items) {
          await userBox.put(item.id, item);
        }
      } catch (e) {
        print('Error saving user items: $e');
      }
      
      // Save mileage data to user-specific box
      final mileageBoxName = 'user_${currentUserEmail}_mileage';
      try {
        final mileageBox = await Hive.openBox<Map>(mileageBoxName);
        await mileageBox.put('data', {
          'currentMileage': currentMileage,
          'todayDistance': todayDistance,
          'yesterdayDistance': yesterdayDistance,
          'lastWeekDistance': lastWeekDistance,
        });
      } catch (e) {
        print('Error saving user mileage: $e');
      }
    }
  }
}

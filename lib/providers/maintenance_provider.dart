import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/maintenance_item.dart';
import '../models/device.dart';
import '../models/vehicle.dart';

class MaintenanceProvider with ChangeNotifier {
  static const String boxName = 'maintenance_items';
  static const String usersBoxName = 'registered_users';
  static const String devicesBoxNamePrefix = 'user_devices';
  static const String vehiclesBoxNamePrefix = 'user_vehicles';
  
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
  bool isFirstTimeSignUp = false;

  List<Device> devices = [];
  String? selectedDeviceId;
  List<Vehicle> vehicles = [];
  String? selectedVehicleId;
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
    // Also persist selected vehicle mileage so vehicles list stays in sync
    // If vehicle selected, also add distance to vehicle's todayDistance before saving
    if (selectedVehicleId != null) {
      // _saveSelectedVehicleMileage will persist provider.todayDistance into the vehicle
      await _saveSelectedVehicleMileage();
    }
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
    // Require a device and a vehicle to be selected before adding an item
    if (selectedDeviceId == null || selectedVehicleId == null) {
      throw Exception('Please add a device and a vehicle before adding maintenance items.');
    }
    final item = MaintenanceItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      intervalKm: intervalKm,
      intervalDays: intervalDays,
      lastServiceMileage: lastServiceMileage,
      lastServiceDateMs: lastServiceDate.millisecondsSinceEpoch,
      vehicleId: selectedVehicleId,
    );
    
    // Save to user-specific box if authenticated
    if (currentUserEmail != null) {
      final userBoxName = selectedVehicleId != null
          ? 'user_${currentUserEmail}_vehicle_${selectedVehicleId}_items'
          : 'user_${currentUserEmail}_items';
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
      final userBoxName = selectedVehicleId != null
          ? 'user_${currentUserEmail}_vehicle_${selectedVehicleId}_items'
          : 'user_${currentUserEmail}_items';
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
        final userBoxName = selectedVehicleId != null
            ? 'user_${currentUserEmail}_vehicle_${selectedVehicleId}_items'
            : 'user_${currentUserEmail}_items';
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
  Future<void> signUp(String name, String email, String password) async {
    try {
      // Create user with Firebase Auth
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Update user profile with name
      await userCredential.user?.updateDisplayName(name);
      
      // Set local auth state
      currentUserName = name;
      currentUserEmail = email;
      this.deviceId = null;
      isAuthenticated = true;
      isFirstTimeSignUp = true;
      
      // Load user-specific data (should be empty for new user)
      await _loadUserData();
      await loadUserDevices();
      await loadUserVehicles();
      await loadItemsForSelectedVehicle();
      notifyListeners();
    } catch (e) {
      throw Exception('Sign up failed: ${e.toString()}');
    }
  }

  Future<void> signIn(String email, String password) async {
    try {
      // Sign in with Firebase Auth
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      currentUserEmail = email;
      currentUserName = userCredential.user?.displayName ?? email;
      deviceId = null;
      isAuthenticated = true;
      isFirstTimeSignUp = false;
      
      // Load user-specific data from Hive
      await _loadUserData();
      await loadUserDevices();
      await loadUserVehicles();
      await loadItemsForSelectedVehicle();
      notifyListeners();
    } catch (e) {
      throw Exception('Sign in failed: ${e.toString()}');
    }
  }

  Future<void> signOut() async {
    // Save user data before signing out
    await _saveUserData();
    
    // Sign out from Firebase
    await FirebaseAuth.instance.signOut();

    // Clear auth state and data
    currentUserEmail = null;
    currentUserName = null;
    deviceId = null;
    isAuthenticated = false;
    isFirstTimeSignUp = false;
    items = [];
    devices = [];
    vehicles = [];
    selectedDeviceId = null;
    selectedVehicleId = null;
    currentMileage = 0;
    todayDistance = 0;
    yesterdayDistance = 0;
    lastWeekDistance = 0;
    notifyListeners();
  }

  // Load user-specific data from storage
  Future<void> _loadUserData() async {
    if (currentUserEmail != null) {
      // Load fallback user items (if any)
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
      // Save maintenance items to vehicle-specific box if a vehicle is selected,
      // otherwise use the fallback user items box.
      final boxName = selectedVehicleId != null
          ? 'user_${currentUserEmail}_vehicle_${selectedVehicleId}_items'
          : 'user_${currentUserEmail}_items';
      try {
        final userBox = await Hive.openBox<MaintenanceItem>(boxName);
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

  // DEVICE MANAGEMENT METHODS
  Future<void> addDevice(String id, String name) async {
    final device = Device(
      id: id,
      name: name,
      carModel: '',
      currentMileage: 0,
      createdAtMs: DateTime.now().millisecondsSinceEpoch,
    );

    // Save to user-specific devices box
    if (currentUserEmail != null) {
      final devicesBoxName = '${devicesBoxNamePrefix}_${currentUserEmail}';
      try {
        final devicesBox = await Hive.openBox<Device>(devicesBoxName);
        await devicesBox.put(device.id, device);
      } catch (e) {
        print('Error saving device: $e');
      }
    }

    devices.add(device);
    if (devices.length == 1) {
      selectedDeviceId = device.id; // Auto-select first device
    }
    notifyListeners();
  }

  Future<void> loadUserDevices() async {
    if (currentUserEmail != null) {
      final devicesBoxName = '${devicesBoxNamePrefix}_${currentUserEmail}';
      try {
        final devicesBox = await Hive.openBox<Device>(devicesBoxName);
        devices = devicesBox.values.toList();
        if (devices.isNotEmpty && selectedDeviceId == null) {
          selectedDeviceId = devices.first.id;
        }
      } catch (e) {
        print('Error loading devices: $e');
        devices = [];
      }
    }
    notifyListeners();
  }

  // Update device
  Future<void> updateDevice(String deviceId, {String? name, String? carModel, int? newMileage}) async {
    if (currentUserEmail == null) return;
    try {
      final devicesBoxName = '${devicesBoxNamePrefix}_${currentUserEmail}';
      final devicesBox = await Hive.openBox<Device>(devicesBoxName);
      final idx = devices.indexWhere((d) => d.id == deviceId);
      if (idx != -1) {
        final existing = devices[idx];
        final updated = Device(
          id: existing.id,
          name: name ?? existing.name,
          carModel: carModel ?? existing.carModel,
          currentMileage: newMileage ?? existing.currentMileage,
          createdAtMs: existing.createdAtMs,
        );
        await devicesBox.put(updated.id, updated);
        devices[idx] = updated;
        // If it's the selected device and no vehicle selected, keep state
        notifyListeners();
      }
    } catch (e) {
      print('Error updating device: $e');
    }
  }

  // Remove device and associated vehicles/items
  Future<void> removeDevice(String deviceId) async {
    if (currentUserEmail == null) return;
    try {
      // Remove device from box
      final devicesBoxName = '${devicesBoxNamePrefix}_${currentUserEmail}';
      final devicesBox = await Hive.openBox<Device>(devicesBoxName);
      await devicesBox.delete(deviceId);

      // Remove associated vehicles and their items
      final toRemove = vehicles.where((v) => v.deviceId == deviceId).toList();
      for (var v in toRemove) {
        await removeVehicle(v.id);
      }

      // Remove from in-memory list
      devices.removeWhere((d) => d.id == deviceId);

      // Update selected device if needed
      if (selectedDeviceId == deviceId) {
        selectedDeviceId = devices.isNotEmpty ? devices.first.id : null;
        // pick a vehicle for the new device
        if (selectedDeviceId != null) {
          final vehiclesForDevice = vehicles.where((v) => v.deviceId == selectedDeviceId).toList();
          selectedVehicleId = vehiclesForDevice.isNotEmpty ? vehiclesForDevice.first.id : null;
        } else {
          selectedVehicleId = null;
        }
        await loadItemsForSelectedVehicle();
      }

      notifyListeners();
    } catch (e) {
      print('Error removing device: $e');
    }
  }

  Future<void> selectDevice(String deviceId) async {
    // Save items for current vehicle before changing device
    await _saveItemsForCurrentVehicle();
    selectedDeviceId = deviceId;
    notifyListeners();
  }

  Device? getSelectedDevice() {
    if (selectedDeviceId == null) return null;
    try {
      return devices.firstWhere((d) => d.id == selectedDeviceId);
    } catch (e) {
      return null;
    }
  }

  // VEHICLE MANAGEMENT METHODS
  Future<void> addVehicle(String deviceId, String name, String carModel, int initialMileage) async {
    final vehicle = Vehicle(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      deviceId: deviceId,
      name: name,
      carModel: carModel,
      currentMileage: initialMileage,
      createdAtMs: DateTime.now().millisecondsSinceEpoch,
    );

    // Save to user-specific vehicles box
    if (currentUserEmail != null) {
      final vehiclesBoxName = '${vehiclesBoxNamePrefix}_${currentUserEmail}';
      try {
        final vehiclesBox = await Hive.openBox<Vehicle>(vehiclesBoxName);
        await vehiclesBox.put(vehicle.id, vehicle);
      } catch (e) {
        print('Error saving vehicle: $e');
      }
    }

    // Add to in-memory list
    vehicles.add(vehicle);

    // Always select the newly added vehicle and update current mileage
    selectedVehicleId = vehicle.id;
    currentMileage = vehicle.currentMileage;

    // Persist any existing items to the vehicle box and load items for this vehicle
    await loadItemsForSelectedVehicle();

    notifyListeners();
  }

  Future<void> loadUserVehicles() async {
    if (currentUserEmail != null) {
      final vehiclesBoxName = '${vehiclesBoxNamePrefix}_${currentUserEmail}';
      try {
        final vehiclesBox = await Hive.openBox<Vehicle>(vehiclesBoxName);
        vehicles = vehiclesBox.values.toList();
        // Auto-select first vehicle for selected device
        final vehiclesForDevice = vehicles.where((v) => v.deviceId == selectedDeviceId).toList();
        if (vehiclesForDevice.isNotEmpty && selectedVehicleId == null) {
          selectedVehicleId = vehiclesForDevice.first.id;
        } else if (selectedVehicleId != null && !vehicles.any((v) => v.id == selectedVehicleId)) {
          // If selected vehicle doesn't belong to selected device, pick first of device
          final newVehicles = vehicles.where((v) => v.deviceId == selectedDeviceId).toList();
          selectedVehicleId = newVehicles.isNotEmpty ? newVehicles.first.id : null;
        }
        // If we have a selected vehicle, pick up its per-vehicle distances
        if (selectedVehicleId != null) {
          try {
            final v = vehicles.firstWhere((vv) => vv.id == selectedVehicleId);
            currentMileage = v.currentMileage;
            todayDistance = v.todayDistance;
            yesterdayDistance = v.yesterdayDistance;
            lastWeekDistance = v.lastWeekDistance;
          } catch (_) {}
        }
      } catch (e) {
        print('Error loading vehicles: $e');
        vehicles = [];
      }
    }
    notifyListeners();
  }

  List<Vehicle> getVehiclesForDevice(String deviceId) {
    return vehicles.where((v) => v.deviceId == deviceId).toList();
  }

  // Update vehicle
  Future<void> updateVehicle(String vehicleId, {String? name, String? carModel, int? newMileage}) async {
    if (currentUserEmail == null) return;
    try {
      final vehiclesBoxName = '${vehiclesBoxNamePrefix}_${currentUserEmail}';
      final vehiclesBox = await Hive.openBox<Vehicle>(vehiclesBoxName);
      final idx = vehicles.indexWhere((v) => v.id == vehicleId);
      if (idx != -1) {
        final existing = vehicles[idx];
        final updated = Vehicle(
          id: existing.id,
          deviceId: existing.deviceId,
          name: name ?? existing.name,
          carModel: carModel ?? existing.carModel,
          currentMileage: newMileage ?? existing.currentMileage,
          createdAtMs: existing.createdAtMs,
        );
        await vehiclesBox.put(updated.id, updated);
        vehicles[idx] = updated;
        // If this was the selected vehicle, update provider currentMileage and per-vehicle distances and persist
        if (selectedVehicleId == updated.id) {
          this.currentMileage = updated.currentMileage;
          // keep provider distance totals in sync if any changes (they may remain unchanged)
          todayDistance = updated.todayDistance;
          yesterdayDistance = updated.yesterdayDistance;
          lastWeekDistance = updated.lastWeekDistance;
          await _saveUserData();
          await _saveSelectedVehicleMileage();
        }
        notifyListeners();
      }
    } catch (e) {
      print('Error updating vehicle: $e');
    }
  }

  // Remove vehicle and its items
  Future<void> removeVehicle(String vehicleId) async {
    if (currentUserEmail == null) return;
    try {
      final vehiclesBoxName = '${vehiclesBoxNamePrefix}_${currentUserEmail}';
      final vehiclesBox = await Hive.openBox<Vehicle>(vehiclesBoxName);
      await vehiclesBox.delete(vehicleId);

      // delete vehicle-specific items box
      final itemsBoxName = 'user_${currentUserEmail}_vehicle_${vehicleId}_items';
      try {
        final itemsBox = await Hive.openBox<MaintenanceItem>(itemsBoxName);
        await itemsBox.clear();
        await itemsBox.deleteFromDisk();
      } catch (_) {}

      vehicles.removeWhere((v) => v.id == vehicleId);

      // Update selection if needed
      if (selectedVehicleId == vehicleId) {
        selectedVehicleId = null;
        // try pick another vehicle from same device
        if (selectedDeviceId != null) {
          try {
            final other = vehicles.firstWhere((v) => v.deviceId == selectedDeviceId);
            selectedVehicleId = other.id;
          } catch (_) {
            selectedVehicleId = null;
          }
        }
        await loadItemsForSelectedVehicle();
      }

      notifyListeners();
    } catch (e) {
      print('Error removing vehicle: $e');
    }
  }

  Future<void> selectVehicle(String vehicleId) async {
    // Save current in-memory items to the box for the currently selected vehicle
    await _saveItemsForCurrentVehicle();

    selectedVehicleId = vehicleId;

    // Update current mileage to the vehicle's mileage
    Vehicle? v;
    try {
      v = vehicles.firstWhere((vv) => vv.id == vehicleId);
    } catch (_) {
      v = null;
    }
    if (v != null) {
      currentMileage = v.currentMileage;
      todayDistance = v.todayDistance;
      yesterdayDistance = v.yesterdayDistance;
      lastWeekDistance = v.lastWeekDistance;
    } else {
      currentMileage = 0;
      todayDistance = 0;
      yesterdayDistance = 0;
      lastWeekDistance = 0;
    }

    // Load maintenance items for this vehicle
    await loadItemsForSelectedVehicle();

    notifyListeners();
  }

  // Load maintenance items for the currently selected vehicle (or fallback user items)
  Future<void> loadItemsForSelectedVehicle() async {
    if (currentUserEmail == null) {
      items = [];
      notifyListeners();
      return;
    }

    final boxName = selectedVehicleId != null
        ? 'user_${currentUserEmail}_vehicle_${selectedVehicleId}_items'
        : 'user_${currentUserEmail}_items';

    try {
      final userBox = await Hive.openBox<MaintenanceItem>(boxName);
      items = userBox.values.toList();
    } catch (e) {
      items = [];
    }
    notifyListeners();
  }

  Vehicle? getSelectedVehicle() {
    if (selectedVehicleId == null) return null;
    try {
      return vehicles.firstWhere((v) => v.id == selectedVehicleId);
    } catch (e) {
      return null;
    }
  }

  Future<void> changeDevice(String newDeviceId) async {
    // Save current items before switching device
    await _saveItemsForCurrentVehicle();

    selectedDeviceId = newDeviceId;
    // Auto-select first vehicle for this device
    final vehiclesForDevice = vehicles.where((v) => v.deviceId == newDeviceId).toList();
    selectedVehicleId = vehiclesForDevice.isNotEmpty ? vehiclesForDevice.first.id : null;
    // If we have a selected vehicle, update current mileage to it
    if (selectedVehicleId != null) {
      try {
        final v = vehicles.firstWhere((vv) => vv.id == selectedVehicleId);
        currentMileage = v.currentMileage;
      } catch (_) {
        currentMileage = 0;
      }
    } else {
      currentMileage = 0;
    }

    // Load maintenance items for the selected vehicle (or fallback)
    await loadItemsForSelectedVehicle();
    notifyListeners();
  }

  // Persist current in-memory items to the box for the currently selected vehicle (or fallback)
  Future<void> _saveItemsForCurrentVehicle() async {
    if (currentUserEmail == null) return;
    final boxName = selectedVehicleId != null
        ? 'user_${currentUserEmail}_vehicle_${selectedVehicleId}_items'
        : 'user_${currentUserEmail}_items';
    try {
      final userBox = await Hive.openBox<MaintenanceItem>(boxName);
      await userBox.clear();
      for (var item in items) {
        await userBox.put(item.id, item);
      }
    } catch (e) {
      print('Error saving items for current vehicle: $e');
    }
  }

  // Persist the selected vehicle's mileage to the vehicles box and in-memory list
  Future<void> _saveSelectedVehicleMileage() async {
    if (currentUserEmail == null || selectedVehicleId == null) return;
    try {
      final vehiclesBoxName = '${vehiclesBoxNamePrefix}_${currentUserEmail}';
      final vehiclesBox = await Hive.openBox<Vehicle>(vehiclesBoxName);

      final idx = vehicles.indexWhere((v) => v.id == selectedVehicleId);
      if (idx != -1) {
        final existing = vehicles[idx];
        final updated = Vehicle(
          id: existing.id,
          deviceId: existing.deviceId,
          name: existing.name,
          carModel: existing.carModel,
          currentMileage: currentMileage,
          createdAtMs: existing.createdAtMs,
        );
        await vehiclesBox.put(updated.id, updated);
        vehicles[idx] = updated;
      }
    } catch (e) {
      print('Error saving selected vehicle mileage: $e');
    }
  }
}

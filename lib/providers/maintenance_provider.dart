import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/maintenance_item.dart';
import '../models/device.dart';
import '../models/vehicle.dart';

class MaintenanceProvider with ChangeNotifier {
  static const String boxName = 'maintenance_items';
  static const String usersBoxName = 'registered_users';
  static const String devicesBoxNamePrefix = 'user_devices';
  static const String vehiclesBoxNamePrefix = 'user_vehicles';
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  int currentMileage = 0;
  int todayDistance = 0;
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
  late Box<Map> usersBox;

  int get todayDistanceValue => todayDistance;
  int get overdueCount => items.where((i) => isOverdue(i)).length;

  int distanceForPeriod(String period) {
    switch (period) {
      case 'Yesterday':
        return yesterdayDistance > 0 ? yesterdayDistance : (todayDistance * 0.6).round();
      case 'Last week':
        return lastWeekDistance > 0 ? lastWeekDistance : (todayDistance * 4).round();
      case 'Today':
      default:
        return todayDistance;
    }
  }

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

  Future<void> simulateMovement(int km) async {
    currentMileage += km;
    todayDistance += km;
    await _saveUserData();
    if (selectedVehicleId != null) {
      await _saveSelectedVehicleMileage();
    }
    notifyListeners();
  }

  int kmLeft(MaintenanceItem item) {
    return (item.lastServiceMileage + item.intervalKm) - currentMileage;
  }

  Future<void> init() async {
    box = Hive.box<MaintenanceItem>(boxName);
    usersBox = Hive.box<Map>(usersBoxName);
    items = box.values.toList();
    notifyListeners();
    _saveUserData();
  }

  // ADD MAINTENANCE ITEM to Firestore
  Future<void> addItem({
    required String name,
    required int intervalKm,
    required int intervalDays,
    required int lastServiceMileage,
    required DateTime lastServiceDate,
  }) async {
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
    
    if (currentUserEmail != null) {
      try {
        await _firestore
            .collection('users')
            .doc(currentUserEmail)
            .collection('devices')
            .doc(selectedDeviceId)
            .collection('vehicles')
            .doc(selectedVehicleId)
            .collection('maintenanceItems')
            .doc(item.id)
            .set({
          'id': item.id,
          'name': item.name,
          'intervalKm': item.intervalKm,
          'intervalDays': item.intervalDays,
          'lastServiceMileage': item.lastServiceMileage,
          'lastServiceDateMs': item.lastServiceDateMs,
          'vehicleId': item.vehicleId,
        });
      } catch (e) {
        print('Error saving item to Firestore: $e');
      }
    }
    
    items.add(item);
    notifyListeners();
  }

  // REMOVE MAINTENANCE ITEM from Firestore
  Future<void> removeItem(String id) async {
    if (currentUserEmail != null && selectedDeviceId != null && selectedVehicleId != null) {
      try {
        await _firestore
            .collection('users')
            .doc(currentUserEmail)
            .collection('devices')
            .doc(selectedDeviceId)
            .collection('vehicles')
            .doc(selectedVehicleId)
            .collection('maintenanceItems')
            .doc(id)
            .delete();
      } catch (e) {
        print('Error removing item from Firestore: $e');
      }
    }
    
    items.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  // UPDATE SERVICE NOW in Firestore
  Future<void> updateServiceNow(String id, int mileageNow) async {
    final itemIndex = items.indexWhere((item) => item.id == id);
    if (itemIndex != -1) {
      items[itemIndex].lastServiceMileage = mileageNow;
      items[itemIndex].lastServiceDateMs = DateTime.now().millisecondsSinceEpoch;
      
      if (currentUserEmail != null && selectedDeviceId != null && selectedVehicleId != null) {
        try {
          await _firestore
              .collection('users')
              .doc(currentUserEmail)
              .collection('devices')
              .doc(selectedDeviceId)
              .collection('vehicles')
              .doc(selectedVehicleId)
              .collection('maintenanceItems')
              .doc(id)
              .update({
            'lastServiceMileage': mileageNow,
            'lastServiceDateMs': items[itemIndex].lastServiceDateMs,
          });
        } catch (e) {
          print('Error updating item in Firestore: $e');
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
      
      // Store user data in Firestore
      await _firestore.collection('users').doc(email).set({
        'email': email,
        'name': name,
        'createdAt': FieldValue.serverTimestamp(),
        'displayName': name,
      });
      
      // Set local auth state
      currentUserName = name;
      currentUserEmail = email;
      this.deviceId = null;
      isAuthenticated = true;
      isFirstTimeSignUp = true;
      
      // Load user-specific data from Firestore
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
      
      // Load user-specific data from Firestore
      await loadUserDevices();
      await loadUserVehicles();
      await loadItemsForSelectedVehicle();
      notifyListeners();
    } catch (e) {
      throw Exception('Sign in failed: ${e.toString()}');
    }
  }

  Future<void> signOut() async {
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

  // Save user-specific data to Firestore
  Future<void> _saveUserData() async {
    // User data (credentials) already saved at signup
    // Mileage is saved per-vehicle via _saveSelectedVehicleMileage
  }

  // DEVICE MANAGEMENT METHODS - Using Firestore
  Future<void> addDevice(String id, String name) async {
    final device = Device(
      id: id,
      name: name,
      carModel: '',
      currentMileage: 0,
      createdAtMs: DateTime.now().millisecondsSinceEpoch,
    );

    if (currentUserEmail != null) {
      try {
        await _firestore
            .collection('users')
            .doc(currentUserEmail)
            .collection('devices')
            .doc(device.id)
            .set({
          'id': device.id,
          'name': device.name,
          'carModel': device.carModel,
          'currentMileage': device.currentMileage,
          'createdAtMs': device.createdAtMs,
        });
      } catch (e) {
        print('Error saving device to Firestore: $e');
      }
    }

    devices.add(device);
    if (devices.length == 1) {
      selectedDeviceId = device.id;
    }
    notifyListeners();
  }

  Future<void> loadUserDevices() async {
    if (currentUserEmail != null) {
      try {
        final querySnapshot = await _firestore
            .collection('users')
            .doc(currentUserEmail)
            .collection('devices')
            .get();

        devices = querySnapshot.docs.map((doc) {
          final data = doc.data();
          return Device(
            id: data['id'] ?? '',
            name: data['name'] ?? '',
            carModel: data['carModel'] ?? '',
            currentMileage: data['currentMileage'] ?? 0,
            createdAtMs: data['createdAtMs'] ?? 0,
          );
        }).toList();

        if (devices.isNotEmpty && selectedDeviceId == null) {
          selectedDeviceId = devices.first.id;
        }
      } catch (e) {
        print('Error loading devices from Firestore: $e');
        devices = [];
      }
    }
    notifyListeners();
  }

  Future<void> updateDevice(String deviceId, {String? name, String? carModel, int? newMileage}) async {
    if (currentUserEmail == null) return;
    try {
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
        
        // Update in Firestore
        await _firestore
            .collection('users')
            .doc(currentUserEmail)
            .collection('devices')
            .doc(deviceId)
            .update({
          'name': updated.name,
          'carModel': updated.carModel,
          'currentMileage': updated.currentMileage,
        });
        
        devices[idx] = updated;
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
      // Remove device from Firestore
      await _firestore
          .collection('users')
          .doc(currentUserEmail)
          .collection('devices')
          .doc(deviceId)
          .delete();

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

  // VEHICLE MANAGEMENT METHODS - Using Firestore
  Future<void> addVehicle(String deviceId, String name, String carModel, int initialMileage) async {
    final vehicle = Vehicle(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      deviceId: deviceId,
      name: name,
      carModel: carModel,
      currentMileage: initialMileage,
      createdAtMs: DateTime.now().millisecondsSinceEpoch,
    );

    if (currentUserEmail != null) {
      try {
        await _firestore
            .collection('users')
            .doc(currentUserEmail)
            .collection('devices')
            .doc(deviceId)
            .collection('vehicles')
            .doc(vehicle.id)
            .set({
          'id': vehicle.id,
          'deviceId': vehicle.deviceId,
          'name': vehicle.name,
          'carModel': vehicle.carModel,
          'currentMileage': vehicle.currentMileage,
          'createdAtMs': vehicle.createdAtMs,
          'todayDistance': vehicle.todayDistance,
          'yesterdayDistance': vehicle.yesterdayDistance,
          'lastWeekDistance': vehicle.lastWeekDistance,
        });
      } catch (e) {
        print('Error saving vehicle to Firestore: $e');
      }
    }

    vehicles.add(vehicle);
    selectedVehicleId = vehicle.id;
    currentMileage = vehicle.currentMileage;
    await loadItemsForSelectedVehicle();
    notifyListeners();
  }

  Future<void> loadUserVehicles() async {
    if (currentUserEmail != null && selectedDeviceId != null) {
      try {
        final querySnapshot = await _firestore
            .collection('users')
            .doc(currentUserEmail)
            .collection('devices')
            .doc(selectedDeviceId)
            .collection('vehicles')
            .get();

        vehicles = querySnapshot.docs.map((doc) {
          final data = doc.data();
          return Vehicle(
            id: data['id'] ?? '',
            deviceId: data['deviceId'] ?? '',
            name: data['name'] ?? '',
            carModel: data['carModel'] ?? '',
            currentMileage: data['currentMileage'] ?? 0,
            createdAtMs: data['createdAtMs'] ?? 0,
            todayDistance: data['todayDistance'] ?? 0,
            yesterdayDistance: data['yesterdayDistance'] ?? 0,
            lastWeekDistance: data['lastWeekDistance'] ?? 0,
          );
        }).toList();

        if (vehicles.isNotEmpty && selectedVehicleId == null) {
          selectedVehicleId = vehicles.first.id;
        }
        
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
        print('Error loading vehicles from Firestore: $e');
        vehicles = [];
      }
    }
    notifyListeners();
  }

  List<Vehicle> getVehiclesForDevice(String deviceId) {
    return vehicles.where((v) => v.deviceId == deviceId).toList();
  }

  Future<void> updateVehicle(String vehicleId, {String? name, String? carModel, int? newMileage}) async {
    if (currentUserEmail == null || selectedDeviceId == null) return;
    try {
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
        
        // Update in Firestore
        await _firestore
            .collection('users')
            .doc(currentUserEmail)
            .collection('devices')
            .doc(selectedDeviceId)
            .collection('vehicles')
            .doc(vehicleId)
            .update({
          'name': updated.name,
          'carModel': updated.carModel,
          'currentMileage': updated.currentMileage,
        });
        
        vehicles[idx] = updated;
        
        if (selectedVehicleId == updated.id) {
          this.currentMileage = updated.currentMileage;
          // keep provider distance totals in sync if any changes (they may remain unchanged)
          todayDistance = updated.todayDistance;
          yesterdayDistance = updated.yesterdayDistance;
          lastWeekDistance = updated.lastWeekDistance;
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
    if (currentUserEmail == null || selectedDeviceId == null) return;
    try {
      // Remove vehicle from Firestore
      await _firestore
          .collection('users')
          .doc(currentUserEmail)
          .collection('devices')
          .doc(selectedDeviceId)
          .collection('vehicles')
          .doc(vehicleId)
          .delete();

      // Remove vehicle's maintenance items from Firestore
      final itemsSnapshot = await _firestore
          .collection('users')
          .doc(currentUserEmail)
          .collection('devices')
          .doc(selectedDeviceId)
          .collection('vehicles')
          .doc(vehicleId)
          .collection('maintenanceItems')
          .get();

      for (var doc in itemsSnapshot.docs) {
        await doc.reference.delete();
      }

      vehicles.removeWhere((v) => v.id == vehicleId);

      if (selectedVehicleId == vehicleId) {
        selectedVehicleId = null;
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
    await _saveItemsForCurrentVehicle();

    selectedVehicleId = vehicleId;

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

    await loadItemsForSelectedVehicle();
    notifyListeners();
  }

  // Load maintenance items for the currently selected vehicle from Firestore
  Future<void> loadItemsForSelectedVehicle() async {
    if (currentUserEmail == null || selectedDeviceId == null || selectedVehicleId == null) {
      items = [];
      notifyListeners();
      return;
    }

    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(currentUserEmail)
          .collection('devices')
          .doc(selectedDeviceId)
          .collection('vehicles')
          .doc(selectedVehicleId)
          .collection('maintenanceItems')
          .get();

      items = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return MaintenanceItem(
          id: data['id'] ?? '',
          name: data['name'] ?? '',
          intervalKm: data['intervalKm'] ?? 0,
          intervalDays: data['intervalDays'] ?? 0,
          lastServiceMileage: data['lastServiceMileage'] ?? 0,
          lastServiceDateMs: data['lastServiceDateMs'] ?? 0,
          vehicleId: data['vehicleId'],
        );
      }).toList();
    } catch (e) {
      print('Error loading maintenance items from Firestore: $e');
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

  // Persist current in-memory items to Firestore for the currently selected vehicle
  Future<void> _saveItemsForCurrentVehicle() async {
    if (currentUserEmail == null || selectedDeviceId == null || selectedVehicleId == null) return;
    try {
      // Items are already saved to Firestore individually as they're added/updated
      // This method is now a no-op but kept for compatibility
    } catch (e) {
      print('Error saving items: $e');
    }
  }

  // Persist the selected vehicle's mileage and distances to Firestore
  Future<void> _saveSelectedVehicleMileage() async {
    if (currentUserEmail == null || selectedDeviceId == null || selectedVehicleId == null) return;
    try {
      final idx = vehicles.indexWhere((v) => v.id == selectedVehicleId);
      if (idx != -1) {
        final existing = vehicles[idx];
        
        // Update vehicle in Firestore with new mileage and distances
        await _firestore
            .collection('users')
            .doc(currentUserEmail)
            .collection('devices')
            .doc(selectedDeviceId)
            .collection('vehicles')
            .doc(selectedVehicleId)
            .update({
          'currentMileage': currentMileage,
          'todayDistance': todayDistance,
          'yesterdayDistance': yesterdayDistance,
          'lastWeekDistance': lastWeekDistance,
        });
        
        // Update in-memory list
        final updated = Vehicle(
          id: existing.id,
          deviceId: existing.deviceId,
          name: existing.name,
          carModel: existing.carModel,
          currentMileage: currentMileage,
          createdAtMs: existing.createdAtMs,
          todayDistance: todayDistance,
          yesterdayDistance: yesterdayDistance,
          lastWeekDistance: lastWeekDistance,
        );
        vehicles[idx] = updated;
      }
    } catch (e) {
      print('Error saving selected vehicle mileage: $e');
    }
  }
}


// lib/screens/vehicles.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/maintenance_provider.dart';

class VehiclesScreen extends StatefulWidget {
  const VehiclesScreen({super.key});

  @override
  State<VehiclesScreen> createState() => _VehiclesScreenState();
}

class _VehiclesScreenState extends State<VehiclesScreen> {
  late TextEditingController _vehicleNameCtl;
  late TextEditingController _carModelCtl;
  late TextEditingController _mileageCtl;

  @override
  void initState() {
    super.initState();
    _vehicleNameCtl = TextEditingController();
    _carModelCtl = TextEditingController();
    _mileageCtl = TextEditingController();
  }

  @override
  void dispose() {
    _vehicleNameCtl.dispose();
    _carModelCtl.dispose();
    _mileageCtl.dispose();
    super.dispose();
  }

  void _showAddVehicleDialog(String deviceId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Color(0xFF0D1821),
        title: Text('Add Vehicle', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _vehicleNameCtl,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Vehicle Name (e.g., Family Car)',
                hintStyle: TextStyle(color: Colors.white30),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.white24),
                ),
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: _carModelCtl,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Car Model (e.g., Toyota Camry)',
                hintStyle: TextStyle(color: Colors.white30),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.white24),
                ),
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: _mileageCtl,
              style: TextStyle(color: Colors.white),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Current Mileage (km)',
                hintStyle: TextStyle(color: Colors.white30),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.white24),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF0CBAB5)),
            onPressed: () async {
              final prov = Provider.of<MaintenanceProvider>(context, listen: false);
              final mileage = int.tryParse(_mileageCtl.text) ?? 0;

              if (_vehicleNameCtl.text.isNotEmpty && _carModelCtl.text.isNotEmpty) {
                await prov.addVehicle(
                  deviceId,
                  _vehicleNameCtl.text.trim(),
                  _carModelCtl.text.trim(),
                  mileage,
                );
                _vehicleNameCtl.clear();
                _carModelCtl.clear();
                _mileageCtl.clear();
                Navigator.pop(context);
              }
            },
            child: Text('Add', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<MaintenanceProvider>(context);
    final vehiclesForDevice = prov.getVehiclesForDevice(prov.selectedDeviceId ?? '');

    return SafeArea(
      child: Scaffold(
        backgroundColor: Color(0xFF091017),
        appBar: AppBar(
          backgroundColor: Color(0xFF07121A),
          elevation: 0,
          title: Text('Vehicles', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        body: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Device selector
              Text('Select Device', style: TextStyle(color: Colors.white70, fontSize: 12)),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Color(0xFF0D1821),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white24),
                ),
                child: DropdownButton<String>(
                  dropdownColor: Color(0xFF0B1216),
                  value: prov.selectedDeviceId,
                  underline: SizedBox.shrink(),
                  items: prov.devices
                      .map((d) => DropdownMenuItem(
                            value: d.id,
                            child: Text(d.name, style: TextStyle(color: Colors.white)),
                          ))
                      .toList(),
                  onChanged: (deviceId) async {
                    if (deviceId != null) {
                      await prov.changeDevice(deviceId);
                    }
                  },
                  isExpanded: true,
                ),
              ),
              SizedBox(height: 24),
              // Vehicles for selected device
              Text('Vehicles', style: TextStyle(color: Colors.white70, fontSize: 12)),
              SizedBox(height: 8),
              if (vehiclesForDevice.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.directions_car, size: 60, color: Colors.white30),
                        SizedBox(height: 20),
                        Text(
                          'No vehicles added for this device',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        SizedBox(height: 20),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF0CBAB5),
                            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                          ),
                          onPressed: () => _showAddVehicleDialog(prov.selectedDeviceId ?? ''),
                          child: Text('Add Vehicle', style: TextStyle(color: Colors.black)),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView(
                    children: vehiclesForDevice.map((vehicle) {
                      final isSelected = vehicle.id == prov.selectedVehicleId;
                      return GestureDetector(
                        onTap: () async {
                          await prov.selectVehicle(vehicle.id);
                        },
                        child: Container(
                          margin: EdgeInsets.only(bottom: 12),
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected ? Color(0xFF0CBAB5).withOpacity(0.2) : Color(0xFF131A24),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected ? Color(0xFF0CBAB5) : Colors.white24,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          vehicle.name,
                                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          vehicle.carModel,
                                          style: TextStyle(color: Colors.white70, fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Color(0xFF0CBAB5),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'SELECTED',
                                        style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  SizedBox(width: 8),
                                  // Edit vehicle
                                  IconButton(
                                    tooltip: 'Edit vehicle',
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (_) {
                                          final _nameCtl = TextEditingController(text: vehicle.name);
                                          final _modelCtl = TextEditingController(text: vehicle.carModel);
                                          final _mileageCtl = TextEditingController(text: vehicle.currentMileage.toString());
                                          return AlertDialog(
                                            backgroundColor: Color(0xFF0D1821),
                                            title: Text('Edit Vehicle', style: TextStyle(color: Colors.white)),
                                            content: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                TextField(controller: _nameCtl, style: TextStyle(color: Colors.white), decoration: InputDecoration(hintText: 'Vehicle name', hintStyle: TextStyle(color: Colors.white30))),
                                                SizedBox(height: 8),
                                                TextField(controller: _modelCtl, style: TextStyle(color: Colors.white), decoration: InputDecoration(hintText: 'Car model', hintStyle: TextStyle(color: Colors.white30))),
                                                SizedBox(height: 8),
                                                TextField(controller: _mileageCtl, style: TextStyle(color: Colors.white), keyboardType: TextInputType.number, decoration: InputDecoration(hintText: 'Current mileage', hintStyle: TextStyle(color: Colors.white30))),
                                              ],
                                            ),
                                            actions: [
                                              TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: TextStyle(color: Colors.white70))),
                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF0CBAB5)),
                                                onPressed: () async {
                                                  final newName = _nameCtl.text.trim();
                                                  final newModel = _modelCtl.text.trim();
                                                  final newMileage = int.tryParse(_mileageCtl.text.trim()) ?? vehicle.currentMileage;
                                                  await prov.updateVehicle(vehicle.id, name: newName, carModel: newModel, newMileage: newMileage);
                                                  Navigator.pop(context);
                                                },
                                                child: Text('Save', style: TextStyle(color: Colors.black)),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                    color: Colors.white70,
                                    icon: Icon(Icons.edit),
                                  ),
                                  // Remove vehicle
                                  IconButton(
                                    tooltip: 'Remove vehicle',
                                    onPressed: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (_) => AlertDialog(
                                          backgroundColor: Color(0xFF0D1821),
                                          title: Text('Remove vehicle', style: TextStyle(color: Colors.white)),
                                          content: Text('Remove vehicle "${vehicle.name}"?', style: TextStyle(color: Colors.white70)),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel', style: TextStyle(color: Colors.white70))),
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                                              onPressed: () => Navigator.pop(context, true),
                                              child: Text('Remove', style: TextStyle(color: Colors.white)),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (confirm == true) {
                                        await prov.removeVehicle(vehicle.id);
                                      }
                                    },
                                    color: Colors.white70,
                                    icon: Icon(Icons.delete_forever),
                                  ),
                                ],
                              ),
                              SizedBox(height: 12),
                              Text(
                                'Current Mileage: ${vehicle.currentMileage} km',
                                style: TextStyle(color: Colors.greenAccent, fontSize: 14, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF0CBAB5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => _showAddVehicleDialog(prov.selectedDeviceId ?? ''),
                  child: Text('Add New Vehicle', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

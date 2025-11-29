import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/maintenance_provider.dart';
import 'vehicles.dart';

class DevicesScreen extends StatefulWidget {
  const DevicesScreen({super.key});

  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  late TextEditingController _nameCtl;
  late TextEditingController _idCtl;

  @override
  void initState() {
    super.initState();
    _nameCtl = TextEditingController();
    _idCtl = TextEditingController();
  }

  @override
  void dispose() {
    _nameCtl.dispose();
    _idCtl.dispose();
    super.dispose();
  }

  void _showAddDeviceDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Color(0xFF0D1821),
        title: Text('Add Device', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _idCtl,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Device ID (unique)',
                hintStyle: TextStyle(color: Colors.white30),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.white24),
                ),
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _nameCtl,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Device Name (e.g., My Tesla)',
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
              final id = _idCtl.text.trim();
              final name = _nameCtl.text.trim();
              if (id.isNotEmpty && name.isNotEmpty) {
                await prov.addDevice(id, name);
                _nameCtl.clear();
                _idCtl.clear();
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

    return SafeArea(
      child: Scaffold(
        backgroundColor: Color(0xFF091017),
        appBar: AppBar(
          backgroundColor: Color(0xFF07121A),
          elevation: 0,
          title: Text('Devices', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        body: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (prov.devices.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.directions_car, size: 60, color: Colors.white30),
                        SizedBox(height: 20),
                        Text(
                          'No devices added yet',
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                        SizedBox(height: 20),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF0CBAB5),
                            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                          ),
                          onPressed: _showAddDeviceDialog,
                          child: Text('Add Your First Device', style: TextStyle(color: Colors.black)),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView(
                    children: prov.devices.map((device) {
                      final isSelected = device.id == prov.selectedDeviceId;
                      return Container(
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
                                        device.name,
                                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        device.carModel,
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
                                TextButton(
                                  onPressed: () async {
                                    await prov.selectDevice(device.id);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => VehiclesScreen()),
                                    );
                                  },
                                  style: TextButton.styleFrom(
                                    backgroundColor: Color(0xFF0CBAB5),
                                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  child: Text('Vehicles', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                                ),
                                SizedBox(width: 8),
                                // Edit device
                                IconButton(
                                  tooltip: 'Edit device',
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (_) {
                                        final _editName = TextEditingController(text: device.name);
                                        return AlertDialog(
                                          backgroundColor: Color(0xFF0D1821),
                                          title: Text('Edit Device', style: TextStyle(color: Colors.white)),
                                          content: TextField(
                                            controller: _editName,
                                            style: TextStyle(color: Colors.white),
                                            decoration: InputDecoration(hintText: 'Device name', hintStyle: TextStyle(color: Colors.white30)),
                                          ),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: TextStyle(color: Colors.white70))),
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF0CBAB5)),
                                              onPressed: () async {
                                                await prov.updateDevice(device.id, name: _editName.text.trim());
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
                                // Remove device
                                IconButton(
                                  tooltip: 'Remove device',
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        backgroundColor: Color(0xFF0D1821),
                                        title: Text('Remove device', style: TextStyle(color: Colors.white)),
                                        content: Text('Remove device "${device.name}" and all its cars?', style: TextStyle(color: Colors.white70)),
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
                                      await prov.removeDevice(device.id);
                                    }
                                  },
                                  color: Colors.white70,
                                  icon: Icon(Icons.delete_forever),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            // Device-level mileage is not shown because mileage is per-vehicle
                            SizedBox.shrink(),
                          ],
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
                  onPressed: _showAddDeviceDialog,
                  child: Text('Add New Device', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

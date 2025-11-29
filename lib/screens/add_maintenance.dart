// lib/screens/add_maintenance.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/maintenance_provider.dart';

class AddMaintenanceScreen extends StatefulWidget {
  const AddMaintenanceScreen({Key? key}) : super(key: key);

  @override
  State<AddMaintenanceScreen> createState() => _AddMaintenanceScreenState();
}

class _AddMaintenanceScreenState extends State<AddMaintenanceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtl = TextEditingController();
  final _kmCtl = TextEditingController(text: '10000');
  final _daysCtl = TextEditingController(text: '365');
  DateTime _lastServiceDate = DateTime.now();
  int _lastServiceMileage = 0;

  @override
  void dispose() {
    _nameCtl.dispose();
    _kmCtl.dispose();
    _daysCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<MaintenanceProvider>(context);
    return Scaffold(
      appBar: AppBar(title: Text('Add Maintenance Item'), backgroundColor: Color(0xFF07121A)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(children: [
            TextFormField(
              controller: _nameCtl,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(labelText: 'Item name', hintText: 'Oil change', filled: true, fillColor: Color(0xFF07121A)),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter item name' : null,
            ),
            SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: TextFormField(
                  controller: _kmCtl,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(labelText: 'Interval (km)', filled: true, fillColor: Color(0xFF07121A)),
                  validator: (v) => (v == null || int.tryParse(v) == null) ? 'Enter km interval' : null,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _daysCtl,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(labelText: 'Interval (days)', filled: true, fillColor: Color(0xFF07121A)),
                  validator: (v) => (v == null || int.tryParse(v) == null) ? 'Enter days interval' : null,
                ),
              ),
            ]),
            SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: TextFormField(
                  initialValue: prov.currentMileage.toString(),
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(labelText: 'Last service mileage', filled: true, fillColor: Color(0xFF07121A)),
                  onChanged: (v) {
                    _lastServiceMileage = int.tryParse(v) ?? prov.currentMileage;
                  },
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final dt = await showDatePicker(
                      context: context,
                      initialDate: _lastServiceDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (dt != null) setState(() => _lastServiceDate = dt);
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(labelText: 'Last service date', filled: true, fillColor: Color(0xFF07121A)),
                    child: Text(
                      DateFormat('yyyy-MM-dd').format(_lastServiceDate),
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ]),
            SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF0CBAB5)),
              onPressed: () async {
                if (prov.selectedDeviceId == null || prov.selectedVehicleId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('You must add a device and a vehicle before adding maintenance items.'),
                  ));
                  return;
                }

                if (_formKey.currentState?.validate() ?? false) {
                  final name = _nameCtl.text.trim();
                  final km = int.parse(_kmCtl.text.trim());
                  final days = int.parse(_daysCtl.text.trim());
                  final lastMileage = _lastServiceMileage == 0 ? prov.currentMileage : _lastServiceMileage;
                  try {
                    await prov.addItem(
                      name: name,
                      intervalKm: km,
                      intervalDays: days,
                      lastServiceMileage: lastMileage,
                      lastServiceDate: _lastServiceDate,
                    );
                    Navigator.of(context).pop();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                  }
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Text('Save', style: TextStyle(color: Colors.black)),
              ),
            )
          ]),
        ),
      ),
    );
  }
}

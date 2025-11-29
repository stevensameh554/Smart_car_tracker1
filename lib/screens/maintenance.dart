// lib/screens/maintenance.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/maintenance_provider.dart';
// ...existing code...
import 'add_maintenance.dart';

class MaintenanceScreen extends StatelessWidget {
  const MaintenanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<MaintenanceProvider>(context);
    final items = prov.items;

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          // Show currently selected vehicle above tabs
          if (prov.getSelectedVehicle() != null)
            Container(
              width: double.infinity,
              color: Color(0xFF07121A),
              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              child: Text(
                'Vehicle: ${prov.getSelectedVehicle()!.name} • ${prov.getSelectedVehicle()!.carModel}',
                style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          Container(
            color: Color(0xFF07121A),
            child: TabBar(
              indicatorColor: Colors.tealAccent,
              tabs: [
                Tab(text: 'Schedule'),
                Tab(text: 'History'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(children: [
              // Schedule
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Expanded(
                      child: items.isEmpty
                          ? Center(child: Text('No maintenance items yet', style: TextStyle(color: Colors.white60)))
                          : ListView.separated(
                              itemCount: items.length,
                              separatorBuilder: (context, index) => SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final item = items[index];
                                final isOver = prov.isOverdue(item);
                                return Container(
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(color: Color(0xFF0B1620), borderRadius: BorderRadius.circular(12)),
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Row(children: [
                                      Expanded(child: Text(item.name, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                                      if (isOver)
                                        Container(
                                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                          decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(12)),
                                          child: Text('OVERDUE', style: TextStyle(color: Colors.white)),
                                        )
                                    ]),
                                    SizedBox(height: 8),
                                    Row(children: [
                                      Expanded(
                                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                          Text('Every ${item.intervalKm} km or ${item.intervalDays} days', style: TextStyle(color: Colors.white60)),
                                          SizedBox(height: 6),
                                          // Highlight numbers in red if close to overdue
                                          Builder(builder: (context) {
                                            final kmLeft = prov.remainingKm(item);
                                            final daysLeft = prov.remainingDays(item);
                                            final kmThreshold = (item.intervalKm * 0.1).ceil();
                                            final daysThreshold = (item.intervalDays * 0.1).ceil();
                                            final kmColor = (kmLeft <= kmThreshold) ? Colors.red : Colors.white;
                                            final daysColor = (daysLeft <= daysThreshold) ? Colors.red : Colors.white;
                                            return Row(
                                              children: [
                                                Text('$kmLeft km left', style: TextStyle(color: kmColor)),
                                                Text(' • ', style: TextStyle(color: Colors.white)),
                                                Text('$daysLeft days left', style: TextStyle(color: daysColor)),
                                              ],
                                            );
                                          }),
                                        ]),
                                      ),
                                    ]),
                                    SizedBox(height: 8),
                                    Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                                      TextButton(
                                          onPressed: () {
                                            // mark service done
                                            prov.updateServiceNow(item.id, prov.currentMileage);
                                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Service updated')));
                                          },
                                          child: Text('Mark serviced')),
                                      TextButton(
                                          onPressed: () {
                                            prov.removeItem(item.id);
                                          },
                                          child: Text('Remove', style: TextStyle(color: Colors.red))),
                                    ])
                                  ]),
                                );
                              }),
                    ),
                    SizedBox(height: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: (prov.selectedDeviceId == null || prov.selectedVehicleId == null)
                            ? Colors.grey
                            : Color(0xFF0CBAB5),
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: (prov.selectedDeviceId == null || prov.selectedVehicleId == null)
                          ? () {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                  content: Text('Please add a device and a vehicle before adding maintenance items.')));
                            }
                          : () {
                              Navigator.of(context).push(MaterialPageRoute(builder: (_) => AddMaintenanceScreen()));
                            },
                      icon: Icon(Icons.add),
                      label: Text('Add Item', style: TextStyle(color: Colors.black)),
                    ),
                  ],
                ),
              ),
              // History tab placeholder
              Center(child: Text('History will be shown here', style: TextStyle(color: Colors.white60))),
            ]),
          )
        ],
      ),
    );
  }
}

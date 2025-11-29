              // ...existing code...
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/maintenance_provider.dart';
import 'sign_in.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _selectedPeriod = 'Today';

  Widget dashboardCard({
    required IconData icon,
    required Color iconBg,
    required String title,
    required String value,
    Color? valueColor,
    String? subtitle,
    Widget? trailing,
  }) {
    return Container(
      margin: EdgeInsets.all(6),
      padding: EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      decoration: BoxDecoration(
        color: Color(0xFF131A24),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600)),
                if (subtitle != null) ...[
                  SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(color: Colors.white54, fontSize: 12)),
                ],
                SizedBox(height: 8),
                Text(value,
                    style: TextStyle(
                        color: valueColor ?? Colors.tealAccent,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          if (trailing != null) ...[
            SizedBox(width: 8),
            trailing,
          ]
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
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Dashboard", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              if (prov.currentUserName != null)
                Text("${prov.currentUserName}", style: TextStyle(color: Colors.white70, fontSize: 12)),
              // Show selected vehicle if available
              if (prov.getSelectedVehicle() != null) ...[
                SizedBox(height: 2),
                Text(
                  '${prov.getSelectedVehicle()!.name} • ${prov.getSelectedVehicle()!.carModel}',
                  style: TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ],
            ],
          ),
          actions: [
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'signout') {
                  // Save and clear auth state, then navigate to SignInScreen and remove history
                  await prov.signOut();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const SignInScreen()),
                    (route) => false,
                  );
                }
              },
              itemBuilder: (BuildContext context) => [
                PopupMenuItem(
                  value: 'signout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: Colors.redAccent),
                      SizedBox(width: 8),
                      Text('Sign Out', style: TextStyle(color: Colors.redAccent)),
                    ],
                  ),
                ),
              ],
              icon: Icon(Icons.more_vert, color: Colors.white),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(14.0),
          child: ListView(
            children: [
              SizedBox(height: 10),

              // Dashboard stat cards styled like screenshot
              Row(
                children: [
                  Expanded(
                    child: Container(
                      margin: EdgeInsets.all(6),
                      padding: EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Color(0xFF131A24),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.speed, color: Colors.blueAccent, size: 28),
                          SizedBox(height: 12),
                          Text("Current Mileage", style: TextStyle(color: Colors.white70, fontSize: 13)),
                          SizedBox(height: 8),
                          Text("${prov.currentMileage} km", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      margin: EdgeInsets.all(6),
                      padding: EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Color(0xFF131A24),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.alt_route, color: Colors.greenAccent, size: 28),
                          SizedBox(height: 12),
                          Text("Total Distance", style: TextStyle(color: Colors.white70, fontSize: 13)),
                          SizedBox(height: 8),
                          // Period selector for distance display
                              Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("${prov.distanceForPeriod(_selectedPeriod)} km", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                              DropdownButton<String>(
                                dropdownColor: Color(0xFF0B1216),
                                value: _selectedPeriod,
                                underline: SizedBox.shrink(),
                                items: ['Today', 'Yesterday', 'Last week']
                                    .map((p) => DropdownMenuItem(value: p, child: Text(p, style: TextStyle(color: Colors.white))))
                                    .toList(),
                                onChanged: (v) => setState(() {
                                  if (v != null) _selectedPeriod = v;
                                }),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      margin: EdgeInsets.all(6),
                      padding: EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Color(0xFF131A24),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.calendar_today, color: Colors.amberAccent, size: 28),
                          SizedBox(height: 12),
                          Text("Last Trip", style: TextStyle(color: Colors.white70, fontSize: 13)),
                          SizedBox(height: 8),
                          Text("Today", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      margin: EdgeInsets.all(6),
                      padding: EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Color(0xFF131A24),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.build, color: Colors.purpleAccent, size: 28),
                          SizedBox(height: 12),
                          Text("Maintenance Items", style: TextStyle(color: Colors.white70, fontSize: 13)),
                          SizedBox(height: 8),
                          Text("${prov.items.length}", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              // Simulation buttons (correct placement)
              SizedBox(height: 25),
              Text("Simulate Car Movement",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600)),
              SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF0CBAB5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => prov.simulateMovement(1),
                      child: Text("+1 km", style: TextStyle(color: Colors.black)),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF0CBAB5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => prov.simulateMovement(10),
                      child: Text("+10 km", style: TextStyle(color: Colors.black)),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 25),

              // Maintenance Alerts styled like screenshot
              Row(
                children: [
                  Text("Maintenance Alerts", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                  Spacer(),
                  if (prov.overdueCount > 0)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.shade700,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text("${prov.overdueCount} OVERDUE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                ],
              ),
              SizedBox(height: 10),
              if (prov.items.isEmpty)
                Text("No maintenance items added.", style: TextStyle(color: Colors.white70))
              else
                ...[
                  // Alerts (yellow): items close to overdue (<=10% interval)
                  ...prov.items.where((item) {
                    final left = prov.kmLeft(item);
                    final threshold = (item.intervalKm * 0.1).ceil();
                    return left > 0 && left <= threshold;
                  }).map((item) {
                    final left = prov.kmLeft(item);
                    return Container(
                      margin: EdgeInsets.only(bottom: 10),
                      padding: EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.yellow.shade900.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.yellow.shade700, width: 1),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.amberAccent, size: 28),
                          SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.name, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                                SizedBox(height: 4),
                                Text("ALERT • $left km left", style: TextStyle(color: Colors.yellowAccent, fontSize: 13)),
                                Text("${prov.remainingDays(item)} days remaining", style: TextStyle(color: Colors.white70, fontSize: 13)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  // Overdue items (red)
                  ...prov.items.where((item) => prov.isOverdue(item)).map((item) {
                    return Container(
                      margin: EdgeInsets.only(bottom: 10),
                      padding: EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.red.shade900.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.red.shade700, width: 1),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.build_circle, color: Colors.redAccent, size: 28),
                          SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.name, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                                SizedBox(height: 4),
                                Text("${prov.kmLeft(item).abs()} km overdue", style: TextStyle(color: Colors.redAccent, fontSize: 13)),
                                Text("${prov.remainingDays(item)} days remaining", style: TextStyle(color: Colors.white70, fontSize: 13)),
                              ],
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.red.shade700,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text("OVERDUE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              SizedBox(height: 18),
              Text("Recent Trips", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
              SizedBox(height: 10),
              ...["32.7 km", "18.3 km", "24.5 km"].asMap().entries.map((entry) {
                final idx = entry.key;
                final miles = entry.value;
                final day = idx == 0 ? "Today" : idx == 1 ? "Yesterday" : "2 days ago";
                return Container(
                  margin: EdgeInsets.only(bottom: 8),
                  padding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Color(0xFF131A24),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Color(0xFF1E2A3A),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.alt_route, color: Colors.white, size: 20),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(miles, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                            SizedBox(height: 4),
                            Text("$day • 1h 0m", style: TextStyle(color: Colors.white60, fontSize: 13)),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: Colors.white38),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

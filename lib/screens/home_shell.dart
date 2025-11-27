import 'package:flutter/material.dart';
import 'dashboard.dart';
import 'trips.dart';
import 'maintenance.dart';
import 'vehicles.dart';

class HomeShell extends StatefulWidget {
  final int initialIndex;
  const HomeShell({Key? key, this.initialIndex = 0}) : super(key: key);

  @override
  _HomeShellState createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late int _selected;
  final List<Widget> _screens = [
    const DashboardScreen(),
    const TripsScreen(),
    const MaintenanceScreen(),
    const VehiclesScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _selected = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selected],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selected,
        onTap: (i) => setState(() => _selected = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.alt_route), label: 'Trips'),
          BottomNavigationBarItem(icon: Icon(Icons.build), label: 'Maintenance'),
          BottomNavigationBarItem(icon: Icon(Icons.directions_car_filled), label: 'Vehicles'),
        ],
      ),
    );
  }
}

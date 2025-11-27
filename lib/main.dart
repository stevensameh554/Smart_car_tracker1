// lib/main.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'models/maintenance_item.dart';
import 'providers/maintenance_provider.dart';
import 'screens/dashboard.dart';
import 'screens/trips.dart';
import 'screens/maintenance.dart';
import 'screens/vehicles.dart';
// The generated adapter is included via the `part` directive in the model file.
// Do not import `maintenance_item.g.dart` directly.

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  Hive.registerAdapter(MaintenanceItemAdapter());
  await Hive.openBox<MaintenanceItem>(MaintenanceProvider.boxName);

  final maintenanceProvider = MaintenanceProvider();
  await maintenanceProvider.init();

  runApp(MyApp(provider: maintenanceProvider));
}

class MyApp extends StatelessWidget {
  final MaintenanceProvider provider;
  const MyApp({Key? key, required this.provider}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<MaintenanceProvider>.value(
      value: provider,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Smart Car Tracker',
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: Color(0xFF061018),
          appBarTheme: AppBarTheme(backgroundColor: Color(0xFF07121A)),
          bottomNavigationBarTheme: BottomNavigationBarThemeData(
            backgroundColor: Color(0xFF07121A),
            selectedItemColor: Color(0xFF0CBAB5),
            unselectedItemColor: Colors.white60,
          ),
        ),
        home: HomeShell(),
      ),
    );
  }
}

class HomeShell extends StatefulWidget {
  @override
  _HomeShellState createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selected = 0;
  final List<Widget> _screens = [DashboardScreen(), TripsScreen(), MaintenanceScreen(), VehiclesScreen()];

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

// lib/main.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'models/maintenance_item.dart';
import 'providers/maintenance_provider.dart';
import 'screens/home_shell.dart';
import 'screens/sign_in.dart';
// The generated adapter is included via the `part` directive in the model file.
// Do not import `maintenance_item.g.dart` directly.

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  Hive.registerAdapter(MaintenanceItemAdapter());
  await Hive.openBox<MaintenanceItem>(MaintenanceProvider.boxName);

  await Hive.openBox<Map>(MaintenanceProvider.usersBoxName);

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
        home: Consumer<MaintenanceProvider>(
          builder: (context, prov, _) {
            return prov.isAuthenticated ? HomeShell() : SignInScreen();
          },
        ),
      ),
    );
  }
}

// `HomeShell` is defined in `lib/screens/home_shell.dart` to avoid circular imports

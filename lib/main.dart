import 'package:material_ui/material_ui.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import 'screens/auth_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar SQLite para Chrome.
  databaseFactory = databaseFactoryFfiWeb;

  runApp(const NuevoDiaApp());
}

class NuevoDiaApp extends StatelessWidget {
  const NuevoDiaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NuevoDia 🌞',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF168B70),
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
      ),

      home: const AuthScreen(),

      routes: {'/login': (context) => const AuthScreen()},
    );
  }
}

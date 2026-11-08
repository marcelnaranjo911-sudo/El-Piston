import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'providers/cliente_provider.dart';
import 'providers/inventario_provider.dart';
import 'providers/orden_provider.dart';
import 'providers/reporte_provider.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // En Windows / Linux / macOS sqflite necesita el backend FFI.
  // En Android e iOS se usa el sqflite normal.
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  await initializeDateFormatting('es');
  Intl.defaultLocale = 'es';

  runApp(const PistonApp());
}

class PistonApp extends StatelessWidget {
  const PistonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => InventarioProvider()..cargar()),
        ChangeNotifierProvider(create: (_) => ClienteProvider()..cargar()),
        ChangeNotifierProvider(
          create: (ctx) => OrdenProvider(
            ctx.read<InventarioProvider>(),
            ctx.read<ClienteProvider>(),
          )..cargar(),
        ),
        ChangeNotifierProvider(create: (_) => ReporteProvider()),
      ],
      child: MaterialApp(
        title: 'El Pistón',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        themeMode: ThemeMode.dark,
        locale: const Locale('es'),
        supportedLocales: const [Locale('es'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const HomeScreen(),
      ),
    );
  }
}

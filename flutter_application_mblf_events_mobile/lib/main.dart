import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'config/app_theme.dart';
import 'screens/auth/splash_screen.dart';
import 'package:intl/date_symbol_data_local.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting(
    'pt_BR',
    null,
  );

  runApp(
    const MblfEventsApp(),
  );
}

class MblfEventsApp extends StatefulWidget {
  const MblfEventsApp({super.key});

  @override
  State<MblfEventsApp> createState() => _MblfEventsAppState();
}

class _MblfEventsAppState extends State<MblfEventsApp> {
  ThemeMode _modo = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _carregarTema();
  }

  Future<void> _carregarTema() async {
    final prefs = await SharedPreferences.getInstance();
    final salvo = prefs.getString('modo_tema') ?? 'sistema';
    if (!mounted) return;
    setState(() => _modo = _converter(salvo));
  }

  ThemeMode _converter(String valor) {
    switch (valor) {
      case 'claro': return ThemeMode.light;
      case 'escuro': return ThemeMode.dark;
      default: return ThemeMode.system;
    }
  }

  Future<void> _alterarTema(ThemeMode modo) async {
    setState(() => _modo = modo);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('modo_tema',
      modo == ThemeMode.dark ? 'escuro' :
      modo == ThemeMode.light ? 'claro' : 'sistema');
  }

  @override
  Widget build(BuildContext context) {
    return MblfThemeController(
      modo: _modo,
      alterar: _alterarTema,
      child: MaterialApp(
      title: 'MBLF Events',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _modo,
      home: const SplashScreen(),
    ));
  }
}
/// Permite escolher o tema a partir do Perfil, sem tocar na API.
class MblfThemeController extends InheritedWidget {
  final ThemeMode modo;
  final Future<void> Function(ThemeMode) alterar;
  const MblfThemeController({
    super.key, required this.modo, required this.alterar,
    required super.child,
  });

  static MblfThemeController of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<MblfThemeController>()!;
  }

  @override
  bool updateShouldNotify(MblfThemeController oldWidget) =>
      modo != oldWidget.modo;
}

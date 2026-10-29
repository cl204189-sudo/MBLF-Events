import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'admin/admin_screen.dart';
import 'funcionario/funcionario_screen.dart';

import '../services/notificacao_service.dart';
import 'eventos/explorar_screen.dart';
import 'home/home_screen.dart';
import 'hub/meus_eventos_screen.dart';
import 'notificacoes/notificacoes_screen.dart';
import 'perfil/perfil_screen.dart';
import 'sobre/sobre_nos_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> with WidgetsBindingObserver {
  Timer? _contadorTimer;
  bool _contadorEmAndamento = false;
  final ValueNotifier<int> _naoLidas = ValueNotifier<int>(0);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) carregarContador();
  }

  @override
  void dispose() {
    _contadorTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _naoLidas.dispose();
    super.dispose();
  }
  final NotificacaoService notificacaoService = NotificacaoService();

  int paginaAtual = 0;
  late final List<Widget> paginas;
  String perfil = '';
  int? get paginaEspecial => perfil == 'ADMIN' ? 6 : perfil == 'FUNCIONARIO' ? 7 : null;

  Future<void> _lerPerfil() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => perfil = (prefs.getString('perfil') ?? '').trim().toUpperCase());
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);
    _contadorTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
        carregarContador();
      }
    });
    paginas = [
      HomeScreen(
        irParaExplorar: () => _irPara(1),
        irParaNotificacoes: () => _irPara(2),
        notificacoesNaoLidas: _naoLidas,
        irParaSobreNos: () => _irPara(3),
      ),
      const ExplorarScreen(),
      NotificacoesScreen(onVoltar: () => _irPara(0)),
      SobreNosScreen(onVoltar: () => _irPara(0)),
      const MeusEventosScreen(),
      const PerfilScreen(),
      const AdminScreen(),
      const FuncionarioScreen(),
    ];

    _lerPerfil();
    carregarContador();
  }

  void _irPara(int pagina) {
    setState(() => paginaAtual = pagina);
  }

  Future<void> carregarContador() async {
    if (_contadorEmAndamento) return;
    _contadorEmAndamento = true;
    try {
      final quantidade = await notificacaoService.contarNaoLidas();
      if (!mounted) return;
      _naoLidas.value = quantidade;
    } catch (_) {
      // Mantém o último contador em caso de falha de rede.
    } finally {
      _contadorEmAndamento = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final destinosPaginas = <int>[0, 1, 4, if (paginaEspecial != null) paginaEspecial!, 5];
    final selecionado = destinosPaginas.contains(paginaAtual)
        ? destinosPaginas.indexOf(paginaAtual)
        : 0;
    final destinos = <NavigationDestination>[
      const NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
      const NavigationDestination(icon: Icon(Icons.explore_outlined), selectedIcon: Icon(Icons.explore), label: 'Explorar'),
      const NavigationDestination(icon: Icon(Icons.dashboard_customize_outlined), selectedIcon: Icon(Icons.dashboard_customize), label: 'Meu HUB'),
      if (perfil == 'ADMIN')
        const NavigationDestination(icon: Icon(Icons.admin_panel_settings_outlined), selectedIcon: Icon(Icons.admin_panel_settings), label: 'Admin'),
      if (perfil == 'FUNCIONARIO')
        const NavigationDestination(icon: Icon(Icons.badge_outlined), selectedIcon: Icon(Icons.badge), label: 'Funcionário'),
      const NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Perfil'),
    ];

    return Scaffold(
      body: IndexedStack(
        index: paginaAtual,
        children: paginas,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selecionado,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: (index) async {
          setState(() => paginaAtual = destinosPaginas[index]);
          await carregarContador();
          await _lerPerfil();
        },
        destinations: destinos,
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../../config/app_theme.dart';
import '../../models/evento.dart';
import '../../widgets/evento_resumo.dart';
import '../../services/evento_service.dart';
import '../eventos/detalhes_evento_screen.dart';
import '../inscricoes/minhas_inscricoes_screen.dart';
import '../../services/favorito_service.dart';
import '../../services/meus_eventos_service.dart';
import '../hub/gerenciar_evento_screen.dart';
import '../certificados/validar_certificado_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback irParaExplorar;
  final VoidCallback irParaNotificacoes;
  final VoidCallback irParaSobreNos;
  final ValueListenable<int> notificacoesNaoLidas;

  const HomeScreen({
    super.key,
    required this.irParaExplorar,
    required this.irParaNotificacoes,
    required this.irParaSobreNos,
    required this.notificacoesNaoLidas,
  });

  @override
  State<HomeScreen> createState() =>
      _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  Timer? _atualizacaoTimer;
  bool _emPrimeiroPlano = true;
  bool _atualizando = false;
  final EventoService eventoService =
      EventoService();

  List<Evento> eventos = [];

  final FavoritoService favoritoService =
    FavoritoService();

  Set<int> favoritos = {};

  final MeusEventosService meusEventosService =
    MeusEventosService();

  List<Evento> meusEventos = [];

  bool carregando = true;
  String nomeUsuario = '';

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _emPrimeiroPlano = state == AppLifecycleState.resumed;
    if (_emPrimeiroPlano && mounted) carregarDados(silencioso: true);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _atualizacaoTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (_emPrimeiroPlano && !_atualizando && mounted) {
        carregarDados(silencioso: true);
      }
    });

    carregarDados();
  }

  List<Evento> get proximosEventos {
  final agora = DateTime.now();

  final lista = eventos
      .where(
        (evento) =>
            evento.dataInicio.isAfter(agora),
      )
      .toList();

  lista.sort(
    (a, b) =>
        a.dataInicio.compareTo(
      b.dataInicio,
    ),
  );

  return lista.take(3).toList();
}

List<Evento> get eventosFavoritos {
  return eventos
      .where(
        (evento) =>
            favoritos.contains(evento.id),
      )
      .take(3)
      .toList();
}

  Future<void> carregarDados({bool silencioso = false}) async {
    if (_atualizando) return;
    _atualizando = true;
    try {
      final prefs =
          await SharedPreferences.getInstance();

      final nome =
          prefs.getString('nome') ?? '';

      final lista =
          await eventoService.listarPublicos();

        List<Evento> organizados = [];

        try {
          organizados =
              await meusEventosService
                  .listarEventosOrganizados();
        } catch (_) {
          organizados = [];
        } 

      final favoritosSalvos =
          await favoritoService.listarIds();    

      if (!mounted) return;

      setState(() {
        nomeUsuario = nome;
        eventos = lista;
        meusEventos = organizados;
        favoritos = favoritosSalvos;
        carregando = false;
      });
    } catch (erro) {
      if (!mounted) return;

      setState(() {
        carregando = false;
      });

      if (!silencioso) ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível carregar os eventos.',
          ),
        ),
      );
    }
    finally {
      _atualizando = false;
    }
  }

  Future<void> alternarFavorito(
  Evento evento,
    ) async {
      final ficouFavorito =
          await favoritoService.alternar(
        evento.id,
      );

      if (!mounted) return;

      setState(() {
        if (ficouFavorito) {
          favoritos.add(evento.id);
        } else {
          favoritos.remove(evento.id);
        }
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          duration:
              const Duration(
            milliseconds: 900,
          ),
          content: Text(
            ficouFavorito
                ? 'Evento adicionado aos favoritos.'
                : 'Evento removido dos favoritos.',
          ),
        ),
      );
    }

  String primeiroNome() {
    if (nomeUsuario.isEmpty) {
      return '';
    }

    return nomeUsuario
        .split(' ')
        .first;
  }

  @override
  void dispose() {
    _atualizacaoTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: carregarDados,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              22,
              20,
              22,
              110,
            ),
            children: [
              Row(
                children: [
                  Image.asset(
                    'assets/images/LOGO2.png',
                    width: 58,
                    height: 58,
                    fit: BoxFit.contain,
                  ),

                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Olá,',
                          style: TextStyle(
                            color:
                                AppTheme.textoSecundario,
                            fontSize: 15,
                          ),
                        ),

                        const SizedBox(height: 2),

                        Text(
                          primeiroNome().isEmpty
                              ? 'Bem-vindo!'
                              : '${primeiroNome()} 👋',
                          style: const TextStyle(
                            fontSize: 27,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Notificações',
                        onPressed: widget.irParaNotificacoes,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppTheme.roxo,
                        ),
                        icon: ValueListenableBuilder<int>(
                          valueListenable: widget.notificacoesNaoLidas,
                          builder: (context, quantidade, _) => Badge(
                            isLabelVisible: quantidade > 0,
                            label: Text(quantidade > 99 ? '99+' : '$quantidade'),
                            child: const Icon(Icons.notifications_none_rounded),
                          ),
                        ),
                      ),
                      const SizedBox(width: 2),
                      IconButton(
                        tooltip: 'Sobre nós',
                        onPressed: widget.irParaSobreNos,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppTheme.roxo,
                        ),
                        icon: const Icon(
                          Icons.info_outline_rounded,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 28),

              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient:
                      AppTheme.gradientePrincipal,
                  borderRadius:
                      BorderRadius.circular(26),
                ),
                child: const Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Descubra experiências\nincríveis perto de você',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        height: 1.2,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Encontre eventos, participe e conecte-se.',
                      style: TextStyle(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Atalho de inscrições em um card com texto,
              // deixando a ação mais fácil de encontrar.
              Material(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const MinhasInscricoesScreen(),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: AppTheme.gradientePrincipal,
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: const Icon(
                            Icons.confirmation_number_outlined,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Minhas inscrições',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'Consulte seus ingressos e eventos',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: AppTheme.textoSecundario,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ValidarCertificadoScreen()),
                ),
                icon: const Icon(Icons.verified_outlined),
                label: const Text('Validar certificado'),
              ),

              const SizedBox(height: 24),

              if (!carregando &&
                  meusEventos.isNotEmpty) ...[
                const SizedBox(height: 24),

                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Seus eventos',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.roxo.withValues(
                          alpha: 0.10,
                        ),
                        borderRadius:
                            BorderRadius.circular(100),
                      ),
                      child: const Text(
                        'ORGANIZADOR',
                        style: TextStyle(
                          color: AppTheme.roxo,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                ...meusEventos.take(2).map(
                  (evento) => Container(
                    margin: const EdgeInsets.only(
                      bottom: 12,
                    ),
                    padding: const EdgeInsets.all(17),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius:
                          BorderRadius.circular(21),
                      border: Border.all(
                        color: const Color(
                          0xFFEBEDF2,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            gradient:
                                AppTheme.gradientePrincipal,
                            borderRadius:
                                BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.event_outlined,
                            color: Colors.white,
                          ),
                        ),

                        const SizedBox(width: 11),

                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                evento.titulo,
                                style: const TextStyle(
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),

                              const SizedBox(height: 4),

                              EventoResumo(evento: evento),
                            ],
                          ),
                        ),

                        IconButton(
                          tooltip: 'Gerenciar evento',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    GerenciarEventoScreen(
                                  evento: evento,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons
                                .arrow_forward_ios_rounded,
                            size: 17,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),
              ],

              TextField(
                decoration: InputDecoration(
                  hintText: 'Buscar eventos...',
                  prefixIcon: const Icon(
                    Icons.search,
                  ),
                  suffixIcon: IconButton(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.tune_rounded,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Próximos eventos',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  TextButton(
                    onPressed: widget.irParaExplorar,
                    child: const Text(
                      'Ver todos',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              if (carregando)
                const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (proximosEventos.isEmpty)
                _estadoVazio()
              else
                ...proximosEventos.map(
                  (evento) =>
                      _cardEvento(evento),
                ),
              if (!carregando &&
                  eventosFavoritos.isNotEmpty) ...[
                const SizedBox(height: 30),

                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Seus favoritos',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const Icon(
                      Icons.favorite,
                      color: Colors.red,
                      size: 20,
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                ...eventosFavoritos.map(
                  (evento) =>
                      _cardEvento(evento),
                ),
              ],  
            ],
          ),
        ),
      ),
    );
  }

  Widget _cardEvento(Evento evento) {
    final data = DateFormat(
      "dd 'de' MMM",
      'pt_BR',
    ).format(evento.dataInicio);

    final hora = DateFormat(
      'HH:mm',
    ).format(evento.dataInicio);

    return Container(
      margin: const EdgeInsets.only(
        bottom: 16,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius:
            BorderRadius.circular(22),
        border: Border.all(
          color:
              Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: InkWell(
        borderRadius:
            BorderRadius.circular(22),
        onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      DetalhesEventoScreen(
                    evento: evento,
                  ),
                ),
              );

              if (!mounted) return;

              await carregarDados();
            },
        child: Padding(
          padding:
              const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.roxo
                          .withValues(
                            alpha: 0.10,
                          ),
                      borderRadius:
                          BorderRadius.circular(
                        100,
                      ),
                    ),
                    child: Text(
                      evento.tipo,
                      style: const TextStyle(
                        color: AppTheme.roxo,
                        fontWeight:
                            FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),

                  const Spacer(),

                  IconButton(
                    onPressed: () {
                      alternarFavorito(
                        evento,
                      );
                    },
                    icon: Icon(
                      favoritos.contains(
                        evento.id,
                      )
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: favoritos.contains(
                        evento.id,
                      )
                          ? Colors.red
                          : AppTheme.textoSecundario,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Text(
                evento.titulo,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                evento.descricao,
                maxLines: 2,
                overflow:
                    TextOverflow.ellipsis,
                style: const TextStyle(
                  color:
                      AppTheme.textoSecundario,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 18,
                    color: AppTheme.verde,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    '$data • $hora',
                  ),
                ],
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 19,
                    color: AppTheme.verde,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      evento.cidade,
                      overflow:
                          TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              if (evento.vagasDisponiveis != null)
                ...[
                  const SizedBox(height: 14),

                  Text(
                    '${evento.vagasDisponiveis} vagas disponíveis',
                    style: const TextStyle(
                      fontSize: 13,
                      color:
                          AppTheme.textoSecundario,
                    ),
                  ),
                ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _estadoVazio() {
    return Container(
      padding: const EdgeInsets.all(36),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius:
            BorderRadius.circular(24),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.event_busy_outlined,
            size: 55,
            color:
                AppTheme.textoSecundario,
          ),
          SizedBox(height: 15),
          Text(
            'Nenhum evento disponível',
            style: TextStyle(
              fontWeight:
                  FontWeight.bold,
              fontSize: 17,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Novos eventos aparecerão aqui.',
            textAlign:
                TextAlign.center,
            style: TextStyle(
              color:
                  AppTheme.textoSecundario,
            ),
          ),
        ],
      ),
    );
  }
}
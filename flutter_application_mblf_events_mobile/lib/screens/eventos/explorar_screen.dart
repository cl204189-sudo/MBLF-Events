import '../../config/api_config.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../config/app_theme.dart';
import '../../models/evento.dart';
import '../../services/evento_service.dart';
import 'detalhes_evento_screen.dart';

class ExplorarScreen extends StatefulWidget {
  const ExplorarScreen({super.key});

  @override
  State<ExplorarScreen> createState() =>
      _ExplorarScreenState();
}

class _ExplorarScreenState
    extends State<ExplorarScreen> with WidgetsBindingObserver {
  Timer? _atualizacaoTimer;
  bool _emPrimeiroPlano = true;
  bool _atualizando = false;

  final EventoService service =
      EventoService();

  final TextEditingController
      buscaController =
      TextEditingController();

  List<Evento> eventos = [];
  List<Evento> filtrados = [];

  bool carregando = true;

  String tipoSelecionado = 'TODOS';
  String periodoSelecionado = 'Todos';
  bool erroCarregamento = false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _emPrimeiroPlano = state == AppLifecycleState.resumed;
    if (_emPrimeiroPlano && mounted) carregar(silencioso: true);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _atualizacaoTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (_emPrimeiroPlano && !_atualizando && mounted) {
        carregar(silencioso: true);
      }
    });

    carregar();
    buscaController.addListener(filtrar);
  }

  Future<void> carregar({bool silencioso = false}) async {
    if (_atualizando) return;
    _atualizando = true;
    try {
      final lista =
          await service.listarPublicos();

      if (!mounted) return;

      setState(() {
        eventos = lista;
        carregando = false;
        erroCarregamento = false;
      });
      filtrar();
    } catch (erro) {
      if (!mounted) return;

      setState(() {
        carregando = false;
        erroCarregamento = true;
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

  void filtrar() {
    final busca =
        buscaController.text
            .trim()
            .toLowerCase();

    setState(() {
      filtrados = eventos.where(
        (evento) {

          final correspondeBusca =
              evento.titulo
                      .toLowerCase()
                      .contains(busca) ||
                  evento.cidade
                      .toLowerCase()
                      .contains(busca) ||
                  evento.tipo
                      .toLowerCase()
                      .contains(busca);

          final correspondeTipo =
              tipoSelecionado == 'TODOS' ||
                  evento.tipo
                          .toUpperCase() ==
                      tipoSelecionado;

          final hoje = DateTime.now();
          final dia = DateTime(hoje.year, hoje.month, hoje.day);
          final inicio = evento.dataInicio.toLocal();
          final data = DateTime(inicio.year, inicio.month, inicio.day);
          final diasAte = data.difference(dia).inDays;
          final correspondePeriodo = switch (periodoSelecionado) {
            'Hoje' => diasAte == 0,
            'Próximos 7 dias' => diasAte >= 0 && diasAte <= 7,
            'Este mês' => inicio.year == hoje.year && inicio.month == hoje.month,
            _ => true,
          };
          // Eventos encerrados deixam apenas a vitrine pública.
          // Não são removidos do banco nem das telas do organizador.
          final aindaEmAndamento = evento.dataFim.isAfter(hoje);
          return aindaEmAndamento && correspondeBusca &&
              correspondeTipo && correspondePeriodo;
        },
      ).toList();
    });
  }

  List<String> tipos() {
    final lista = eventos
        .map(
          (evento) =>
              evento.tipo.toUpperCase(),
        )
        .where(
          (tipo) => tipo.isNotEmpty,
        )
        .toSet()
        .toList();

    lista.sort();

    return [
      'TODOS',
      ...lista,
    ];
  }

  @override
  void dispose() {
    _atualizacaoTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    buscaController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Explorar eventos',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: RefreshIndicator(
        onRefresh: carregar,

        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            20,
            10,
            20,
            100,
          ),

          children: [
            TextField(
              controller:
                  buscaController,

              decoration:
                  const InputDecoration(
                hintText:
                    'Buscar evento, cidade ou categoria...',
                prefixIcon: Icon(
                  Icons.search_rounded,
                ),
              ),
            ),

            const SizedBox(
              height: 18,
            ),

            SizedBox(
              height: 42,

              child: ListView.separated(
                scrollDirection:
                    Axis.horizontal,

                itemCount:
                    tipos().length,

                separatorBuilder:
                    (_, __) =>
                        const SizedBox(
                  width: 8,
                ),

                itemBuilder:
                    (context, index) {

                  final tipo =
                      tipos()[index];

                  final selecionado =
                      tipoSelecionado ==
                          tipo;

                  return ChoiceChip(
                    label: Text(
                      tipo == 'TODOS'
                          ? 'Todos'
                          : tipo,
                    ),

                    selected:
                        selecionado,

                    onSelected: (_) {
                      setState(() {
                        tipoSelecionado =
                            tipo;
                      });

                      filtrar();
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 12),
            SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: ['Todos', 'Hoje', 'Próximos 7 dias', 'Este mês'].map((periodo) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(periodo, style: const TextStyle(fontSize: 12)),
                      selected: periodoSelecionado == periodo,
                      onSelected: (_) {
                        periodoSelecionado = periodo;
                        filtrar();
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                const Text(
                  'Eventos encontrados',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const Spacer(),

                Text(
                  '${filtrados.length}',
                  style: const TextStyle(
                    color:
                        AppTheme.textoSecundario,
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 14,
            ),

            if (carregando)
              const Padding(
                padding:
                    EdgeInsets.all(50),

                child: Center(
                  child:
                      CircularProgressIndicator(),
                ),
              )

            else if (erroCarregamento)
              Center(child: TextButton.icon(
                onPressed: () { setState(() => carregando = true); carregar(); },
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar carregar novamente'),
              ))
            else if (filtrados.isEmpty)
              _estadoVazio()

            else
              ...filtrados.map(
                _cardEvento,
              ),
          ],
        ),
      ),
    );
  }

  Widget _blocoData(DateTime inicio) {
    return Container(
                  width: 88,
                  height: 112,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF7667E8), Color(0xFF557FE0)],
                    ),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.event_available_outlined,
                          size: 28, color: Colors.white),
                      const SizedBox(height: 8),
                      Text(DateFormat('dd').format(inicio),
                        style: const TextStyle(fontSize: 24,
                          fontWeight: FontWeight.bold, color: Colors.white)),
                      Text(DateFormat('MMM', 'pt_BR').format(inicio).toUpperCase(),
                        style: const TextStyle(fontSize: 12,
                          fontWeight: FontWeight.w600, color: Colors.white)),
                    ],
                  ),
                );
  }

  Widget _cardEvento(Evento evento) {
    final inicio = evento.dataInicio.toLocal();
    final encerrado = evento.dataFim.isBefore(DateTime.now());
    final esgotado = evento.vagasDisponiveis != null && evento.vagasDisponiveis! <= 0;
    final disponivel = !encerrado && !esgotado && evento.inscricoesAbertas;
    final corStatus = encerrado ? const Color(0xFF727987) :
        disponivel ? AppTheme.verde : const Color(0xFFC48725);
    final textoStatus = encerrado ? 'Encerrado' :
        esgotado ? 'Esgotado' :
        evento.inscricoesAbertas ? 'Inscrições abertas' : 'Inscrições fechadas';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        boxShadow: const [BoxShadow(
          color: Color(0x08000000), blurRadius: 10, offset: Offset(0, 3)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () async {
            await Navigator.push(context, MaterialPageRoute(
              builder: (_) => DetalhesEventoScreen(evento: evento),
            ));
            if (mounted) await carregar();
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (evento.imagemUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(13),
                    child: Image.network(
                      '${ApiConfig.baseUrl}${evento.imagemUrl}',
                      width: 88, height: 112, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _blocoData(inicio),
                    ),
                  )
                else
                  _blocoData(inicio),
                const SizedBox(width: 12),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(evento.tipo.isEmpty ? 'Evento' : evento.tipo,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11,
                        color: AppTheme.roxo, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 5),
                    Text(evento.titulo, maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 15,
                        height: 1.2, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(children: [
                      const Icon(Icons.schedule_outlined, size: 14,
                          color: AppTheme.textoSecundario),
                      const SizedBox(width: 4),
                      Text(DateFormat('HH:mm').format(inicio),
                        style: const TextStyle(fontSize: 12,
                          color: AppTheme.textoSecundario)),
                      const SizedBox(width: 10),
                      const Icon(Icons.location_on_outlined, size: 14,
                          color: AppTheme.textoSecundario),
                      const SizedBox(width: 3),
                      Expanded(child: Text(evento.cidade.isEmpty ? 'Local não informado' : evento.cidade,
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12,
                          color: AppTheme.textoSecundario))),
                    ]),
                    const SizedBox(height: 9),
                    Wrap(spacing: 7, runSpacing: 5, children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: corStatus.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(30)),
                        child: Text(textoStatus, style: TextStyle(
                          fontSize: 10, fontWeight: FontWeight.w600, color: corStatus)),
                      ),
                      if (evento.vagasDisponiveis != null)
                        Text('${evento.vagasDisponiveis} vagas',
                          style: const TextStyle(fontSize: 11,
                            color: AppTheme.textoSecundario)),
                    ]),
                  ],
                )),
                const Icon(Icons.chevron_right, size: 18,
                  color: AppTheme.textoSecundario),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _estadoVazio() {
    return Container(
      padding:
          const EdgeInsets.all(35),

      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,

        borderRadius:
            BorderRadius.circular(22),
      ),

      child: const Column(
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 58,
            color:
                AppTheme.textoSecundario,
          ),

          SizedBox(
            height: 14,
          ),

          Text(
            'Nenhum evento encontrado.',
            style: TextStyle(
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          SizedBox(
            height: 5,
          ),

          Text(
            'Tente alterar sua busca ou categoria.',
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
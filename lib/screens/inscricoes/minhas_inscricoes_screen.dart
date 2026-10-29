import 'dart:async';
import '../../widgets/eventos_por_periodo.dart';
import '../hub/calendario_screen.dart';
import '../hub/chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../config/app_theme.dart';
import '../../models/inscricao.dart';
import '../../models/evento.dart';
import '../../services/inscricao_service.dart';
import '../../services/evento_service.dart';
import 'qr_inscricao_screen.dart';

class MinhasInscricoesScreen
    extends StatefulWidget {
  const MinhasInscricoesScreen({
    super.key,
  });

  @override
  State<MinhasInscricoesScreen>
      createState() =>
          _MinhasInscricoesScreenState();
}

class _MinhasInscricoesScreenState
    extends State<MinhasInscricoesScreen> with WidgetsBindingObserver {
  Timer? _timer;
  bool _buscando = false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) carregar(silencioso: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  final InscricaoService service =
      InscricaoService();
  final EventoService eventoService = EventoService();

  List<Inscricao> inscricoes = [];
  final Map<int, Evento> detalhesEventos = {};

  bool carregando = true;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (mounted &&
          WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed &&
          (ModalRoute.of(context)?.isCurrent ?? false)) {
        carregar(silencioso: true);
      }
    });
    carregar();
  }

  Future<void> carregar({bool silencioso = false}) async {
    if (_buscando) return;
    _buscando = true;
    try {
      final lista =
          await service.listarMinhas();

      final agora = DateTime.now();

      final listaVisivel = lista.where(
        (inscricao) {
          if (inscricao.status != 'CANCELADO') {
            return true;
          }

          if (inscricao.dataCancelamento == null) {
            return true;
          }

          final diferenca =
              agora.difference(
            inscricao.dataCancelamento!,
          );

          return diferenca.inDays < 3;
        },
      ).toList();    

      // Busca os detalhes de cada evento para enriquecer os cards.
      // Se algum detalhe falhar, a inscrição continua aparecendo normalmente.
      final ids = listaVisivel.map((e) => e.eventoId).toSet();
      final detalhes = <int, Evento>{};
      await Future.wait(ids.map((id) async {
        try {
          detalhes[id] = await eventoService.buscarPorId(id);
        } catch (_) {
          // Falha de um evento não impede as outras inscrições.
        }
      }));

      if (!mounted) return;

      setState(() {
        detalhesEventos..clear()..addAll(detalhes);
        inscricoes = listaVisivel;
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
            'Não foi possível carregar suas inscrições.',
          ),
        ),
      );
    } finally {
      _buscando = false;
    }
  }

  Future<void> cancelar(
    Inscricao inscricao,
  ) async {
    final confirmar =
        await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text(
            'Cancelar inscrição?',
          ),
          content: Text(
            'Deseja cancelar sua inscrição em ${inscricao.eventoTitulo}?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child: const Text(
                'Não',
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              child: const Text(
                'Cancelar inscrição',
              ),
            ),
          ],
        );
      },
    );

    if (confirmar != true) {
      return;
    }

    try {
      await service.cancelar(
        inscricao.id,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Inscrição cancelada.',
          ),
        ),
      );

      await carregar();
    } catch (erro) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            erro
                .toString()
                .replaceFirst(
                  'Exception: ',
                  '',
                ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Minhas inscrições',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: carregar,
        child: carregando
            ? const Center(
                child:
                    CircularProgressIndicator(),
              )
            : inscricoes.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(
                        height: 180,
                      ),
                      Icon(
                        Icons
                            .confirmation_number_outlined,
                        size: 65,
                        color: AppTheme
                            .textoSecundario,
                      ),
                      SizedBox(
                        height: 18,
                      ),
                      Center(
                        child: Text(
                          'Você ainda não possui inscrições.',
                          style: TextStyle(
                            color: AppTheme
                                .textoSecundario,
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView(
                    padding: const EdgeInsets.all(20),
                    children: [EventosPorPeriodo<Inscricao>(
                      itens: inscricoes,
                      inicio: (i) => detalhesEventos[i.eventoId]?.dataInicio,
                      fim: (i) => detalhesEventos[i.eventoId]?.dataFim,
                      construir: _card,
                    )],
                  ),
      ),
    );
  }

  Widget _card(
    Inscricao inscricao,
  ) {
    final cancelada =
        inscricao.status ==
            'CANCELADO';

    final presente =
        inscricao.status ==
            'PRESENTE';

    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 15,
      ),
      padding:
          const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius:
            BorderRadius.circular(22),
        border: Border.all(
          color: const Color(
            0xFFEBEDF2,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  inscricao
                      .eventoTitulo,
                  style:
                      const TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),

              _status(
                inscricao.status,
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Mostra informações do evento retornadas pela API.
          _informacoesEvento(inscricao),

          if (inscricao.dataInscricao != null) ...[
            const SizedBox(height: 10),
            _linhaInfo(
              Icons.how_to_reg_outlined,
              'Inscrição realizada em ${DateFormat('dd/MM/yyyy').format(inscricao.dataInscricao!.toLocal())}',
            ),
          ],

          const SizedBox(height: 18),

          if (!cancelada)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: OutlinedButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => ChatScreen(
                    eventoId: inscricao.eventoId,
                    eventoTitulo: inscricao.eventoTitulo,
                    canal: 'GERAL',
                  ),
                )),
                icon: const Icon(Icons.forum_outlined),
                label: const Text('Chat geral do evento'),
              ),
            ),
          if (!cancelada)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: const Text('Ver programação do evento'),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => CalendarioScreen(
                      eventoId: inscricao.eventoId,
                      eventoTitulo: inscricao.eventoTitulo,
                      somenteLeitura: true,
                    ),
                  )),
                ),
              ),
            ),
          if (!cancelada)
            SizedBox(
              width: double.infinity,
              child:
                  FilledButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          QrInscricaoScreen(
                        inscricao:
                            inscricao,
                        evento: detalhesEventos[inscricao.eventoId],
                      ),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.qr_code_2,
                ),
                label: Text(
                  presente
                      ? 'Ver ingresso'
                      : 'Ver ingresso digital',
                ),
              ),
            ),

          if (!cancelada &&
              !presente) ...[
            const SizedBox(
              height: 8,
            ),

            SizedBox(
              width:
                  double.infinity,
              child:
                  TextButton.icon(
                onPressed: () =>
                    cancelar(
                  inscricao,
                ),
                icon: const Icon(
                  Icons.close,
                ),
                label: const Text(
                  'Cancelar inscrição',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _informacoesEvento(Inscricao inscricao) {
    final evento = detalhesEventos[inscricao.eventoId];

    if (evento == null) {
      return _linhaInfo(
        Icons.event_outlined,
        'Código do evento: ${inscricao.eventoId}',
      );
    }

    final inicio = evento.dataInicio.toLocal();
    final fim = evento.dataFim.toLocal();
    final mesmaData = inicio.year == fim.year &&
        inicio.month == fim.month && inicio.day == fim.day;
    final dataTexto = mesmaData
        ? '${DateFormat('dd/MM/yyyy').format(inicio)} • ${DateFormat('HH:mm').format(inicio)}–${DateFormat('HH:mm').format(fim)}'
        : '${DateFormat('dd/MM/yyyy HH:mm').format(inicio)} até ${DateFormat('dd/MM/yyyy HH:mm').format(fim)}';

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (evento.tipo.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.roxo.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  evento.tipo,
                  style: const TextStyle(
                    color: AppTheme.roxo,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          _linhaInfo(Icons.calendar_month_outlined, dataTexto),
          if (evento.cidade.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            _linhaInfo(Icons.location_on_outlined, evento.cidade),
          ],
          if (evento.endereco.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            _linhaInfo(Icons.place_outlined, evento.endereco),
          ],
          if (evento.descricao.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              evento.descricao,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTheme.textoSecundario,
                height: 1.35,
                fontSize: 13,
              ),
            ),
          ],
          if (evento.cargaHoraria != null && evento.cargaHoraria! > 0) ...[
            const SizedBox(height: 8),
            _linhaInfo(Icons.schedule_outlined, '${evento.cargaHoraria} horas de carga horária'),
          ],
        ],
      ),
    );
  }

  Widget _linhaInfo(IconData icone, String texto) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icone, size: 17, color: AppTheme.roxo),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            texto,
            style: const TextStyle(
              color: AppTheme.textoSecundario,
              fontSize: 13,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }

  Widget _status(
    String status,
  ) {
    Color cor;

    switch (status) {
      case 'PRESENTE':
        cor = AppTheme.verde;
        break;

      case 'CANCELADO':
        cor = Colors.red;
        break;

      default:
        cor = AppTheme.roxo;
    }

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: cor.withValues(
          alpha: 0.10,
        ),
        borderRadius:
            BorderRadius.circular(
          100,
        ),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: cor,
          fontSize: 11,
          fontWeight:
              FontWeight.bold,
        ),
      ),
    );
  }
}
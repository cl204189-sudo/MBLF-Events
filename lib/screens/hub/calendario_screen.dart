import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/app_theme.dart';
import '../../models/agenda_evento.dart';
import '../../services/agenda_service.dart';

class CalendarioScreen extends StatefulWidget {
  final int eventoId;
  final String eventoTitulo;
  final bool somenteLeitura;

  const CalendarioScreen({
    super.key,
    required this.eventoId,
    required this.eventoTitulo,
    this.somenteLeitura = false,
  });

  @override
  State<CalendarioScreen> createState() => _CalendarioScreenState();
}

class _CalendarioScreenState extends State<CalendarioScreen>
    with WidgetsBindingObserver {
  final AgendaService service = AgendaService();

  List<AgendaEvento> itens = [];
  DateTime mesVisivel = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime? diaSelecionado;

  bool carregando = true;
  int _antecedenciaMinutos = 30;

  Future<void> _carregarPreferenciaLembrete() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(
      () =>
          _antecedenciaMinutos = prefs.getInt('agenda_lembrete_minutos') ?? 30,
    );
  }

  Timer? _syncTimer;
  final Set<String> _lembretesExibidos = {};
  bool _avisosNestaTela = true;
  bool _syncAtivo = true;
  bool _syncEmAndamento = false;
  bool _syncPendente = false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _syncAtivo = state == AppLifecycleState.resumed;
    if (_syncAtivo) {
      carregar(silencioso: true);
      _verificarLembretes();
    }
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _syncTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      _verificarLembretes();
      if (_syncAtivo &&
          mounted &&
          (ModalRoute.of(context)?.isCurrent ?? false)) {
        carregar(silencioso: true);
        _verificarLembretes();
      }
    });

    _carregarPreferenciaLembrete();
    carregar();
  }

  Future<void> carregar({bool silencioso = false}) async {
    if (_syncEmAndamento) {
      if (!silencioso) _syncPendente = true;
      return;
    }
    _syncEmAndamento = true;
    try {
      final lista = widget.somenteLeitura
          ? await service.listarParaInscrito(widget.eventoId)
          : await service.listar(widget.eventoId);

      if (!mounted) return;

      setState(() {
        itens = lista;
        carregando = false;
      });
      _verificarLembretes();
    } catch (erro) {
      if (!mounted) return;

      setState(() {
        carregando = false;
      });

      if (!silencioso)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(erro.toString().replaceFirst('Exception: ', '')),
          ),
        );
    } finally {
      _syncEmAndamento = false;
      if (_syncPendente && mounted) {
        _syncPendente = false;
        carregar(silencioso: true);
      }
    }
  }

  // Avisos locais enquanto o calendário está aberto. Não são notificações push.
  void _verificarLembretes() {
    if (!mounted ||
        !_avisosNestaTela ||
        !_syncAtivo ||
        !(ModalRoute.of(context)?.isCurrent ?? false))
      return;
    final agora = DateTime.now();
    for (final item in itens) {
      final restante = item.dataInicio.difference(agora);
      if (restante.isNegative || restante > const Duration(minutes: 30))
        continue;
      final chave = '${item.id}:${item.dataInicio.toIso8601String()}';
      if (_lembretesExibidos.add(chave)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Em breve: ${item.titulo} às ${DateFormat('HH:mm').format(item.dataInicio)}',
            ),
            duration: const Duration(seconds: 6),
          ),
        );
        break;
      }
    }
  }

  Future<void> abrirCriacao() async {
    final tituloController = TextEditingController();

    final descricaoController = TextEditingController();

    DateTime data = DateTime.now().add(const Duration(days: 1));

    TimeOfDay hora = TimeOfDay.now();

    String tipo = 'REUNIAO';
    
    TimeOfDay? horaFim;

    final criou = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Novo compromisso',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 20),

                    TextField(
                      controller: tituloController,
                      decoration: const InputDecoration(labelText: 'Título'),
                    ),

                    const SizedBox(height: 14),

                    TextField(
                      controller: descricaoController,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Descrição'),
                    ),

                    const SizedBox(height: 14),

                    DropdownButtonFormField<String>(
                      value: tipo,
                      items: const [
                        DropdownMenuItem(
                          value: 'REUNIAO',
                          child: Text('Reunião'),
                        ),
                        DropdownMenuItem(
                          value: 'ENTREGA',
                          child: Text('Entrega'),
                        ),
                        DropdownMenuItem(value: 'OUTRO', child: Text('Outro')),
                      ],
                      onChanged: (valor) {
                        if (valor == null) {
                          return;
                        }

                        setModalState(() {
                          tipo = valor;
                        });
                      },
                      decoration: const InputDecoration(labelText: 'Tipo'),
                    ),

                    const SizedBox(height: 18),

                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.calendar_today_outlined,
                        color: AppTheme.roxo,
                      ),
                      title: const Text('Data'),
                      subtitle: Text(DateFormat('dd/MM/yyyy').format(data)),
                      onTap: () async {
                        final escolhida = await showDatePicker(
                          context: context,
                          initialDate: data,
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2035),
                        );

                        if (escolhida != null) {
                          setModalState(() {
                            data = escolhida;
                          });
                        }
                      },
                    ),

                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.access_time_outlined,
                        color: AppTheme.verde,
                      ),
                      title: const Text('Horário'),
                      subtitle: Text(hora.format(context)),
                      onTap: () async {
                        final escolhida = await showTimePicker(
                          context: context,
                          initialTime: hora,
                        );

                        if (escolhida != null) {
                          setModalState(() {
                            hora = escolhida;
                          });
                        }
                      },
                    ),

                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.event_available_outlined),
                      title: const Text('Horário de término (opcional)'),
                      subtitle: Text(
                        horaFim == null
                            ? 'Não definido'
                            : horaFim!.format(context),
                      ),
                      trailing: horaFim == null
                          ? null
                          : IconButton(
                              tooltip: 'Remover horário de término',
                              onPressed: () =>
                                  setModalState(() => horaFim = null),
                              icon: const Icon(Icons.close),
                            ),
                      onTap: () async {
                        final escolhido = await showTimePicker(
                          context: context,
                          initialTime: horaFim ?? hora,
                        );
                        if (escolhido != null)
                          setModalState(() => horaFim = escolhido);
                      },
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () async {
                          if (tituloController.text.trim().isEmpty) {
                            return;
                          }

                          final dataCompleta = DateTime(
                            data.year,
                            data.month,
                            data.day,
                            hora.hour,
                            hora.minute,
                          );

                          final horaFinalSelecionada = horaFim;

                          final DateTime? termino = horaFinalSelecionada == null
                              ? null
                              : DateTime(
                                  data.year,
                                  data.month,
                                  data.day,
                                  horaFinalSelecionada.hour,
                                  horaFinalSelecionada.minute,
                                );
                          if (!dataCompleta.isAfter(DateTime.now()) ||
                              (termino != null &&
                                  !termino.isAfter(dataCompleta))) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Escolha um início futuro e um término posterior ao início.',
                                ),
                              ),
                            );
                            return;
                          }
                          try {
                            await service.criar(
                              widget.eventoId,
                              titulo: tituloController.text.trim(),
                              descricao: descricaoController.text.trim(),
                              dataInicio: dataCompleta,
                              dataFim: termino,
                              tipo: tipo,
                            );

                            if (!context.mounted) {
                              return;
                            }

                            Navigator.pop(context, true);
                          } catch (erro) {
                            if (!context.mounted) {
                              return;
                            }

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  erro.toString().replaceFirst(
                                    'Exception: ',
                                    '',
                                  ),
                                ),
                              ),
                            );
                          }
                        },
                        child: const Text('Adicionar ao calendário'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    tituloController.dispose();
    descricaoController.dispose();

    if (criou == true) {
      await carregar();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            tooltip: _avisosNestaTela
                ? 'Desativar avisos nesta tela'
                : 'Ativar avisos nesta tela',
            icon: Icon(
              _avisosNestaTela
                  ? Icons.notifications_active_outlined
                  : Icons.notifications_off_outlined,
            ),
            onPressed: () =>
                setState(() => _avisosNestaTela = !_avisosNestaTela),
          ),
        ],
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.somenteLeitura ? 'Programação do evento' : 'Calendário',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              widget.eventoTitulo,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textoSecundario,
              ),
            ),
          ],
        ),
      ),

      floatingActionButton: widget.somenteLeitura
          ? null
          : FloatingActionButton.extended(
              onPressed: abrirCriacao,
              icon: const Icon(Icons.add),
              label: const Text('Adicionar'),
            ),

      body: RefreshIndicator(
        onRefresh: carregar,
        child: carregando
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.chevron_left),
                                tooltip: 'Mês anterior',
                                onPressed: () => setState(() {
                                  mesVisivel = DateTime(
                                    mesVisivel.year,
                                    mesVisivel.month - 1,
                                  );
                                  diaSelecionado = null;
                                }),
                              ),
                              Expanded(
                                child: Text(
                                  DateFormat(
                                    'MMMM yyyy',
                                    'pt_BR',
                                  ).format(mesVisivel),
                                  textAlign: TextAlign.center,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.chevron_right),
                                tooltip: 'Próximo mês',
                                onPressed: () => setState(() {
                                  mesVisivel = DateTime(
                                    mesVisivel.year,
                                    mesVisivel.month + 1,
                                  );
                                  diaSelecionado = null;
                                }),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: ['S', 'T', 'Q', 'Q', 'S', 'S', 'D']
                                .map(
                                  (d) => Expanded(
                                    child: Center(
                                      child: Text(
                                        d,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.labelSmall,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                          const SizedBox(height: 8),
                          ...List.generate(
                            6,
                            (semana) => Row(
                              children: List.generate(7, (coluna) {
                                final primeiro = DateTime(
                                  mesVisivel.year,
                                  mesVisivel.month,
                                  1,
                                );
                                final deslocamento = primeiro.weekday - 1;
                                final dia =
                                    semana * 7 + coluna - deslocamento + 1;
                                final total = DateTime(
                                  mesVisivel.year,
                                  mesVisivel.month + 1,
                                  0,
                                ).day;
                                if (dia < 1 || dia > total)
                                  return const Expanded(
                                    child: SizedBox(height: 43),
                                  );
                                final data = DateTime(
                                  mesVisivel.year,
                                  mesVisivel.month,
                                  dia,
                                );
                                final temAtividade = itens.any(
                                  (a) =>
                                      a.dataInicio.year == data.year &&
                                      a.dataInicio.month == data.month &&
                                      a.dataInicio.day == data.day,
                                );
                                final selecionado =
                                    diaSelecionado?.year == data.year &&
                                    diaSelecionado?.month == data.month &&
                                    diaSelecionado?.day == data.day;
                                return Expanded(
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () => setState(
                                      () => diaSelecionado = selecionado
                                          ? null
                                          : data,
                                    ),
                                    child: Container(
                                      height: 43,
                                      margin: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        color: selecionado
                                            ? Theme.of(
                                                context,
                                              ).colorScheme.primaryContainer
                                            : null,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            '$dia',
                                            style: TextStyle(
                                              fontWeight: selecionado
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                            ),
                                          ),
                                          if (temAtividade)
                                            Container(
                                              width: 5,
                                              height: 5,
                                              decoration: BoxDecoration(
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                          TextButton(
                            onPressed: () => setState(() {
                              mesVisivel = DateTime(
                                DateTime.now().year,
                                DateTime.now().month,
                              );
                              diaSelecionado = null;
                            }),
                            child: const Text('Ir para o mês atual'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.notifications_active_outlined),
                          const SizedBox(width: 8),
                          const Expanded(child: Text('Lembrete na tela')),
                          DropdownButton<int>(
                            value: _antecedenciaMinutos,
                            underline: const SizedBox.shrink(),
                            items: const [15, 30, 60]
                                .map(
                                  (min) => DropdownMenuItem(
                                    value: min,
                                    child: Text('$min min'),
                                  ),
                                )
                                .toList(),
                            onChanged: (valor) async {
                              if (valor == null) return;
                              setState(() => _antecedenciaMinutos = valor);
                              final prefs =
                                  await SharedPreferences.getInstance();
                              await prefs.setInt(
                                'agenda_lembrete_minutos',
                                valor,
                              );
                              _verificarLembretes();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Os avisos aparecem enquanto esta tela estiver aberta.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  Builder(
                    builder: (context) {
                      final agora = DateTime.now();
                      final proximas =
                          itens
                              .where((e) => e.dataInicio.isAfter(agora))
                              .toList()
                            ..sort(
                              (a, b) => a.dataInicio.compareTo(b.dataInicio),
                            );
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Próximas atividades',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text('${proximas.length} atividade(s) futura(s)'),
                              if (proximas.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  '${proximas.first.titulo} • ${DateFormat('dd/MM HH:mm').format(proximas.first.dataInicio)}',
                                ),
                              ],
                              const SizedBox(height: 6),
                              Text(
                                'Avisos de 30 minutos aparecem somente com esta tela aberta.',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 18),
                  Text(
                    diaSelecionado == null
                        ? 'Atividades do mês'
                        : DateFormat('dd/MM/yyyy').format(diaSelecionado!),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  ...(() {
                    final filtrados =
                        itens
                            .where(
                              (a) => diaSelecionado != null
                                  ? a.dataInicio.year == diaSelecionado!.year &&
                                        a.dataInicio.month ==
                                            diaSelecionado!.month &&
                                        a.dataInicio.day == diaSelecionado!.day
                                  : a.dataInicio.year == mesVisivel.year &&
                                        a.dataInicio.month == mesVisivel.month,
                            )
                            .toList()
                          ..sort(
                            (a, b) => a.dataInicio.compareTo(b.dataInicio),
                          );
                    if (filtrados.isEmpty)
                      return <Widget>[
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Center(
                            child: Text(
                              widget.somenteLeitura
                                  ? 'Nenhuma atividade programada neste período.'
                                  : 'Nenhuma atividade neste período. Toque em Adicionar para criar uma.',
                            ),
                          ),
                        ),
                      ];
                    return filtrados.map(_card).toList();
                  })(),
                ],
              ),
      ),
    );
  }

  Widget _card(AgendaEvento item) {
    final dia = DateFormat('dd').format(item.dataInicio);

    final mes = DateFormat('MMM', 'pt_BR').format(item.dataInicio);

    final hora = DateFormat('HH:mm').format(item.dataInicio);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: const Color(0xFFEBEDF2)),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 64,
            decoration: BoxDecoration(
              gradient: AppTheme.gradientePrincipal,
              borderRadius: BorderRadius.circular(17),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  dia,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  mes.toUpperCase(),
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),

          const SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.titulo,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  item.descricao,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppTheme.textoSecundario),
                ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    const Icon(
                      Icons.access_time_outlined,
                      size: 16,
                      color: AppTheme.verde,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      item.dataFim == null
                          ? hora
                          : '$hora – ${DateFormat('HH:mm').format(item.dataFim!)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

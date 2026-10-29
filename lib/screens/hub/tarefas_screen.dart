import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../config/app_theme.dart';
import '../../models/tarefa_evento.dart';
import '../../services/tarefa_service.dart';

class TarefasScreen extends StatefulWidget {
  final int eventoId;
  final String eventoTitulo;

  const TarefasScreen({
    super.key,
    required this.eventoId,
    required this.eventoTitulo,
  });

  @override
  State<TarefasScreen> createState() =>
      _TarefasScreenState();
}

class _TarefasScreenState
    extends State<TarefasScreen> with WidgetsBindingObserver {
  final TarefaService service =
      TarefaService();

  List<TarefaEvento> tarefas = [];
  String filtroStatus = 'Todas';


  bool carregando = true;

  Timer? _syncTimer;
  bool _syncAtivo = true;
  bool _syncEmAndamento = false;
  bool _syncPendente = false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _syncAtivo = state == AppLifecycleState.resumed;
    if (_syncAtivo) carregar(silencioso: true);
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
      if (_syncAtivo && mounted && (ModalRoute.of(context)?.isCurrent ?? false)) {
        carregar(silencioso: true);
      }
    });
    carregar();
  }

  Future<void> carregar({bool silencioso = false}) async {
    if (_syncEmAndamento) {
      if (!silencioso) _syncPendente = true;
      return;
    }
    _syncEmAndamento = true;
    try {
      final lista = await service.listar(
        widget.eventoId,
      );

      if (!mounted) return;

      setState(() {
        tarefas = lista;
        carregando = false;
      });
    } catch (erro) {
      if (!mounted) return;

      setState(() {
        carregando = false;
      });

      if (!silencioso) ScaffoldMessenger.of(context)
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
    finally {
      _syncEmAndamento = false;
      if (_syncPendente && mounted) {
        _syncPendente = false;
        carregar(silencioso: true);
      }
    }
  }

  Future<void> criarTarefa() async {
    final tituloController =
        TextEditingController();

    final descricaoController =
        TextEditingController();

    String prioridade = 'MEDIA';

    DateTime? prazo;

    final criou =
        await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) {
        return StatefulBuilder(
          builder: (
            context,
            setModalState,
          ) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.of(context)
                        .viewInsets
                        .bottom +
                    20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Nova tarefa',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 20),

                    TextField(
                      controller:
                          tituloController,
                      decoration:
                          const InputDecoration(
                        labelText: 'Título',
                      ),
                    ),

                    const SizedBox(height: 14),

                    TextField(
                      controller:
                          descricaoController,
                      maxLines: 3,
                      decoration:
                          const InputDecoration(
                        labelText:
                            'Descrição',
                      ),
                    ),

                    const SizedBox(height: 14),

                    DropdownButtonFormField<
                        String>(
                      value: prioridade,
                      items: const [
                        DropdownMenuItem(
                          value: 'BAIXA',
                          child: Text('Baixa'),
                        ),
                        DropdownMenuItem(
                          value: 'MEDIA',
                          child: Text('Média'),
                        ),
                        DropdownMenuItem(
                          value: 'ALTA',
                          child: Text('Alta'),
                        ),
                      ],
                      onChanged: (valor) {
                        if (valor == null) {
                          return;
                        }

                        setModalState(() {
                          prioridade = valor;
                        });
                      },
                      decoration:
                          const InputDecoration(
                        labelText:
                            'Prioridade',
                      ),
                    ),

                    const SizedBox(height: 15),

                    ListTile(
                      contentPadding:
                          EdgeInsets.zero,
                      leading: const Icon(
                        Icons.event_outlined,
                        color: AppTheme.roxo,
                      ),
                      title: const Text(
                        'Prazo',
                      ),
                      subtitle: Text(
                        prazo == null
                            ? 'Sem prazo definido'
                            : DateFormat(
                                'dd/MM/yyyy',
                              ).format(
                                prazo!,
                              ),
                      ),
                      onTap: () async {
                        final escolhida =
                            await showDatePicker(
                          context: context,
                          initialDate:
                              DateTime.now()
                                  .add(
                            const Duration(
                              days: 1,
                            ),
                          ),
                          firstDate:
                              DateTime.now(),
                          lastDate:
                              DateTime(2035),
                        );

                        if (escolhida !=
                            null) {
                          setModalState(() {
                            prazo = escolhida;
                          });
                        }
                      },
                    ),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () async {
                          final titulo =
                              tituloController
                                  .text
                                  .trim();

                          if (titulo.isEmpty) {
                            return;
                          }

                          try {
                            await service.criar(
                              widget.eventoId,
                              titulo: titulo,
                              descricao:
                                  descricaoController
                                      .text
                                      .trim(),
                              prioridade:
                                  prioridade,
                              prazo: prazo,
                            );

                            if (!context
                                .mounted) {
                              return;
                            }

                            Navigator.pop(
                              context,
                              true,
                            );
                          } catch (erro) {
                            if (!context
                                .mounted) {
                              return;
                            }

                            ScaffoldMessenger
                                    .of(context)
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
                        },
                        child: const Text(
                          'Criar tarefa',
                        ),
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

  Future<void> mudarStatus(
    TarefaEvento tarefa,
    String status,
  ) async {
    try {
      await service.alterarStatus(
        tarefa.id,
        status,
      );

      await carregar();
    } catch (erro) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível alterar a tarefa.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'Tarefas',
              style: TextStyle(
                fontWeight:
                    FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              widget.eventoTitulo,
              style: const TextStyle(
                fontSize: 12,
                color:
                    AppTheme.textoSecundario,
              ),
            ),
          ],
        ),
      ),

      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: criarTarefa,
        icon: const Icon(Icons.add),
        label: const Text(
          'Nova tarefa',
        ),
      ),

      body: RefreshIndicator(
        onRefresh: carregar,
        child: carregando ? const Center(child: CircularProgressIndicator()) : ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          children: [
            Row(children: [
              Expanded(child: _resumoTarefa('Pendentes', tarefas.where((t) => t.status == 'PENDENTE').length)),
              const SizedBox(width: 8),
              Expanded(child: _resumoTarefa('Em andamento', tarefas.where((t) => t.status == 'EM_ANDAMENTO').length)),
              const SizedBox(width: 8),
              Expanded(child: _resumoTarefa('Concluídas', tarefas.where((t) => t.status == 'CONCLUIDA').length)),
            ]),
            const SizedBox(height: 16),
            SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(
              children: ['Todas', 'Pendentes', 'Em andamento', 'Concluídas'].map((f) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(label: Text(f), selected: filtroStatus == f,
                  onSelected: (_) => setState(() => filtroStatus = f)),
              )).toList(),
            )),
            const SizedBox(height: 12),
            ...(() {
              final status = {'Pendentes': 'PENDENTE', 'Em andamento': 'EM_ANDAMENTO', 'Concluídas': 'CONCLUIDA'}[filtroStatus];
              final lista = tarefas.where((t) => status == null || t.status == status).toList();
              if (lista.isEmpty) return <Widget>[const Padding(padding: EdgeInsets.all(30), child: Center(child: Text('Nenhuma tarefa neste filtro.')))];
              return lista.map(_card).toList();
            })(),
          ],
        ),
      ),
    );
  }

  Widget _resumoTarefa(String titulo, int total) => Card(
    child: Padding(padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 5),
      child: Column(children: [
        Text('$total', style: Theme.of(context).textTheme.headlineSmall),
        Text(titulo, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11)),
      ])),
  );

  Widget _card(
    TarefaEvento tarefa,
  ) {
    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 14,
      ),
      padding:
          const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius:
            BorderRadius.circular(22),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _prioridade(
                tarefa.prioridade,
              ),

              const Spacer(),

              PopupMenuButton<String>(
                onSelected: (status) {
                  mudarStatus(
                    tarefa,
                    status,
                  );
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'PENDENTE',
                    child: Text(
                      'Pendente',
                    ),
                  ),
                  PopupMenuItem(
                    value:
                        'EM_ANDAMENTO',
                    child: Text(
                      'Em andamento',
                    ),
                  ),
                  PopupMenuItem(
                    value: 'CONCLUIDA',
                    child: Text(
                      'Concluída',
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 10),

          Text(
            tarefa.titulo,
            style: const TextStyle(
              fontSize: 18,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          if (tarefa
              .descricao.isNotEmpty) ...[
            const SizedBox(height: 7),
            Text(
              tarefa.descricao,
              style: const TextStyle(
                color: AppTheme
                    .textoSecundario,
              ),
            ),
          ],

          const SizedBox(height: 14),

          Row(
            children: [
              const Icon(
                Icons.circle,
                size: 10,
                color: AppTheme.verde,
              ),
              const SizedBox(width: 7),
              Text(
                tarefa.status
                    .replaceAll(
                      '_',
                      ' ',
                    ),
                style: const TextStyle(
                  fontWeight:
                      FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),

          if (tarefa.prazo != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons
                      .calendar_today_outlined,
                  size: 17,
                  color: AppTheme
                      .textoSecundario,
                ),
                const SizedBox(width: 7),
                Text(
                  'Prazo: ${DateFormat('dd/MM/yyyy').format(tarefa.prazo!)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme
                        .textoSecundario,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _prioridade(
    String prioridade,
  ) {
    Color cor;

    switch (prioridade) {
      case 'ALTA':
        cor = Colors.red;
        break;
      case 'BAIXA':
        cor = AppTheme.verde;
        break;
      default:
        cor = Colors.orange;
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
            BorderRadius.circular(100),
      ),
      child: Text(
        prioridade,
        style: TextStyle(
          color: cor,
          fontWeight:
              FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }
}
import 'dart:async';

import 'package:flutter/material.dart';

import '../../config/app_theme.dart';
import '../../models/evento_colaborador.dart';
import '../../services/moderacao_service.dart';
import '../../services/colaborador_hub_service.dart';

class ModeracaoScreen extends StatefulWidget {
  final int eventoId;
  final String eventoTitulo;

  final bool organizador;

  final bool podeSilenciar;
  final bool podeExpulsar;

  final List<EventoColaborador> colaboradores;

  const ModeracaoScreen({
    super.key,
    required this.eventoId,
    required this.eventoTitulo,
    required this.organizador,
    required this.podeSilenciar,
    required this.podeExpulsar,
    required this.colaboradores,
  });

  @override
  State<ModeracaoScreen> createState() =>
      _ModeracaoScreenState();
}

class _ModeracaoScreenState
    extends State<ModeracaoScreen> with WidgetsBindingObserver {
  final ModeracaoService service =
      ModeracaoService();

  bool processando = false;
  String busca = '';
  String filtro = 'Todos';
  List<Map<String, dynamic>> historico = [];
  bool mostrarHistorico = false;

  final ColaboradorHubService colaboradorService = ColaboradorHubService();
  late List<EventoColaborador> colaboradores;
  Timer? _timer;
  bool _ativo = true;
  bool _consultando = false;
  bool _reconsultar = false;

  @override
  void initState() {
    super.initState();
    colaboradores = List<EventoColaborador>.from(widget.colaboradores);
    WidgetsBinding.instance.addObserver(this);
    atualizarColaboradores();
    atualizarHistorico();
    _timer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (_ativo) { atualizarColaboradores(); atualizarHistorico(); }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _ativo = state == AppLifecycleState.resumed;
    if (_ativo) { atualizarColaboradores(); atualizarHistorico(); }
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> atualizarColaboradores() async {
    if (!mounted || !_ativo) return;
    if (_consultando) {
      _reconsultar = true;
      return;
    }
    _consultando = true;
    try {
      do {
        _reconsultar = false;
        try {
          final atualizados = await colaboradorService.listar(widget.eventoId);
          if (!mounted || !_ativo) return;
          setState(() => colaboradores = atualizados);
        } catch (_) {
          // Mantém a lista atual em falhas temporárias de conexão.
        }
      } while (_reconsultar && mounted && _ativo);
    } finally {
      _consultando = false;
    }
  }


  Future<void> atualizarHistorico() async {
    try {
      final dados = await service.historico(widget.eventoId);
      if (mounted && _ativo) setState(() => historico = dados);
    } catch (_) { /* preserva os dados anteriores */ }
  }

  Future<void> confirmarAcao(String titulo, String descricao,
      Future<void> Function() acao, String sucesso) async {
    final confirmou = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: Text(titulo), content: Text(descricao),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Voltar')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirmar')),
      ],
    ));
    if (confirmou == true && mounted) await executar(acao, sucesso);
  }

  Future<String?> pedirMotivo(
    String titulo,
  ) async {
    final controller =
        TextEditingController();

    final resultado =
        await showDialog<String>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(titulo),
          content: TextField(
            controller: controller,
            maxLines: 3,
            decoration:
                const InputDecoration(
              labelText: 'Motivo',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                'Cancelar',
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  controller.text.trim(),
                );
              },
              child: const Text(
                'Confirmar',
              ),
            ),
          ],
        );
      },
    );

    controller.dispose();

    return resultado;
  }

  Future<void> silenciar(
    EventoColaborador colaborador,
  ) async {
    final motivo =
        await pedirMotivo(
      'Silenciar ${colaborador.usuarioNome}',
    );

    if (motivo == null ||
        motivo.isEmpty) {
      return;
    }

    await executar(
      () => service.silenciar(
        widget.eventoId,
        colaborador.usuarioId,
        motivo,
      ),
      'Usuário silenciado.',
    );
  }

  Future<void> dessilenciar(
    EventoColaborador colaborador,
  ) async {
    await executar(
      () => service.dessilenciar(
        widget.eventoId,
        colaborador.usuarioId,
      ),
      'Silenciamento removido.',
    );
  }

  Future<void> expulsar(
    EventoColaborador colaborador,
  ) async {
    final motivo =
        await pedirMotivo(
      'Expulsar ${colaborador.usuarioNome}',
    );

    if (motivo == null ||
        motivo.isEmpty) {
      return;
    }

    await executar(
      () => service.expulsar(
        widget.eventoId,
        colaborador.usuarioId,
        motivo,
      ),
      'Usuário expulso.',
    );
  }

  Future<void> executar(
    Future<void> Function() acao,
    String sucesso,
  ) async {
    if (processando) return;

    setState(() {
      processando = true;
    });

    try {
      await acao();
      await atualizarColaboradores();
      await atualizarHistorico();

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(sucesso),
        ),
      );
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
    } finally {
      if (mounted) {
        setState(() {
          processando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colaboradoresAtivos =
        colaboradores
            .where(
              (c) =>
                  c.status ==
                  'ACEITO',
            )
            .toList();

    final filtrados = colaboradoresAtivos.where((c) {
      final nomeOk = c.usuarioNome.toLowerCase().contains(busca.toLowerCase());
      final statusOk = filtro == 'Todos' ||
          (filtro == 'Silenciados' && c.silenciado) ||
          (filtro == 'Liberados' && !c.silenciado);
      return nomeOk && statusOk;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'Moderação',
              style: TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.bold,
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

      body: ListView(
        padding:
            const EdgeInsets.all(20),
        children: [
          if (widget.organizador) ...[
            const Text(
              'Chat geral',
              style: TextStyle(
                fontSize: 19,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 12,
            ),

            Row(
              children: [
                Expanded(
                  child:
                      FilledButton.icon(
                    onPressed: processando
                        ? null
                        : () {
                            confirmarAcao('Silenciar chat geral',
                              'Isso impedirá novas mensagens no chat geral até que seja liberado.',
                              () => service
                                  .silenciarTodos(
                                widget
                                    .eventoId,
                              ),
                              'Chat silenciado para todos.',
                            );
                          },
                    icon: const Icon(
                      Icons
                          .volume_off_outlined,
                    ),
                    label: const Text(
                      'Silenciar todos',
                    ),
                  ),
                ),

                const SizedBox(
                  width: 10,
                ),

                Expanded(
                  child:
                      OutlinedButton.icon(
                    onPressed: processando
                        ? null
                        : () {
                            confirmarAcao('Liberar chat geral',
                              'Deseja permitir novamente mensagens no chat geral?',
                              () => service
                                  .liberarTodos(
                                widget
                                    .eventoId,
                              ),
                              'Chat liberado para todos.',
                            );
                          },
                    icon: const Icon(
                      Icons
                          .volume_up_outlined,
                    ),
                    label: const Text(
                      'Liberar todos',
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 30,
            ),
          ],

          Wrap(spacing: 8, runSpacing: 8, children: [
            _resumo('Ativos', colaboradoresAtivos.length),
            _resumo('Silenciados', colaboradoresAtivos.where((c) => c.silenciado).length),
            _resumo('Ações', historico.length),
          ]),
          const SizedBox(height: 18),
          TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Pesquisar colaborador',
              border: OutlineInputBorder(),
            ),
            onChanged: (v) => setState(() => busca = v),
          ),
          const SizedBox(height: 10),
          Wrap(spacing: 8, children: ['Todos', 'Silenciados', 'Liberados'].map((f) =>
            ChoiceChip(label: Text(f), selected: filtro == f,
              onSelected: (_) => setState(() => filtro = f))).toList()),
          const SizedBox(height: 18),
          const Text(
            'Colaboradores',
            style: TextStyle(
              fontSize: 19,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          if (filtrados.isEmpty)
            const Padding(
              padding:
                  EdgeInsets.all(30),
              child: Center(
                child: Text(
                  'Nenhum colaborador ativo para moderar.',
                  style: TextStyle(
                    color: AppTheme
                        .textoSecundario,
                  ),
                ),
              ),
            )
          else
            ...filtrados.map(
              _cardColaborador,
            ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: () => setState(() => mostrarHistorico = !mostrarHistorico),
            icon: const Icon(Icons.history),
            label: Text(mostrarHistorico ? 'Ocultar histórico' : 'Ver histórico de moderação'),
          ),
          if (mostrarHistorico) ...[
            const SizedBox(height: 10),
            if (historico.isEmpty) const Text('Nenhuma ação registrada.'),
            ...historico.take(100).map((h) => Card(
              child: ListTile(
                title: Text('${h['acao'] ?? 'Ação'} • ${h['alvoNome'] ?? 'Chat geral'}'),
                subtitle: Text('Por ${h['executorNome'] ?? 'Desconhecido'} • ${h['dataAcao'] ?? ''}\n${h['motivo'] ?? 'Sem motivo informado'}'),
                isThreeLine: true,
              ),
            )),
          ],
        ],
      ),
    );
  }

  Widget _resumo(String titulo, int valor) => Chip(
    label: Text('$titulo: $valor'),
  );

  Widget _cardColaborador(
    EventoColaborador colaborador,
  ) {
    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),
      padding:
          const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color: const Color(
            0xFFEBEDF2,
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor:
                    AppTheme.roxo
                        .withValues(
                  alpha: 0.10,
                ),
                child: Text(
                  colaborador
                          .usuarioNome
                          .isNotEmpty
                      ? colaborador
                          .usuarioNome[0]
                          .toUpperCase()
                      : '?',
                  style:
                      const TextStyle(
                    color:
                        AppTheme.roxo,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(
                width: 12,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Text(
                      colaborador
                          .usuarioNome,
                      style:
                          const TextStyle(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    Text(
                      colaborador.funcao,
                      style:
                          const TextStyle(
                        fontSize: 12,
                        color: AppTheme
                            .textoSecundario,
                      ),
                    ),
                  ],
                ),
              ),

              if (colaborador
                  .silenciado)
                const Icon(
                  Icons.volume_off,
                  color: Colors.red,
                ),
            ],
          ),

          const SizedBox(
            height: 14,
          ),

          Row(
            children: [
              if (widget
                  .podeSilenciar)
                Expanded(
                  child: colaborador
                          .silenciado
                      ? OutlinedButton(
                          onPressed:
                              processando
                                  ? null
                                  : () =>
                                      dessilenciar(
                                    colaborador,
                                  ),
                          child:
                              const Text(
                            'Liberar',
                          ),
                        )
                      : OutlinedButton(
                          onPressed:
                              processando
                                  ? null
                                  : () =>
                                      silenciar(
                                    colaborador,
                                  ),
                          child:
                              const Text(
                            'Silenciar',
                          ),
                        ),
                ),

              if (widget
                      .podeSilenciar &&
                  widget
                      .podeExpulsar)
                const SizedBox(
                  width: 8,
                ),

              if (widget
                  .podeExpulsar)
                Expanded(
                  child:
                      FilledButton(
                    onPressed: processando
                        ? null
                        : () => expulsar(
                              colaborador,
                            ),
                    style:
                        FilledButton
                            .styleFrom(
                      backgroundColor:
                          Colors.red,
                    ),
                    child: const Text(
                      'Expulsar',
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
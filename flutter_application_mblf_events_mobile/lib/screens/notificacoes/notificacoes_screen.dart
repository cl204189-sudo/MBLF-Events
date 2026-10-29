import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../config/app_theme.dart';
import '../../models/notificacao.dart';
import '../hub/chat_screen.dart';
import '../../services/notificacao_service.dart';

class NotificacoesScreen
    extends StatefulWidget {
  final VoidCallback? onVoltar;

  const NotificacoesScreen({
    super.key,
    this.onVoltar,
  });

  @override
  State<NotificacoesScreen>
      createState() =>
          _NotificacoesScreenState();
}

class _NotificacoesScreenState
    extends State<NotificacoesScreen> with WidgetsBindingObserver {
  Timer? _timer;
  bool _buscando = false;
  bool _ativo = true;
  final NotificacaoService service =
      NotificacaoService();

  List<Notificacao> notificacoes = [];

  bool carregando = true;
  bool erroCarregamento = false;
  String filtro = 'Todas';

  List<Notificacao> get filtradas {
    final lista = notificacoes.where((n) {
      if (filtro == 'Não lidas') return !n.lida;
      if (filtro == 'Convites') return n.tipo.startsWith('CONVITE');
      if (filtro == 'Certificados') return n.tipo.contains('CERTIFICADO');
      if (filtro == 'Eventos') return n.tipo.contains('EVENTO') || n.tipo.contains('INSCRICAO');
      if (filtro == 'Chat geral') return n.tipo == 'CHAT_GERAL';
      if (filtro == 'Chat organização') return n.tipo == 'CHAT_ORGANIZACAO';
      return true;
    }).toList();
    lista.sort((a, b) {
      if (a.dataCriacao == null && b.dataCriacao == null) return b.id.compareTo(a.id);
      if (a.dataCriacao == null) return 1;
      if (b.dataCriacao == null) return -1;
      return b.dataCriacao!.compareTo(a.dataCriacao!);
    });
    return lista;
  }


  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);
    carregar();
    _timer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (_ativo) carregar(silencioso: true);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _ativo = state == AppLifecycleState.resumed;
    if (_ativo) carregar(silencioso: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> carregar({bool silencioso = false}) async {
    if (_buscando) return;
    _buscando = true;
    try {
      final lista =
          await service.listarMinhas();

      if (!mounted) return;

      setState(() {
        notificacoes = lista;
        carregando = false;
        erroCarregamento = false;
      });
    } catch (erro) {
      if (!mounted) return;

      setState(() {
        carregando = false;
        erroCarregamento = true;
      });

      if (!silencioso) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível carregar as notificações.')),
        );
      }
    } finally {
      _buscando = false;
    }
  }

  Future<void> marcarTodasLidas() async {
    final pendentes = notificacoes.where((n) => !n.lida).toList();
    int falhas = 0;
    for (final n in pendentes) {
      try { await service.marcarComoLida(n.id); }
      catch (_) { falhas++; }
    }
    await carregar();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(falhas == 0 ? 'Notificações marcadas como lidas.'
        : '$falhas notificação(ões) não atualizadas.'),
    ));
  }

      Future<void> abrirNotificacao(
      Notificacao notificacao,
    ) async {
      if (!notificacao.lida) {
        try {
          await service.marcarComoLida(
            notificacao.id,
          );
        } catch (_) {
          
        }
      }

      if (!mounted) return;

      if ((notificacao.tipo == 'CHAT_GERAL' ||
              notificacao.tipo == 'CHAT_ORGANIZACAO') &&
          notificacao.eventoId != null) {
        await Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ChatScreen(
            eventoId: notificacao.eventoId!,
            eventoTitulo: notificacao.titulo,
            canal: notificacao.tipo == 'CHAT_GERAL' ? 'GERAL' : 'ORGANIZACAO',
          ),
        ));
        if (mounted) await carregar();
        return;
      }

      if (notificacao.tipo ==
        'CONVITE_COLABORADOR' &&
        notificacao.eventoId != null) {

      try {
        final status =
            await service.statusConvite(
          notificacao.eventoId!,
        );

        if (!mounted) return;

        if (status == 'PENDENTE') {
          await _mostrarConvite(
            notificacao,
          );
        } else {
          await showDialog(
            context: context,
            builder: (_) {
              return AlertDialog(
                title: Text(
                  notificacao.titulo,
                ),
                content: Text(
                  notificacao.mensagem,
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Fechar',
                    ),
                  ),
                ],
              );
            },
          );
        }

    await carregar();
    return;

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

    return;
  }
}

      await showDialog(
        context: context,
        builder: (_) {
          return AlertDialog(
            title: Text(
              notificacao.titulo,
            ),
            content: Text(
              notificacao.mensagem,
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text(
                  'Fechar',
                ),
              ),
            ],
          );
        },
      );

      await carregar();
    }

      Future<void> _mostrarConvite(
      Notificacao notificacao,
    ) async {
      final resultado =
          await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            icon: const Icon(
              Icons.group_add_outlined,
              color: AppTheme.roxo,
              size: 48,
            ),

            title: Text(
              notificacao.titulo,
            ),

            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  notificacao.mensagem,
                  style: const TextStyle(
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 18),

                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.roxo
                        .withValues(
                      alpha: 0.06,
                    ),
                    borderRadius:
                        BorderRadius.circular(14),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppTheme.roxo,
                        size: 19,
                      ),

                      SizedBox(width: 8),

                      Expanded(
                        child: Text(
                          'Ao aceitar, este evento aparecerá na área Meus Eventos e HUB.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme
                                .textoSecundario,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(
                    context,
                    'RECUSAR',
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor:
                      Colors.red,
                ),
                child: const Text(
                  'Recusar',
                ),
              ),

              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(
                    context,
                    'ACEITAR',
                  );
                },
                icon: const Icon(
                  Icons.check,
                ),
                label: const Text(
                  'Aceitar',
                ),
              ),
            ],
          );
        },
      );

      if (resultado == null) {
        return;
      }

      try {
        if (resultado == 'ACEITAR') {
          await service.aceitarConvite(
            notificacao.eventoId!,
          );
        } else {
          await service.recusarConvite(
            notificacao.eventoId!,
          );
        }

        if (!mounted) return;

        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text(
              resultado == 'ACEITAR'
                  ? 'Convite aceito com sucesso!'
                  : 'Convite recusado.',
            ),
          ),
        );

        await carregar();
      } catch (erro) {
        if (!mounted) return;

        showDialog(
          context: context,
          builder: (_) {
            return AlertDialog(
              icon: const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 42,
              ),
              title: const Text(
                'Não foi possível responder',
              ),
              content: Text(
                erro
                    .toString()
                    .replaceFirst(
                      'Exception: ',
                      '',
                    ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Entendi',
                  ),
                ),
              ],
            );
          },
        );
      }
    }  

  Future<void> marcarLida(
    Notificacao notificacao,
  ) async {
    if (notificacao.lida) {
      return;
    }

    try {
      await service.marcarComoLida(
        notificacao.id,
      );

      await carregar();
    } catch (erro) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível atualizar a notificação.',
          ),
        ),
      );
    }
  }

  IconData iconePorTipo(
    String tipo,
  ) {
    switch (tipo) {
      case 'CONVITE_COLABORADOR':
        return Icons.group_add_outlined;

      case 'CONVITE_ACEITO':
        return Icons.check_circle_outline;

      case 'CONVITE_RECUSADO':
        return Icons.cancel_outlined;

      case 'CERTIFICADO_LIBERADO':
        return Icons.workspace_premium_outlined;

      case 'PAGAMENTO_APROVADO':
        return Icons.payments_outlined;

      case 'NOVA_TAREFA':
        return Icons.task_alt_outlined;

      case 'EVENTO_CANCELADO':
        return Icons.event_busy_outlined;

      default:
        return Icons.notifications_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final naoLidas = notificacoes.where((n) => !n.lida).length;
    final lista = filtradas;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Voltar',
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onVoltar ?? () => Navigator.maybePop(context),
        ),
        title: const Text('Notificações',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (naoLidas > 0)
            IconButton(
              tooltip: 'Marcar todas como lidas',
              icon: const Icon(Icons.done_all),
              onPressed: marcarTodasLidas,
            ),
          IconButton(
            tooltip: 'Atualizar notificações',
            onPressed: carregar,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                const Expanded(
                  child: Text('Suas atualizações',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                ),
                if (naoLidas > 0)
                  Text('$naoLidas não lida${naoLidas == 1 ? '' : 's'}',
                    style: const TextStyle(
                      fontSize: 12, color: AppTheme.roxo,
                      fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          SizedBox(
            height: 52,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              children: ['Todas', 'Não lidas', 'Convites', 'Certificados', 'Eventos', 'Chat geral', 'Chat organização'].map((opcao) {
                final selecionado = filtro == opcao;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(opcao),
                    selected: selecionado,
                    onSelected: (_) => setState(() => filtro = opcao),
                    selectedColor: AppTheme.roxo.withValues(alpha: .13),
                    side: BorderSide(color: selecionado
                        ? AppTheme.roxo : const Color(0xFFEBEDF2)),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: carregar,
              child: carregando
                  ? const Center(child: CircularProgressIndicator())
                  : erroCarregamento && notificacoes.isEmpty
                      ? ListView(children: [
                          const SizedBox(height: 90),
                          const Icon(Icons.wifi_off_outlined,
                            size: 52, color: AppTheme.textoSecundario),
                          const SizedBox(height: 14),
                          const Center(child: Text('Não foi possível carregar as notificações.')),
                          const SizedBox(height: 12),
                          Center(child: TextButton.icon(
                            onPressed: carregar,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Tentar novamente'))),
                        ])
                      : lista.isEmpty
                          ? ListView(children: [
                              const SizedBox(height: 90),
                              const Icon(Icons.notifications_none_outlined,
                                size: 56, color: AppTheme.textoSecundario),
                              const SizedBox(height: 12),
                              Center(child: Text(
                                filtro == 'Não lidas'
                                  ? 'Nenhuma notificação não lida.'
                                  : filtro == 'Convites'
                                    ? 'Nenhum convite por enquanto.'
                                    : 'Nenhuma notificação por enquanto.',
                                style: const TextStyle(
                                  color: AppTheme.textoSecundario))),
                            ])
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                              itemCount: lista.length,
                              itemBuilder: (context, index) => _card(lista[index]),
                            ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(
    Notificacao notificacao,
  ) {
    final data =
        notificacao.dataCriacao != null
            ? DateFormat(
                'dd/MM/yyyy • HH:mm',
              ).format(
                notificacao.dataCriacao!,
              )
            : '';

    return InkWell(
      borderRadius:
          BorderRadius.circular(16),
      onTap: () {
        abrirNotificacao(
          notificacao,
        );
      },
      child: Container(
        margin:
            const EdgeInsets.only(
          bottom: 9,
        ),
        padding:
            const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: notificacao.lida
              ? Theme.of(context).colorScheme.surface
              : Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.35),
          borderRadius:
              BorderRadius.circular(16),
          border: Border.all(
            color: notificacao.lida
                ? Theme.of(context).colorScheme.outlineVariant
                : Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: AppTheme
                    .gradientePrincipal,
                borderRadius:
                    BorderRadius.circular(
                  14,
                ),
              ),
              child: Icon(
                iconePorTipo(
                  notificacao.tipo,
                ),
                color: Colors.white,
              ),
            ),

            const SizedBox(
              width: 11,
            ),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notificacao.titulo,
                          style:
                              TextStyle(
                            fontWeight:
                                notificacao.lida
                                    ? FontWeight
                                        .w600
                                    : FontWeight
                                        .bold,
                            fontSize: 14,
                          ),
                        ),
                      ),

                      if (!notificacao.lida)
                        Container(
                          width: 9,
                          height: 9,
                          decoration:
                              const BoxDecoration(
                            color:
                                AppTheme.roxo,
                            shape:
                                BoxShape.circle,
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(
                    height: 7,
                  ),

                  Text(
                    notificacao.mensagem,
                    style: const TextStyle(
                      color: AppTheme
                          .textoSecundario,
                      height: 1.4,
                    ),
                  ),

                  if (data.isNotEmpty) ...[
                    const SizedBox(
                      height: 10,
                    ),
                    Text(
                      data,
                      style:
                          const TextStyle(
                        fontSize: 12,
                        color: AppTheme
                            .textoSecundario,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
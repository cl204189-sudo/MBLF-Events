import 'dart:async';
import 'package:flutter/material.dart';

import '../../config/app_theme.dart';
import '../../models/evento_colaborador.dart';
import '../../services/colaborador_hub_service.dart';

class ColaboradoresScreen
    extends StatefulWidget {
  final int eventoId;
  final String eventoTitulo;

  const ColaboradoresScreen({
    super.key,
    required this.eventoId,
    required this.eventoTitulo,
  });

  @override
  State<ColaboradoresScreen>
      createState() =>
          _ColaboradoresScreenState();
}

class _ColaboradoresScreenState
    extends State<ColaboradoresScreen> with WidgetsBindingObserver {
  Timer? _atualizacao;
  bool _consultando = false;
  bool _recarregarDepois = false;
  bool _ativo = true;

  final ColaboradorHubService service =
      ColaboradorHubService();

  List<EventoColaborador> colaboradores = [];

  bool carregando = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    carregar();
    _atualizacao = Timer.periodic(const Duration(seconds: 8), (_) {
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
    _atualizacao?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> carregar({bool silencioso = false}) async {
    if (_consultando) {
      // Não perder uma atualização solicitada enquanto outra está em andamento.
      _recarregarDepois = true;
      return;
    }
    _consultando = true;
    try {
      final lista =
          await service.listar(
        widget.eventoId,
      );

      if (!mounted) return;

      setState(() {
      colaboradores = lista
          .where(
            (colaborador) =>
                colaborador.status != 'RECUSADO' && colaborador.status != 'EXPULSO',
          )
          .toList();

      carregando = false;
    });
    } catch (erro) {
      if (!mounted) return;

      setState(() {
        carregando = false;
      });

      if (!silencioso) mostrarErro(erro);
    } finally {
      _consultando = false;
      if (_recarregarDepois && mounted) {
        _recarregarDepois = false;
        // Reexecuta a consulta depois que a atual terminar.
        carregar(silencioso: true);
      }
    }
  }

  Future<void> removerColaborador(EventoColaborador colaborador) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover colaborador?'),
        content: Text('Remover ${colaborador.usuarioNome} da equipe? O acesso ao HUB será revogado e o histórico será preservado.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Voltar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remover')),
        ],
      ),
    );
    if (confirmar != true) return;
    try {
      await service.remover(eventoId: widget.eventoId, usuarioId: colaborador.usuarioId);
      if (mounted) setState(() {
        colaboradores.removeWhere((c) => c.usuarioId == colaborador.usuarioId);
      });
      await carregar();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Colaborador removido da equipe.')),
      );
    } catch (e) { mostrarErro(e); }
  }

  void mostrarErro(Object erro) {
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

  Future<void> convidar() async {
    final emailController =
    TextEditingController();

    final funcaoController =
        TextEditingController();

    final resultado =
        await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            22,
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
                  'Convidar colaborador',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email do usuário',
                    hintText: 'usuario@email.com',
                    prefixIcon: Icon(
                      Icons.email_outlined,
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                TextField(
                  controller:
                      funcaoController,
                  decoration:
                      const InputDecoration(
                    labelText:
                        'Função no evento',
                    hintText:
                        'Ex: Coordenador',
                  ),
                ),

                const SizedBox(height: 22),

                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () async {
                      final email =
                      emailController.text.trim();

                      final funcao =
                          funcaoController
                              .text
                              .trim();

                      if (email.isEmpty ||
                            funcao.isEmpty) {
                          return;
                        }

                      try {
                        await service.convidar(
                          eventoId: widget.eventoId,
                          email: email,
                          funcao: funcao,
                        );

                        if (!context.mounted) {
                          return;
                        }

                        Navigator.pop(
                          context,
                          true,
                        );
                      } catch (erro) {
                        if (!context.mounted) {
                          return;
                        }

                        showDialog(
                          context: context,
                          builder: (_) {
                            return AlertDialog(
                              icon: const Icon(
                                Icons.error_outline,
                                color: Colors.red,
                                size: 45,
                              ),
                              title: const Text(
                                'Não foi possível convidar',
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
                    },
                    icon: const Icon(
                      Icons.person_add_alt_1,
                    ),
                    label: const Text(
                      'Enviar convite',
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    emailController.dispose();
    funcaoController.dispose();

    if (resultado == true && mounted) {
      await carregar();
    }
  }

  Future<void> editarPermissoes(
    EventoColaborador colaborador,
  ) async {
    bool podeChat =
        colaborador.podeChat;

    bool podeCalendario =
        colaborador.podeCalendario;

    bool podeTarefas =
        colaborador.podeTarefas;

    bool podeVerInscritos =
        colaborador.podeVerInscritos;

    bool podeRegistrarPresencas =
        colaborador
            .podeRegistrarPresencas;

    bool podeVerRelatorios =
        colaborador.podeVerRelatorios;

    bool podeSilenciar =
        colaborador.podeSilenciar;

    bool podeExpulsar =
        colaborador.podeExpulsar;

    bool podeLiberarCertificados =
        colaborador
            .podeLiberarCertificados;

    final salvou =
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
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(
                  20,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        colaborador.usuarioNome,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 5),

                      Text(
                        colaborador.funcao,
                        style: const TextStyle(
                          color: AppTheme
                              .textoSecundario,
                        ),
                      ),

                      const SizedBox(height: 22),

                      const Text(
                        'Permissões',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 10),

                      _switch(
                        'Chat',
                        podeChat,
                        (v) {
                          setModalState(() {
                            podeChat = v;
                          });
                        },
                      ),

                      _switch(
                        'Calendário',
                        podeCalendario,
                        (v) {
                          setModalState(() {
                            podeCalendario = v;
                          });
                        },
                      ),

                      _switch(
                        'Tarefas',
                        podeTarefas,
                        (v) {
                          setModalState(() {
                            podeTarefas = v;
                          });
                        },
                      ),

                      _switch(
                        'Ver inscritos',
                        podeVerInscritos,
                        (v) {
                          setModalState(() {
                            podeVerInscritos = v;
                          });
                        },
                      ),

                      _switch(
                        'Registrar presenças',
                        podeRegistrarPresencas,
                        (v) {
                          setModalState(() {
                            podeRegistrarPresencas =
                                v;
                          });
                        },
                      ),

                      _switch(
                        'Ver relatórios',
                        podeVerRelatorios,
                        (v) {
                          setModalState(() {
                            podeVerRelatorios =
                                v;
                          });
                        },
                      ),

                      _switch(
                        'Silenciar usuários',
                        podeSilenciar,
                        (v) {
                          setModalState(() {
                            podeSilenciar = v;
                          });
                        },
                      ),

                      _switch(
                        'Expulsar usuários',
                        podeExpulsar,
                        (v) {
                          setModalState(() {
                            podeExpulsar = v;
                          });
                        },
                      ),

                      _switch(
                        'Liberar certificados',
                        podeLiberarCertificados,
                        (v) {
                          setModalState(() {
                            podeLiberarCertificados =
                                v;
                          });
                        },
                      ),

                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        child:
                            FilledButton.icon(
                          onPressed: () async {
                            try {
                              await service
                                  .alterarPermissoes(
                                eventoId:
                                    widget
                                        .eventoId,
                                usuarioId:
                                    colaborador
                                        .usuarioId,
                                podeChat:
                                    podeChat,
                                podeCalendario:
                                    podeCalendario,
                                podeTarefas:
                                    podeTarefas,
                                podeVerInscritos:
                                    podeVerInscritos,
                                podeRegistrarPresencas:
                                    podeRegistrarPresencas,
                                podeVerRelatorios:
                                    podeVerRelatorios,
                                podeSilenciar:
                                    podeSilenciar,
                                podeExpulsar:
                                    podeExpulsar,
                                podeLiberarCertificados:
                                    podeLiberarCertificados,
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
                          icon: const Icon(
                            Icons.save_outlined,
                          ),
                          label: const Text(
                            'Salvar permissões',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (salvou == true) {
      await carregar();
    }
  }

  Widget _switch(
    String titulo,
    bool valor,
    ValueChanged<bool> onChanged,
  ) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(titulo),
      value: valor,
      onChanged: onChanged,
    );
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
              'Colaboradores',
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

      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: convidar,
        icon: const Icon(
          Icons.person_add_alt_1,
        ),
        label: const Text(
          'Convidar',
        ),
      ),

      body: RefreshIndicator(
        onRefresh: carregar,
        child: carregando
            ? const Center(
                child:
                    CircularProgressIndicator(),
              )
            : colaboradores.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 95),

                      Icon(
                        Icons.groups_outlined,
                        size: 70,
                        color: AppTheme
                            .textoSecundario,
                      ),

                      SizedBox(height: 15),

                      Center(
                        child: Text(
                          'Nenhum colaborador ainda. Use Convidar para adicionar alguém à equipe.',
                          style: TextStyle(
                            color: AppTheme
                                .textoSecundario,
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    padding:
                        const EdgeInsets.fromLTRB(
                      20,
                      15,
                      20,
                      100,
                    ),
                    itemCount:
                        colaboradores.length + 1,
                    itemBuilder:
                        (context, index) {
                      if (index == 0) {
                        final ativos = colaboradores.where((c) => c.status == 'ACEITO').length;
                        final convites = colaboradores.where((c) => c.status != 'ACEITO').length;
                        return Padding(padding: const EdgeInsets.only(bottom: 16), child: Row(children: [
                          Expanded(child: Card(child: ListTile(title: Text('$ativos'), subtitle: const Text('Ativos')))),
                          Expanded(child: Card(child: ListTile(title: Text('$convites'), subtitle: const Text('Convites pendentes')))),
                        ]));
                      }
                      return _card(colaboradores[index - 1]);
                    },
                  ),
      ),
    );
  }

  Widget _card(
    EventoColaborador colaborador,
  ) {
    Color corStatus;

    switch (colaborador.status) {
      case 'ACEITO':
        corStatus = AppTheme.verde;
        break;

      case 'RECUSADO':
        corStatus = Colors.red;
        break;

      default:
        corStatus = Colors.orange;
    }

    return Container(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      padding: const EdgeInsets.all(
        17,
      ),
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
                  style: const TextStyle(
                    color: AppTheme.roxo,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      colaborador
                          .usuarioNome,
                      style: const TextStyle(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      colaborador.funcao,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme
                            .textoSecundario,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color:
                      corStatus.withValues(
                    alpha: 0.10,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    100,
                  ),
                ),
                child: Text(
                  colaborador.status,
                  style: TextStyle(
                    color: corStatus,
                    fontSize: 10,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          if (colaborador.status ==
              'ACEITO') ...[
            const SizedBox(height: 14),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  editarPermissoes(
                    colaborador,
                  );
                },
                icon: const Icon(
                  Icons.tune_rounded,
                ),
                label: const Text(
                  'Gerenciar permissões',
                ),
              ),
            ),
          ],
          if (colaborador.status == 'ACEITO' || colaborador.status == 'PENDENTE') ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () => removerColaborador(colaborador),
                icon: const Icon(Icons.person_remove_outlined),
                label: const Text('Remover da equipe'),
              ),
            ),
          ],
          if (colaborador.status == 'PENDENTE') ...[
            const SizedBox(height: 14),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(
                  alpha: 0.08,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.schedule_outlined,
                    color: Colors.orange,
                    size: 19,
                  ),

                  SizedBox(width: 9),

                  Expanded(
                    child: Text(
                      'Aguardando resposta do usuário',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
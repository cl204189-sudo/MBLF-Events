import '../../widgets/eventos_por_periodo.dart';
import 'dart:async';
import 'package:flutter/material.dart';

import '../../config/app_theme.dart';
import '../../models/evento.dart';
import '../../widgets/evento_resumo.dart';
import '../../models/evento_colaborador.dart';
import '../../services/meus_eventos_service.dart';
import 'hub_screen.dart';
import 'criar_evento_screen.dart';
import 'gerenciar_evento_screen.dart';

class MeusEventosScreen
    extends StatefulWidget {

  const MeusEventosScreen({
    super.key,
  });

  @override
  State<MeusEventosScreen>
      createState() =>
          _MeusEventosScreenState();
}

class _MeusEventosScreenState
    extends State<MeusEventosScreen> with WidgetsBindingObserver {

  final MeusEventosService service =
      MeusEventosService();

  List<Evento> organizados = [];
  List<EventoColaborador> colaboracoes = [];

  bool carregando = true;
  bool _emPrimeiroPlano = true;
  bool _atualizando = false;
  Timer? _atualizacaoTimer;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _emPrimeiroPlano = state == AppLifecycleState.resumed;
    if (_emPrimeiroPlano && mounted) carregar(silencioso: true);
  }

  @override
  void dispose() {
    _atualizacaoTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _atualizacaoTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (_emPrimeiroPlano && mounted && !_atualizando) {
        carregar(silencioso: true);
      }
    });
    carregar();
  }

  Future<void> carregar({bool silencioso = false}) async {
    if (_atualizando) return;
    _atualizando = true;
    try {
      final eventos =
          await service
              .listarEventosOrganizados();

      final colaboradores =
          await service
              .listarColaboracoes();

      if (!mounted) return;

      setState(() {
        organizados = eventos;
        colaboracoes = colaboradores;
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
    } finally {
      _atualizando = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Meus eventos',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final criado = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => const CriarEventoScreen(),
            ),
          );

          if (criado == true) {
            await carregar();
          }
        },
        icon: const Icon(
          Icons.add,
        ),
        label: const Text(
          'Criar evento',
        ),
      ),

      body: RefreshIndicator(
        onRefresh: carregar,

        child: carregando
            ? const Center(
                child:
                    CircularProgressIndicator(),
              )

            : ListView(
                padding:
                    const EdgeInsets.fromLTRB(
                  20,
                  10,
                  20,
                  30,
                ),
                children: [
                  const Text(
                    'Organizo',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  if (organizados.isEmpty)
                    _vazio(
                      'Você ainda não organiza nenhum evento.',
                    )
                  else
                    EventosPorPeriodo<Evento>(itens: organizados, inicio: (e) => e.dataInicio, fim: (e) => e.dataFim, construir: _cardOrganizador),

                  const SizedBox(
                    height: 30,
                  ),

                  const Text(
                    'Colaborações',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  if (colaboracoes.isEmpty)
                    _vazio(
                      'Você ainda não participa de nenhum HUB.',
                    )
                  else
                    ...colaboracoes.map(
                      _cardColaborador,
                    ),
                ],
              ),
      ),
    );
  }

  Widget _cardOrganizador(
    Evento evento,
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
              Container(
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration:
                    BoxDecoration(
                  color: AppTheme.roxo
                      .withValues(
                        alpha: 0.10,
                      ),
                  borderRadius:
                      BorderRadius.circular(
                    100,
                  ),
                ),
                child: const Text(
                  'ORGANIZADOR',
                  style: TextStyle(
                    color:
                        AppTheme.roxo,
                    fontSize: 11,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 13,
          ),

          Text(
            evento.titulo,
            style:
                const TextStyle(
              fontSize: 18,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 6,
          ),

          EventoResumo(evento: evento),

          const SizedBox(
            height: 16,
          ),

          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GerenciarEventoScreen(evento: evento),
                  ),
                );
                if (mounted) await carregar();
              },
              icon: const Icon(Icons.dashboard_outlined),
              label: const Text('Gerenciar'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardColaborador(
    EventoColaborador colaborador,
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
              Container(
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),

                decoration:
                    BoxDecoration(
                  color: AppTheme.verde
                      .withValues(
                        alpha: 0.10,
                      ),

                  borderRadius:
                      BorderRadius.circular(
                    100,
                  ),
                ),

                child: const Text(
                  'COLABORADOR',

                  style: TextStyle(
                    color:
                        AppTheme.verde,
                    fontSize: 11,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),

              const Spacer(),

              Text(
                colaborador.funcao,

                style:
                    const TextStyle(
                  color: AppTheme
                      .textoSecundario,
                  fontSize: 12,
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 13,
          ),

          Text(
            colaborador.eventoTitulo,

            style:
                const TextStyle(
              fontSize: 18,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 16,
          ),

          SizedBox(
            width: double.infinity,

            child:
                FilledButton.icon(
              onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HubScreen(
                          eventoId: colaborador.eventoId,
                          eventoTitulo: colaborador.eventoTitulo,
                          organizador: false,
                          colaborador: colaborador,
                        ),
                      ),
                    );

                    if (!mounted) return;

                    await carregar();
                  },
              icon: const Icon(
                Icons.groups_outlined,
              ),
              label: const Text(
                'Entrar no HUB',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _vazio(
    String texto,
  ) {
    return Container(
      width: double.infinity,

      padding:
          const EdgeInsets.all(24),

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

      child: Text(
        texto,

        textAlign:
            TextAlign.center,

        style:
            const TextStyle(
          color: AppTheme
              .textoSecundario,
        ),
      ),
    );
  }
}
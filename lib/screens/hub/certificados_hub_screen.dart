import 'dart:async';
import 'package:flutter/material.dart';

import '../../config/app_theme.dart';
import '../../models/certificado.dart';
import '../../services/certificado_hub_service.dart';
import '../../services/inscricao_evento_service.dart';
import '../../models/inscricao.dart';

class CertificadosHubScreen
    extends StatefulWidget {
  final int eventoId;
  final String eventoTitulo;

  const CertificadosHubScreen({
    super.key,
    required this.eventoId,
    required this.eventoTitulo,
  });

  @override
  State<CertificadosHubScreen>
      createState() =>
          _CertificadosHubScreenState();
}

class _CertificadosHubScreenState
    extends State<CertificadosHubScreen> with WidgetsBindingObserver {
  final CertificadoHubService service =
      CertificadoHubService();

  List<Certificado> certificados = [];
  List<Inscricao> inscritos = [];
  bool gerando = false;
  String filtroCertificado = 'Todos';
  String buscaCertificado = '';


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
      final resultados = await Future.wait<dynamic>([
        service.listarPorEvento(widget.eventoId),
        InscricaoEventoService().listarPorEvento(widget.eventoId),
      ]);
      final lista = resultados[0] as List<Certificado>;
      final listaInscritos = resultados[1] as List<Inscricao>;

      if (!mounted) return;

      setState(() {
        certificados = lista;
        inscritos = listaInscritos;
        carregando = false;
      });
    } catch (erro) {
      if (!mounted) return;

      setState(() {
        carregando = false;
      });

      if (!silencioso) mostrarErro(erro);
    }
    finally {
      _syncEmAndamento = false;
      if (_syncPendente && mounted) {
        _syncPendente = false;
        carregar(silencioso: true);
      }
    }
  }

  Future<void> gerar(Inscricao inscricao) async {
    if (gerando) return;
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Gerar certificado?'),
        content: Text('Gerar certificado pendente para ${inscricao.usuarioNome}? '
            'Depois será necessário liberá-lo.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Gerar')),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;
    setState(() => gerando = true);
    try {
      await service.gerar(inscricao.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Certificado gerado. Agora você pode liberá-lo.')),
      );
      await carregar();
    } catch (e) {
      mostrarErro(e);
    } finally {
      if (mounted) setState(() => gerando = false);
    }
  }

  Future<void> liberar(
    Certificado certificado,
  ) async {
    final confirmar =
        await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text(
            'Liberar certificado?',
          ),
          content: Text(
            'Liberar definitivamente o certificado de ${certificado.nomeParticipante}?',
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
                'Cancelar',
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
                'Liberar',
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
      await service.liberar(
        certificado.id,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Certificado liberado com sucesso.',
          ),
        ),
      );

      await carregar();
    } catch (erro) {
      mostrarErro(erro);
    }
  }

  void mostrarErro(
    Object erro,
  ) {
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

  @override
  Widget build(BuildContext context) {
    final pendentes = certificados
        .where(
          (certificado) =>
              certificado.status !=
              'LIBERADO',
        )
        .length;

    final elegiveis = inscritos.where((i) =>
        i.status == 'PRESENTE' &&
        !certificados.any((c) => c.inscricaoId == i.id)).toList();

    final liberados = certificados
        .where(
          (certificado) =>
              certificado.status ==
              'LIBERADO',
        )
        .length;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'Certificados',
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
                  15,
                  20,
                  30,
                ),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _resumo(
                          'Pendentes',
                          '$pendentes',
                          Icons
                              .hourglass_empty_rounded,
                          Colors.orange,
                        ),
                      ),

                      const SizedBox(
                        width: 12,
                      ),

                      Expanded(
                        child: _resumo(
                          'Liberados',
                          '$liberados',
                          Icons
                              .verified_outlined,
                          AppTheme.verde,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 26,
                  ),

                  const Text(
                    'Certificados do evento',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  if (elegiveis.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text('Presenças confirmadas sem certificado',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    ...elegiveis.map((inscricao) => Card(
                      child: ListTile(
                        title: Text(inscricao.usuarioNome),
                        subtitle: Text('Inscrição #${inscricao.id}'),
                        trailing: FilledButton.tonal(
                          onPressed: gerando ? null : () => gerar(inscricao),
                          child: const Text('Gerar'),
                        ),
                      ),
                    )),
                    const SizedBox(height: 18),
                  ],
                  if (certificados.isNotEmpty) ...[
                    TextField(
                      onChanged: (v) => setState(() => buscaCertificado = v.trim().toLowerCase()),
                      decoration: const InputDecoration(
                        hintText: 'Pesquisar participante ou código',
                        prefixIcon: Icon(Icons.search), border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(
                      children: ['Todos', 'Pendentes', 'Liberados'].map((f) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(label: Text(f), selected: filtroCertificado == f,
                          onSelected: (_) => setState(() => filtroCertificado = f)),
                      )).toList(),
                    )),
                    const SizedBox(height: 10),
                  ],
                  if (certificados.isEmpty && elegiveis.isEmpty)
                    _estadoVazio(),
                  ...(() {
                    final lista = certificados.where((c) {
                      if (filtroCertificado == 'Liberados' && c.status != 'LIBERADO') return false;
                      if (filtroCertificado == 'Pendentes' && c.status == 'LIBERADO') return false;
                      return c.nomeParticipante.toLowerCase().contains(buscaCertificado) ||
                        c.codigo.toLowerCase().contains(buscaCertificado);
                    }).toList();
                    if (certificados.isNotEmpty && lista.isEmpty) return <Widget>[
                      const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('Nenhum certificado corresponde ao filtro.'))),
                    ];
                    return lista.map(_cardCertificado).toList();
                  })(),
                ],
              ),
      ),
    );
  }

  Widget _resumo(
    String titulo,
    String valor,
    IconData icone,
    Color cor,
  ) {
    return Container(
      padding:
          const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icone,
            color: cor,
            size: 27,
          ),

          const SizedBox(height: 8),

          Text(
            valor,
            style: const TextStyle(
              fontSize: 24,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          Text(
            titulo,
            style: const TextStyle(
              fontSize: 12,
              color:
                  AppTheme.textoSecundario,
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardCertificado(
    Certificado certificado,
  ) {
    final liberado =
        certificado.status ==
            'LIBERADO';

    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),
      padding:
          const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius:
            BorderRadius.circular(20),
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
              CircleAvatar(
                backgroundColor:
                    AppTheme.roxo
                        .withValues(
                  alpha: 0.10,
                ),
                child: const Icon(
                  Icons
                      .workspace_premium_outlined,
                  color:
                      AppTheme.roxo,
                ),
              ),

              const SizedBox(
                width: 12,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      certificado
                          .nomeParticipante,
                      style:
                          const TextStyle(
                        fontWeight:
                            FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),

                    const SizedBox(
                      height: 3,
                    ),

                    Text(
                      'Inscrição #${certificado.inscricaoId}',
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

              Container(
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),
                decoration:
                    BoxDecoration(
                  color: liberado
                      ? AppTheme.verde
                          .withValues(
                            alpha: 0.10,
                          )
                      : Colors.orange
                          .withValues(
                            alpha: 0.10,
                          ),
                  borderRadius:
                      BorderRadius.circular(
                    100,
                  ),
                ),
                child: Text(
                  liberado
                      ? 'LIBERADO'
                      : 'PENDENTE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight:
                        FontWeight.bold,
                    color: liberado
                        ? AppTheme.verde
                        : Colors.orange,
                  ),
                ),
              ),
            ],
          ),

          if (!liberado) ...[
            const SizedBox(
              height: 15,
            ),

            SizedBox(
              width:
                  double.infinity,
              child:
                  FilledButton.icon(
                onPressed: () {
                  liberar(
                    certificado,
                  );
                },
                icon: const Icon(
                  Icons
                      .lock_open_outlined,
                ),
                label: const Text(
                  'Liberar certificado',
                ),
              ),
            ),
          ],

          if (liberado) ...[
            const SizedBox(
              height: 13,
            ),

            Row(
              children: [
                const Icon(
                  Icons
                      .check_circle_outline,
                  color:
                      AppTheme.verde,
                  size: 18,
                ),

                const SizedBox(
                  width: 7,
                ),

                Expanded(
                  child: Text(
                    certificado
                                .liberadoPorNome !=
                            null
                        ? 'Liberado por ${certificado.liberadoPorNome}'
                        : 'Certificado liberado',
                    style:
                        const TextStyle(
                      fontSize: 12,
                      color: AppTheme
                          .textoSecundario,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _estadoVazio() {
    return Container(
      padding:
          const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius:
            BorderRadius.circular(22),
      ),
      child: const Column(
        children: [
          Icon(
            Icons
                .workspace_premium_outlined,
            size: 55,
            color:
                AppTheme.textoSecundario,
          ),

          SizedBox(height: 14),

          Text(
            'Nenhum certificado encontrado.',
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
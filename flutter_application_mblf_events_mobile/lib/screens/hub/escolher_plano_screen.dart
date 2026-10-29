import 'package:flutter/material.dart';

import '../../config/app_theme.dart';
import '../../models/plano.dart';
import '../../services/plano_service.dart';

class EscolherPlanoScreen
    extends StatefulWidget {
  final int eventoId;

  // HUB ou PUBLICACAO
  final String tipo;

  const EscolherPlanoScreen({
    super.key,
    required this.eventoId,
    required this.tipo,
  });

  @override
  State<EscolherPlanoScreen>
      createState() =>
          _EscolherPlanoScreenState();
}

class _EscolherPlanoScreenState
    extends State<EscolherPlanoScreen> {
  final PlanoService service =
      PlanoService();

  List<Plano> planos = [];

  bool carregando = true;
  int? planoProcessando;
  int? planoSelecionado;

  @override
  void initState() {
    super.initState();

    carregar();
  }

  Future<void> carregar() async {
    try {
      final lista =
          await service.listarAtivos();

      final filtrados =
          lista.where((plano) {
        return plano.tipo.toUpperCase() ==
            widget.tipo.toUpperCase();
      }).toList();

      if (!mounted) return;

      setState(() {
        planos = filtrados..sort((a, b) => a.duracaoDias.compareTo(b.duracaoDias));
        planoSelecionado = planos.isEmpty ? null : planos.first.id;
        carregando = false;
      });
    } catch (erro) {
      if (!mounted) return;

      setState(() {
        carregando = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível carregar os planos.',
          ),
        ),
      );
    }
  }

  Future<void> comprar(
    Plano plano,
  ) async {
    final confirmar =
        await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          icon: Icon(
            widget.tipo == 'HUB'
                ? Icons
                    .dashboard_customize_outlined
                : Icons.public_outlined,
            color: AppTheme.roxo,
            size: 45,
          ),
          title: Text(
            plano.nome,
          ),
          content: Text(
            'Deseja contratar este plano por R\$ ${plano.valor.toStringAsFixed(2)}?',
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
                'Confirmar',
              ),
            ),
          ],
        );
      },
    );

    if (confirmar != true) {
      return;
    }

    setState(() {
      planoProcessando = plano.id;
    });

    try {
      await service.simularPagamento(
        eventoId: widget.eventoId,
        planoId: plano.id,
      );

      if (!mounted) return;

      await showDialog(
        context: context,
        builder: (_) {
          return AlertDialog(
            icon: const Icon(
              Icons.check_circle,
              color: AppTheme.verde,
              size: 50,
            ),
            title: const Text(
              'Pagamento aprovado!',
            ),
            content: Text(
              widget.tipo == 'HUB'
                  ? 'O MBLF HUB foi ativado para este evento.'
                  : 'A publicação do evento foi ativada.',
            ),
            actions: [
              FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text(
                  'Continuar',
                ),
              ),
            ],
          );
        },
      );

      if (!mounted) return;

      Navigator.pop(
        context,
        true,
      );
    } catch (erro) {
      if (!mounted) return;

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
              'Não foi possível concluir',
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
    } finally {
      if (mounted) {
        setState(() {
          planoProcessando = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hub = widget.tipo.toUpperCase() == 'HUB';
    final cores = Theme.of(context).colorScheme;
    Plano? selecionado;
    for (final plano in planos) {
      if (plano.id == planoSelecionado) selecionado = plano;
    }
    final escolhido = selecionado;
    return Scaffold(
      appBar: AppBar(title: Text(hub ? 'Planos do HUB' : 'Planos de publicação')),
      body: carregando
        ? const Center(child: CircularProgressIndicator())
        : planos.isEmpty
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('Nenhum plano disponível.'),
              TextButton(onPressed: carregar, child: const Text('Tentar novamente')),
            ]))
          : Column(children: [
              Expanded(child: ListView(padding: const EdgeInsets.all(16), children: [
                Text('Escolha seu plano', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 6),
                Text(hub ? 'Escolha por quanto tempo as ferramentas do HUB ficarão disponíveis.'
                    : 'Escolha por quanto tempo o evento ficará publicado no Explorar.',
                  style: TextStyle(color: cores.onSurfaceVariant)),
                const SizedBox(height: 18),
                ...planos.map((plano) {
                  final selecionado = plano.id == planoSelecionado;
                  final precoDia = plano.duracaoDias > 0
                    ? plano.valor / plano.duracaoDias : 0.0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: planoProcessando == null ? () => setState(() => planoSelecionado = plano.id) : null,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cores.surface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: selecionado ? cores.primary : cores.outlineVariant,
                            width: selecionado ? 2 : 1),
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Icon(selecionado ? Icons.radio_button_checked : Icons.radio_button_off,
                              color: selecionado ? cores.primary : cores.onSurfaceVariant),
                            const SizedBox(width: 10),
                            Expanded(child: Text(plano.nome, style: const TextStyle(fontWeight: FontWeight.bold))),
                          ]),
                          const SizedBox(height: 10),
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            Text('${plano.duracaoDias} dias'),
                            Text('R\$ ${plano.valor.toStringAsFixed(2).replaceAll('.', ',')}',
                              style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold, color: cores.primary)),
                          ]),
                          Text('R\$ ${precoDia.toStringAsFixed(2).replaceAll('.', ',')} por dia',
                            style: TextStyle(fontSize: 12, color: cores.onSurfaceVariant)),
                        ]),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 8),
                Card(child: Padding(padding: const EdgeInsets.all(14), child: Row(children: [
                  const Icon(Icons.info_outline), const SizedBox(width: 10),
                  Expanded(child: Text(hub
                    ? 'Este plano ativa ou renova o HUB, não a publicação do evento.'
                    : 'Este plano ativa ou renova a publicação, não o HUB.',
                    style: const TextStyle(fontSize: 12))),
                ]))),
              ])),
              SafeArea(top: false, child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  if (escolhido != null) Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('Plano de ${escolhido.duracaoDias} dias'),
                    Text('R\$ ${escolhido.valor.toStringAsFixed(2).replaceAll('.', ',')}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  ]),
                  const SizedBox(height: 10),
                  SizedBox(width: double.infinity, child: FilledButton(
                    onPressed: escolhido == null || planoProcessando != null ? null : () => comprar(escolhido),
                    child: planoProcessando != null
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Continuar com o plano selecionado'),
                  )),
                ]),
              )),
            ]),
    );
  }
}

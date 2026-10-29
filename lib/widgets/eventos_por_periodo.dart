import 'package:flutter/material.dart';

/// Classificação temporal independente do status administrativo.
enum PeriodoEvento { andamento, proximos, encerrados, semData }

PeriodoEvento periodoEvento(DateTime? inicio, DateTime? fim, {DateTime? agora}) {
  if (inicio == null || fim == null || fim.isBefore(inicio)) return PeriodoEvento.semData;
  final atual = agora ?? DateTime.now();
  if (atual.isBefore(inicio)) return PeriodoEvento.proximos;
  if (atual.isAfter(fim)) return PeriodoEvento.encerrados;
  return PeriodoEvento.andamento;
}

/// Lista reutilizável com seleção de período e contagem por categoria.
/// A classificação temporal não altera o status administrativo do evento.
class EventosPorPeriodo<T> extends StatefulWidget {
  final List<T> itens;
  final DateTime? Function(T) inicio;
  final DateTime? Function(T) fim;
  final Widget Function(T) construir;
  final String vazio;

  const EventosPorPeriodo({super.key, required this.itens, required this.inicio,
    required this.fim, required this.construir, this.vazio = 'Nenhum evento nesta categoria.'});

  @override
  State<EventosPorPeriodo<T>> createState() => _EventosPorPeriodoState<T>();
}

class _EventosPorPeriodoState<T> extends State<EventosPorPeriodo<T>> {
  PeriodoEvento? selecionado; // null = todas as categorias

  @override
  Widget build(BuildContext context) {
    final grupos = <PeriodoEvento, List<T>>{
      for (final p in PeriodoEvento.values) p: <T>[],
    };
    for (final item in widget.itens) {
      grupos[periodoEvento(widget.inicio(item), widget.fim(item))]!.add(item);
    }
    for (final grupo in grupos.entries) {
      grupo.value.sort((a, b) {
        final da = widget.inicio(a) ?? DateTime.fromMillisecondsSinceEpoch(0);
        final db = widget.inicio(b) ?? DateTime.fromMillisecondsSinceEpoch(0);
        return grupo.key == PeriodoEvento.proximos ? da.compareTo(db) : db.compareTo(da);
      });
    }
    const nomes = {
      PeriodoEvento.andamento: 'Em andamento',
      PeriodoEvento.proximos: 'Próximos',
      PeriodoEvento.encerrados: 'Encerrados',
      PeriodoEvento.semData: 'Data não disponível',
    };
    final periodos = PeriodoEvento.values.where((p) => grupos[p]!.isNotEmpty).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (widget.itens.isNotEmpty) ...[
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(
              label: Text('Todos (${widget.itens.length})'),
              selected: selecionado == null,
              onSelected: (_) => setState(() => selecionado = null),
            )),
            for (final p in periodos)
              Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(
                label: Text('${nomes[p]} (${grupos[p]!.length})'),
                selected: selecionado == p,
                onSelected: (_) => setState(() => selecionado = p),
              )),
          ]),
        ),
      ],
      for (final p in PeriodoEvento.values)
        if (grupos[p]!.isNotEmpty && (selecionado == null || selecionado == p)) ...[
          Padding(padding: const EdgeInsets.only(top: 18, bottom: 10),
            child: Row(children: [
              Expanded(child: Text(nomes[p]!, style: Theme.of(context).textTheme.titleMedium)),
              Text('${grupos[p]!.length}', style: Theme.of(context).textTheme.labelLarge),
            ])),
          ...grupos[p]!.map(widget.construir),
        ],
      if (widget.itens.isEmpty)
        Padding(padding: const EdgeInsets.all(20), child: Text(widget.vazio)),
    ]);
  }
}

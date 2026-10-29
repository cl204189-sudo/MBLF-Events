import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../config/app_theme.dart';
import '../models/evento.dart';
import '../config/api_config.dart';

/// Informações curtas e compartilhadas pelos cards da Home e Meus Eventos.
class EventoResumo extends StatelessWidget {
  final Evento evento;
  const EventoResumo({super.key, required this.evento});

  @override
  Widget build(BuildContext context) {
    final inicio = evento.dataInicio.toLocal();
    final fim = evento.dataFim.toLocal();
    final encerrado = !fim.isAfter(DateTime.now());
    final status = encerrado ? 'Encerrado' :
      evento.inscricoesAbertas ? 'Inscrições abertas' : 'Inscrições fechadas';
    final cor = encerrado ? const Color(0xFF888B98) :
      evento.inscricoesAbertas ? AppTheme.verde : AppTheme.roxo;
    final local = [evento.cidade.trim(), evento.endereco.trim()]
      .where((parte) => parte.isNotEmpty).join(' • ');
    final secundario = Theme.of(context).colorScheme.onSurfaceVariant;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (evento.imagemUrl != null) ...[
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            '${ApiConfig.baseUrl}${evento.imagemUrl}',
            width: double.infinity, height: 140, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        ),
        const SizedBox(height: 10),
      ],
      if (evento.tipo.trim().isNotEmpty) ...[
        Text(evento.tipo, maxLines: 1, overflow: TextOverflow.ellipsis,
          style: TextStyle(color: secundario, fontSize: 11)),
        const SizedBox(height: 5),
      ],
      _linha(Icons.calendar_today_outlined,
        '${DateFormat('dd/MM/yyyy').format(inicio)} • ${DateFormat('HH:mm').format(inicio)}–${DateFormat('HH:mm').format(fim)}', secundario),
      if (local.isNotEmpty) ...[
        const SizedBox(height: 5),
        _linha(Icons.place_outlined, local, secundario),
      ],
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 5, crossAxisAlignment: WrapCrossAlignment.center, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: cor.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(20)),
          child: Text(status, style: TextStyle(fontSize: 10,
            fontWeight: FontWeight.w700, color: cor)),
        ),
        if (evento.vagasDisponiveis != null)
          Text('${evento.vagasDisponiveis} vagas disponíveis',
            style: TextStyle(fontSize: 11, color: secundario)),
      ]),
    ]);
  }

  Widget _linha(IconData icone, String valor, Color cor) => Row(children: [
    Icon(icone, size: 13, color: cor),
    const SizedBox(width: 5),
    Expanded(child: Text(valor, maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(fontSize: 12, color: cor))),
  ]);
}

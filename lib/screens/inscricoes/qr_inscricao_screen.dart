import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../config/app_theme.dart';
import '../../models/inscricao.dart';
import '../../models/evento.dart';

/// Ingresso digital: reutiliza o token QR emitido pela API.
class QrInscricaoScreen extends StatelessWidget {
  final Inscricao inscricao;
  final Evento? evento;

  const QrInscricaoScreen({
    super.key,
    required this.inscricao,
    this.evento,
  });

  Widget _detalhe(IconData icone, String titulo, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, size: 19, color: AppTheme.roxo),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: const TextStyle(
                  color: AppTheme.textoSecundario, fontSize: 12)),
                const SizedBox(height: 3),
                Text(valor, style: const TextStyle(
                  fontWeight: FontWeight.w600, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cancelado = inscricao.status.toUpperCase() == 'CANCELADO';
    final presente = inscricao.status.toUpperCase() == 'PRESENTE';
    final qrDisponivel = !cancelado && inscricao.tokenQr.trim().isNotEmpty;
    final inicio = evento?.dataInicio.toLocal();
    final fim = evento?.dataFim.toLocal();

    return Scaffold(
      appBar: AppBar(title: const Text('Ingresso digital')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFEBEDF2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      gradient: AppTheme.gradientePrincipal,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(children: [
                          Icon(Icons.confirmation_number_outlined,
                              color: Colors.white),
                          SizedBox(width: 8),
                          Text('INGRESSO MBLF', style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1)),
                        ]),
                        const SizedBox(height: 18),
                        Text(inscricao.eventoTitulo,
                            style: const TextStyle(
                              color: Colors.white, fontSize: 23,
                              fontWeight: FontWeight.bold)),
                        const SizedBox(height: 9),
                        Text(
                          cancelado ? 'Inscrição cancelada' :
                          presente ? 'Presença registrada' : 'Inscrição confirmada',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _detalhe(Icons.person_outline, 'Participante',
                            inscricao.usuarioNome.isEmpty
                              ? 'Não informado' : inscricao.usuarioNome),
                        if (inicio != null)
                          _detalhe(Icons.event_outlined, 'Data e horário',
                              '${DateFormat('dd/MM/yyyy • HH:mm').format(inicio)}'
                              '${fim == null ? '' : ' até ${DateFormat('dd/MM/yyyy • HH:mm').format(fim)}'}'),
                        if (evento != null && evento!.cidade.trim().isNotEmpty)
                          _detalhe(Icons.location_city_outlined, 'Cidade',
                              evento!.cidade),
                        if (evento != null && evento!.endereco.trim().isNotEmpty)
                          _detalhe(Icons.place_outlined, 'Endereço',
                              evento!.endereco),
                        if (evento != null && evento!.tipo.trim().isNotEmpty)
                          _detalhe(Icons.category_outlined, 'Tipo de evento',
                              evento!.tipo),
                        _detalhe(Icons.tag_outlined, 'Inscrição',
                            '#${inscricao.id}'),
                        if (inscricao.dataInscricao != null)
                          _detalhe(Icons.how_to_reg_outlined, 'Inscrito em',
                              DateFormat('dd/MM/yyyy').format(
                                  inscricao.dataInscricao!.toLocal())),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Divider(color: Colors.grey.shade300),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        if (qrDisponivel) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: const Color(0xFFEBEDF2)),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: QrImageView(
                              data: inscricao.tokenQr,
                              version: QrVersions.auto,
                              size: 210,
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Text('Apresente este QR Code no check-in.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppTheme.textoSecundario)),
                        ] else ...[
                          const Icon(Icons.qr_code_2_outlined,
                              size: 56, color: AppTheme.textoSecundario),
                          const SizedBox(height: 10),
                          Text(cancelado
                            ? 'Ingresso cancelado. QR Code indisponível.'
                            : 'QR Code ainda não disponível para esta inscrição.',
                            textAlign: TextAlign.center),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Este ingresso é pessoal. A validação ocorre no check-in do evento.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textoSecundario, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

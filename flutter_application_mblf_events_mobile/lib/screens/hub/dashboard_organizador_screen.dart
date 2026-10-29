import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:convert';
import 'dart:typed_data';

import '../../models/inscricao.dart';
import '../../models/certificado.dart';
import '../../services/inscricao_evento_service.dart';
import '../../services/certificado_hub_service.dart';

class DashboardOrganizadorScreen extends StatefulWidget {
  final int eventoId;
  final String eventoTitulo;

  const DashboardOrganizadorScreen({
    super.key,
    required this.eventoId,
    required this.eventoTitulo,
  });

  @override
  State<DashboardOrganizadorScreen> createState() =>
      _DashboardOrganizadorScreenState();
}

class _DashboardOrganizadorScreenState extends State<DashboardOrganizadorScreen> {
  bool carregando = true;
  String? erro;
  List<Inscricao> inscricoes = [];
  List<Certificado> certificados = [];
  String filtro = 'Todos';
  bool exportando = false;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    if (!mounted) return;
    setState(() {
      carregando = true;
      erro = null;
    });
    try {
      final resultados = await Future.wait<dynamic>([
        InscricaoEventoService().listarPorEvento(widget.eventoId),
        CertificadoHubService().listarPorEvento(widget.eventoId),
      ]);
      if (!mounted) return;
      setState(() {
        inscricoes = resultados[0] as List<Inscricao>;
        certificados = resultados[1] as List<Certificado>;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => erro = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => carregando = false);
    }
  }

  bool _cancelada(Inscricao i) =>
      i.status.toUpperCase() == 'CANCELADO' ||
      i.status.toUpperCase() == 'CANCELADA';

  bool _presente(Inscricao i) => i.status.toUpperCase() == 'PRESENTE';

  List<Inscricao> _participantesFiltrados() {
    return inscricoes.where((i) {
      if (filtro == 'Presentes') return !_cancelada(i) && _presente(i);
      if (filtro == 'Pendentes') return !_cancelada(i) && !_presente(i);
      if (filtro == 'Cancelados') return _cancelada(i);
      return true;
    }).toList()
      ..sort((a, b) => a.usuarioNome.toLowerCase().compareTo(b.usuarioNome.toLowerCase()));
  }

  String _campoCsv(String valor) {
    // Evita interpretar conteúdo vindo da API como fórmula no Excel.
    final seguro = RegExp(r'^[\s]*[=+@-]').hasMatch(valor) ? "'$valor" : valor;
    return '"${seguro.replaceAll('"', '""')}"';
  }

  Future<void> _exportarCsv() async {
    if (carregando || erro != null || exportando) return;
    setState(() => exportando = true);
    try {
      final linhas = <List<String>>[
        ['Inscricao ID', 'Participante', 'Usuario ID', 'Status', 'Data de inscricao'],
        for (final i in _participantesFiltrados())
          [
            '${i.id}', i.usuarioNome, '${i.usuarioId}', _rotuloStatus(i),
            i.dataInscricao == null ? '' : DateFormat('dd/MM/yyyy HH:mm').format(i.dataInscricao!),
          ],
      ];
      final csv = '\uFEFF${linhas.map((linha) => linha.map(_campoCsv).join(';')).join('\r\n')}';
      final nome = 'participantes_evento_${widget.eventoId}_${filtro.toLowerCase()}.csv';
      await SharePlus.instance.share(ShareParams(
        files: [XFile.fromData(Uint8List.fromList(utf8.encode(csv)), mimeType: 'text/csv')],
        fileNameOverrides: [nome],
        subject: 'Participantes - ${widget.eventoTitulo}',
      ));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao exportar CSV: $e')),
      );
    } finally {
      if (mounted) setState(() => exportando = false);
    }
  }

  Future<void> _exportarPdf() async {
    if (carregando || erro != null || exportando) return;
    setState(() => exportando = true);
    try {
      final ativos = inscricoes.where((i) => !_cancelada(i)).toList();
      final presentes = ativos.where(_presente).length;
      final linhas = _participantesFiltrados();
      final documento = pw.Document();
      documento.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (_) => [
          pw.Text('Relatório de participantes', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Text('Evento: ${widget.eventoTitulo}'),
          pw.Text('Gerado em: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}'),
          pw.Text('Filtro: $filtro'),
          pw.SizedBox(height: 12),
          pw.Text('Inscrições ativas: ${ativos.length} | Presentes: $presentes | '
              'Sem presença: ${ativos.length - presentes} | Canceladas: ${inscricoes.length - ativos.length}'),
          pw.SizedBox(height: 14),
          pw.TableHelper.fromTextArray(
            headers: ['Inscrição', 'Participante', 'Status', 'Data'],
            data: [for (final i in linhas) [
              '${i.id}', i.usuarioNome.isEmpty ? 'Usuário ${i.usuarioId}' : i.usuarioNome,
              _rotuloStatus(i),
              i.dataInscricao == null ? '-' : DateFormat('dd/MM/yyyy').format(i.dataInscricao!),
            ]],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            cellPadding: const pw.EdgeInsets.all(6),
            cellStyle: const pw.TextStyle(fontSize: 9),
          ),
          if (linhas.isEmpty) pw.Text('Nenhum participante neste filtro.'),
        ],
      ));
      await Printing.sharePdf(
        bytes: await documento.save(),
        filename: 'relatorio_evento_${widget.eventoId}_${filtro.toLowerCase()}.pdf',
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao exportar PDF: $e')),
      );
    } finally {
      if (mounted) setState(() => exportando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final ativos = inscricoes.where((i) => !_cancelada(i)).toList();
    final presentes = ativos.where(_presente).length;
    final pendentes = ativos.length - presentes;
    final canceladas = inscricoes.length - ativos.length;
    final liberados = certificados.where((c) => c.status.toUpperCase() == 'LIBERADO').length;
    final certificadosPendentes = certificados.length - liberados;
    final percentual = ativos.isEmpty ? 0.0 : presentes / ativos.length;
    final participantes = _participantesFiltrados();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard do organizador'),
        actions: [
          IconButton(
            onPressed: carregando ? null : _carregar,
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar indicadores',
          ),
        ],
      ),
      body: carregando
          ? const Center(child: CircularProgressIndicator())
          : erro != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, size: 44),
                        const SizedBox(height: 12),
                        Text(erro!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: _carregar,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Tentar novamente'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _carregar,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: cores.primaryContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('VISÃO GERAL DO EVENTO',
                                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: cores.onPrimaryContainer,
                                  letterSpacing: 1.2,
                                )),
                            const SizedBox(height: 8),
                            Text(widget.eventoTitulo,
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: cores.onPrimaryContainer,
                                )),
                            const SizedBox(height: 8),
                            Text('Dados atuais de inscrições e certificados',
                                style: TextStyle(color: cores.onPrimaryContainer)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text('Indicadores principais', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 10),
                      LayoutBuilder(builder: (context, constraints) {
                        final largura = (constraints.maxWidth - 10) / 2;
                        return Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _indicador('Inscrições ativas', ativos.length, Icons.people_outline, largura),
                            _indicador('Presentes', presentes, Icons.how_to_reg_outlined, largura),
                            _indicador('Sem presença', pendentes, Icons.person_off_outlined, largura),
                            _indicador('Canceladas', canceladas, Icons.cancel_outlined, largura),
                          ],
                        );
                      }),
                      const SizedBox(height: 18),
                      Text('Comparecimento', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Text('${(percentual * 100).toStringAsFixed(1)}%',
                                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                                const Spacer(),
                                Text('$presentes de ${ativos.length} presentes',
                                    style: TextStyle(color: cores.onSurfaceVariant)),
                              ]),
                              const SizedBox(height: 12),
                              LinearProgressIndicator(
                                value: percentual,
                                minHeight: 12,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              const SizedBox(height: 10),
                              Text(ativos.isEmpty
                                  ? 'Nenhuma inscrição ativa neste evento.'
                                  : '$pendentes participante(s) ainda sem presença registrada.',
                                  style: TextStyle(color: cores.onSurfaceVariant)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text('Certificados', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 10),
                      Row(children: [
                        Expanded(child: _indicador('Liberados', liberados, Icons.verified_outlined, null)),
                        const SizedBox(width: 10),
                        Expanded(child: _indicador('Não liberados', certificadosPendentes, Icons.pending_actions_outlined, null)),
                      ]),
                      const SizedBox(height: 8),
                      Text('Total de certificados registrados: ${certificados.length}',
                          style: TextStyle(color: cores.onSurfaceVariant)),
                      const SizedBox(height: 20),
                      Text('Exportar relatório', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Wrap(spacing: 10, runSpacing: 8, children: [
                        OutlinedButton.icon(
                          onPressed: exportando ? null : _exportarCsv,
                          icon: const Icon(Icons.table_view_outlined),
                          label: const Text('Exportar CSV'),
                        ),
                        FilledButton.icon(
                          onPressed: exportando ? null : _exportarPdf,
                          icon: const Icon(Icons.picture_as_pdf_outlined),
                          label: const Text('Exportar PDF'),
                        ),
                      ]),
                      const SizedBox(height: 6),
                      Text('A exportação usa o filtro de participantes selecionado abaixo.',
                          style: TextStyle(color: cores.onSurfaceVariant)),
                      const SizedBox(height: 20),
                      Row(children: [
                        Expanded(child: Text('Participantes', style: Theme.of(context).textTheme.titleLarge)),
                        Text('${participantes.length} exibido(s)',
                            style: TextStyle(color: cores.onSurfaceVariant)),
                      ]),
                      const SizedBox(height: 10),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(children: [
                          for (final opcao in const ['Todos', 'Presentes', 'Pendentes', 'Cancelados'])
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(opcao),
                                selected: filtro == opcao,
                                onSelected: (_) => setState(() => filtro = opcao),
                              ),
                            ),
                        ]),
                      ),
                      const SizedBox(height: 8),
                      if (participantes.isEmpty)
                        const Card(child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Text('Nenhum participante neste filtro.'),
                        ))
                      else
                        ...participantes.map((i) => Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              child: Icon(_cancelada(i) ? Icons.cancel_outlined :
                                  _presente(i) ? Icons.check_circle_outline : Icons.person_outline),
                            ),
                            title: Text(i.usuarioNome.isEmpty ? 'Participante #${i.usuarioId}' : i.usuarioNome),
                            subtitle: Text('Inscrição #${i.id} · ${_rotuloStatus(i)}'),
                          ),
                        )),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
    );
  }

  String _rotuloStatus(Inscricao i) {
    if (_cancelada(i)) return 'Cancelada';
    if (_presente(i)) return 'Presente';
    return 'Sem presença registrada';
  }

  Widget _indicador(String titulo, int valor, IconData icone, double? largura) {
    final cores = Theme.of(context).colorScheme;
    return SizedBox(
      width: largura,
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icone, color: cores.primary),
              const SizedBox(height: 12),
              Text('$valor', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(titulo, style: TextStyle(color: cores.onSurfaceVariant)),
            ],
          ),
        ),
      ),
    );
  }
}

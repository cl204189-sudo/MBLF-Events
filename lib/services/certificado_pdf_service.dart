import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/certificado.dart';

class CertificadoPdfService {
  static Future<void> visualizar(BuildContext context, Certificado certificado) async {
    if (certificado.status.toUpperCase() != 'LIBERADO') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Somente certificados liberados podem ser exportados.')),
      );
      return;
    }

    final documento = pw.Document(
      title: 'Certificado - ${certificado.tituloEvento}',
      author: 'MBLF Events',
    );

    final data = certificado.dataLiberacao == null
        ? 'Data de liberação não informada'
        : DateFormat('dd/MM/yyyy').format(certificado.dataLiberacao!);
    final carga = certificado.cargaHoraria == null
        ? 'Carga horária não informada'
        : '${certificado.cargaHoraria} horas';
    // O QR contém o código de validação, que pode ser informado
    // na tela pública "Validar certificado" do aplicativo.
    final codigo = certificado.codigo;

    documento.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(34),
        build: (context) => pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.indigo700, width: 3),
          ),
          padding: const pw.EdgeInsets.all(28),
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(children: [
                pw.Text('MBLF EVENTS', style: pw.TextStyle(
                  fontSize: 17, fontWeight: pw.FontWeight.bold,
                  color: PdfColors.indigo700,
                )),
                pw.SizedBox(height: 18),
                pw.Text('CERTIFICADO DE PARTICIPAÇÃO',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(fontSize: 27,
                    fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900)),
                pw.SizedBox(height: 22),
                pw.Text('Certificamos que', style: const pw.TextStyle(fontSize: 15)),
                pw.SizedBox(height: 8),
                pw.Text(certificado.nomeParticipante,
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(fontSize: 23, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 13),
                pw.Text('participou do evento', style: const pw.TextStyle(fontSize: 15)),
                pw.SizedBox(height: 7),
                pw.Text(certificado.tituloEvento,
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(fontSize: 19, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 14),
                pw.Text('Carga horária: $carga  |  Liberado em: $data',
                  style: const pw.TextStyle(fontSize: 12)),
              ]),
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Código de validação:',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                      pw.SizedBox(height: 5),
                      pw.Text(codigo, style: const pw.TextStyle(fontSize: 10)),
                      pw.SizedBox(height: 7),
                      pw.Text('Verifique a autenticidade na opção '
                          '"Validar certificado" do MBLF Events.',
                          style: const pw.TextStyle(fontSize: 10)),
                    ],
                  )),
                  pw.SizedBox(width: 16),
                  pw.BarcodeWidget(
                    barcode: pw.Barcode.qrCode(),
                    data: codigo,
                    width: 85,
                    height: 85,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => documento.save(),
      name: 'certificado_${certificado.id}.pdf',
    );
  }
}

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/api_config.dart';
import '../../config/app_theme.dart';

class CheckinScreen extends StatefulWidget {
  final int eventoId;
  final String eventoTitulo;

  const CheckinScreen({
    super.key,
    required this.eventoId,
    required this.eventoTitulo,
  });

  @override
  State<CheckinScreen> createState() =>
      _CheckinScreenState();
}

class _CheckinScreenState
    extends State<CheckinScreen> {

  final MobileScannerController scannerController =
      MobileScannerController();

  bool processando = false;

  Future<void> registrar(
    String tokenQr,
  ) async {
    if (processando) return;

    setState(() {
      processando = true;
    });

    await scannerController.stop();

    try {
      final prefs =
          await SharedPreferences.getInstance();

      final jwt =
          prefs.getString('token');

      if (jwt == null) {
        throw Exception(
          'Usuário não autenticado.',
        );
      }

      final url = Uri.parse(
        '${ApiConfig.baseUrl}/presencas/registrar',
      );

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwt',
        },
        body: jsonEncode({
          'token': tokenQr,
          'eventoId': widget.eventoId,
        }),
      );

      dynamic dados;

      if (response.body.isNotEmpty) {
        dados = jsonDecode(response.body);
      }

      if (!mounted) return;

      if (response.statusCode == 200 ||
          response.statusCode == 201) {

        await showDialog(
          context: context,
          builder: (_) {
            return AlertDialog(
              icon: const Icon(
                Icons.check_circle,
                color: AppTheme.verde,
                size: 55,
              ),
              title: const Text(
                'Presença registrada!',
              ),
              content: Text(
                dados is Map
                    ? '${dados['usuarioNome'] ?? 'Participante'} entrou no evento.'
                    : 'Check-in realizado com sucesso.',
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
      } else {
        final mensagem =
            dados is Map
                ? dados['mensagem'] ?? dados['message'] ??
                    'Não foi possível registrar presença.'
                : 'Não foi possível registrar presença.';

        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text(mensagem),
          ),
        );
      }
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
    } finally {
      if (mounted) {
        setState(() {
          processando = false;
        });

        try { await scannerController.start(); } catch (_) { /* Tela encerrada */ }
      }
    }
  }

  @override
  void dispose() {
    scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Check-in',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  widget.eventoTitulo,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Aponte a câmera para o QR Code do participante.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color:
                        AppTheme.textoSecundario,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: ClipRRect(
                borderRadius:
                    BorderRadius.circular(28),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    MobileScanner(
                      controller:
                          scannerController,
                      onDetect: (capture) {
                        if (capture
                            .barcodes.isEmpty) {
                          return;
                        }

                        final valor =
                            capture
                                .barcodes
                                .first
                                .rawValue;

                        if (valor != null &&
                            valor.isNotEmpty) {
                          registrar(valor);
                        }
                      },
                    ),

                    Center(
                      child: Container(
                        width: 230,
                        height: 230,
                        decoration:
                            BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(
                            25,
                          ),
                          border: Border.all(
                            color:
                                Colors.white,
                            width: 3,
                          ),
                        ),
                      ),
                    ),

                    if (processando)
                      Container(
                        color: Colors.black
                            .withValues(
                          alpha: 0.45,
                        ),
                        child: const Center(
                          child:
                              CircularProgressIndicator(
                            color:
                                Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          const Padding(
            padding: EdgeInsets.fromLTRB(
              24,
              5,
              24,
              24,
            ),
            child: Text(
              'O QR Code será validado automaticamente pelo sistema.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color:
                    AppTheme.textoSecundario,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../config/app_theme.dart';
import '../../models/certificado.dart';
import '../../services/certificado_service.dart';
import '../../services/certificado_pdf_service.dart';

class MeusCertificadosScreen
    extends StatefulWidget {

  const MeusCertificadosScreen({
    super.key,
  });

  @override
  State<MeusCertificadosScreen>
      createState() =>
          _MeusCertificadosScreenState();
}

class _MeusCertificadosScreenState
    extends State<MeusCertificadosScreen> with WidgetsBindingObserver {

  final CertificadoService service =
      CertificadoService();

  List<Certificado> certificados = [];

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
      final lista =
          await service.listarMeus();

      if (!mounted) return;

      setState(() {
        certificados = lista;
        carregando = false;
      });
    } catch (erro) {
      if (!mounted) return;

      setState(() {
        carregando = false;
      });

      if (!silencioso) ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível carregar os certificados.',
          ),
        ),
      );
    }
    finally {
      _syncEmAndamento = false;
      if (_syncPendente && mounted) {
        _syncPendente = false;
        carregar(silencioso: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Meus certificados',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: RefreshIndicator(
        onRefresh: carregar,

        child: carregando
            ? const Center(
                child:
                    CircularProgressIndicator(),
              )

            : certificados.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(
                        height: 170,
                      ),

                      Icon(
                        Icons
                            .workspace_premium_outlined,
                        size: 70,
                        color: AppTheme
                            .textoSecundario,
                      ),

                      SizedBox(
                        height: 16,
                      ),

                      Center(
                        child: Text(
                          'Você ainda não possui certificados liberados.',
                          textAlign:
                              TextAlign.center,
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
                        const EdgeInsets.all(
                      20,
                    ),
                    itemCount:
                        certificados.length,
                    itemBuilder:
                        (context, index) {

                      final certificado =
                          certificados[index];

                      return _cardCertificado(
                        certificado,
                      );
                    },
                  ),
      ),
    );
  }

  Widget _cardCertificado(
    Certificado certificado,
  ) {

    String dataLiberacao = '';

    if (certificado.dataLiberacao != null) {
      dataLiberacao =
          DateFormat(
        'dd/MM/yyyy',
      ).format(
        certificado.dataLiberacao!,
      );
    }

    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 16,
      ),

      padding:
          const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,

        borderRadius:
            BorderRadius.circular(24),

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
                width: 50,
                height: 50,

                decoration:
                    BoxDecoration(
                  gradient: AppTheme
                      .gradientePrincipal,

                  borderRadius:
                      BorderRadius.circular(
                    15,
                  ),
                ),

                child: const Icon(
                  Icons
                      .workspace_premium_outlined,
                  color: Colors.white,
                ),
              ),

              const SizedBox(
                width: 14,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [
                    const Text(
                      'CERTIFICADO',
                      style: TextStyle(
                        color:
                            AppTheme.verde,
                        fontSize: 11,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 4,
                    ),

                    Text(
                      certificado
                          .tituloEvento,

                      style:
                          const TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 20,
          ),

          _linha(
            Icons.person_outline,
            'Participante',
            certificado
                .nomeParticipante,
          ),

          if (certificado.cargaHoraria !=
              null) ...[
            const SizedBox(
              height: 12,
            ),

            _linha(
              Icons.schedule_outlined,
              'Carga horária',
              '${certificado.cargaHoraria} horas',
            ),
          ],

          if (dataLiberacao.isNotEmpty) ...[
            const SizedBox(
              height: 12,
            ),

            _linha(
              Icons
                  .calendar_today_outlined,
              'Liberado em',
              dataLiberacao,
            ),
          ],

          const SizedBox(
            height: 18,
          ),

          Container(
            width: double.infinity,

            padding:
                const EdgeInsets.all(
              13,
            ),

            decoration:
                BoxDecoration(
              color: AppTheme.fundo,

              borderRadius:
                  BorderRadius.circular(
                14,
              ),
            ),

            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                const Text(
                  'Código de validação',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme
                        .textoSecundario,
                  ),
                ),

                const SizedBox(
                  height: 5,
                ),

                SelectableText(
                  certificado.codigo,

                  style:
                      const TextStyle(
                    fontWeight:
                        FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (certificado.status.toUpperCase() == 'LIBERADO') ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () async {
                  try {
                    await CertificadoPdfService.visualizar(context, certificado);
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erro ao gerar PDF: $e')),
                    );
                  }
                },
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: const Text('Visualizar / salvar PDF'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _linha(
    IconData icone,
    String titulo,
    String valor,
  ) {
    return Row(
      children: [
        Icon(
          icone,
          size: 20,
          color: AppTheme.roxo,
        ),

        const SizedBox(
          width: 9,
        ),

        Text(
          '$titulo: ',

          style:
              const TextStyle(
            color:
                AppTheme.textoSecundario,
          ),
        ),

        Expanded(
          child: Text(
            valor,

            style:
                const TextStyle(
              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
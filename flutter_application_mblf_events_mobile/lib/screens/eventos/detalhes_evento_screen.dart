import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/api_config.dart';
import '../../config/app_theme.dart';
import '../../models/evento.dart';
import '../../widgets/gradient_button.dart';
import '../../services/evento_service.dart';

class DetalhesEventoScreen extends StatefulWidget {
  final Evento evento;

  const DetalhesEventoScreen({
    super.key,
    required this.evento,
  });

  @override
  State<DetalhesEventoScreen> createState() =>
      _DetalhesEventoScreenState();
}

class _DetalhesEventoScreenState
    extends State<DetalhesEventoScreen> {

  final EventoService eventoService =
      EventoService();

  late Evento evento;

  bool inscrito = false;
  bool carregando = false;

  @override
  void initState() {
    super.initState();

    evento = widget.evento;

    verificarInscricao();
  }

  Future<void> verificarInscricao() async {
      try {
        final prefs =
            await SharedPreferences.getInstance();

        final token =
            prefs.getString('token');

        if (token == null) {
          return;
        }

        final url = Uri.parse(
          '${ApiConfig.baseUrl}/inscricoes/minhas',
        );

        final response = await http.get(
          url,
          headers: {
            'Authorization': 'Bearer $token',
          },
        );

        if (response.statusCode == 200) {
          final List<dynamic> dados =
              jsonDecode(response.body);

          final possuiInscricao =
              dados.any(
            (inscricao) =>
                inscricao['eventoId'] ==
                    evento.id &&
                inscricao['status'] !=
                    'CANCELADO',
          );

          if (!mounted) return;

          setState(() {
            inscrito =
                possuiInscricao;
          });
        }
      } catch (_) {
        // Não impede a abertura da tela.
      }
    }    

  Future<void> inscrever() async {
    setState(() {
      carregando = true;
    });

    try {
      final prefs =
          await SharedPreferences.getInstance();

      final token =
          prefs.getString('token');

      if (token == null) {
        mostrarMensagem(
          'Sessão inválida. Faça login novamente.',
        );
        return;
      }

      final url = Uri.parse(
        '${ApiConfig.baseUrl}/inscricoes',
      );

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'eventoId': evento.id,
        }),
      );

      final dados =
          response.body.isNotEmpty
              ? jsonDecode(response.body)
              : null;

      if (response.statusCode == 200 ||
    response.statusCode == 201) {

        final eventoAtualizado =
            await eventoService.buscarPorId(
          evento.id,
        );

        if (!mounted) return;

        setState(() {
          inscrito = true;
          evento = eventoAtualizado;
        });

        showDialog(
          context: context,
          builder: (_) {
            return AlertDialog(
              icon: const Icon(
                Icons.check_circle,
                color: AppTheme.verde,
                size: 55,
              ),
              title: const Text(
                'Inscrição confirmada!',
              ),
              content: Text(
                'Você está inscrito em ${evento.titulo}.',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Fechar',
                  ),
                ),
              ],
            );
          },
        );
      } else {
        mostrarMensagem(
          dados is Map
              ? dados['mensagem'] ??
                  'Não foi possível realizar a inscrição.'
              : 'Não foi possível realizar a inscrição.',
        );
      }
    } catch (erro) {
      mostrarMensagem(
        'Não foi possível conectar com o servidor.',
      );
    } finally {
      if (mounted) {
        setState(() {
          carregando = false;
        });
      }
    }
  }

  void mostrarMensagem(
    String mensagem,
  ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(mensagem),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final inicio = evento.dataInicio.toLocal();
    final fim = evento.dataFim.toLocal();
    final encerrado = fim.isBefore(DateTime.now());
    final esgotado = evento.vagasDisponiveis != null &&
        evento.vagasDisponiveis! <= 0;
    final disponivel = !encerrado && evento.inscricoesAbertas && !esgotado;
    final status = encerrado
        ? 'Encerrado'
        : !evento.inscricoesAbertas
            ? 'Inscrições fechadas'
            : esgotado ? 'Esgotado' : 'Inscrições abertas';
    final corStatus = disponivel ? AppTheme.verde : const Color(0xFFB46B22);
    final local = [
      if (evento.endereco.trim().isNotEmpty) evento.endereco.trim(),
      if (evento.cidade.trim().isNotEmpty) evento.cidade.trim(),
    ].join(', ');

    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes do evento')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Container(
            height: 240,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: AppTheme.gradientePrincipal,
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (evento.imagemUrl != null)
                  Image.network(
                    '${ApiConfig.baseUrl}${evento.imagemUrl}',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                if (evento.imagemUrl != null)
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x66000000),
                          Color(0x99000000),
                          Color(0xE6000000),
                        ],
                        stops: [0, 0.45, 1],
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: .32),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            evento.tipo.isEmpty ? 'Evento' : evento.tipo,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.celebration_outlined,
                          color: Colors.white, size: 28),
                      ]),
                      const Spacer(),
                      Text(evento.titulo,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 23,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                          shadows: [Shadow(color: Colors.black87, blurRadius: 8)],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${DateFormat('dd/MM/yyyy').format(inicio)}  •  '
                        '${DateFormat('HH:mm').format(inicio)}',
                        style: const TextStyle(
                          color: Colors.white,
                          shadows: [Shadow(color: Colors.black87, blurRadius: 6)],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface,
              border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(14)),
            child: Row(children: [
              Icon(Icons.circle, size: 10, color: corStatus),
              const SizedBox(width: 8),
              Expanded(child: Text(status, style: TextStyle(
                fontWeight: FontWeight.w700, color: corStatus))),
              if (evento.vagasDisponiveis != null)
                Text('${evento.vagasDisponiveis} vagas',
                  style: const TextStyle(fontSize: 12,
                    color: AppTheme.textoSecundario)),
            ]),
          ),
          const SizedBox(height: 20),
          _secao('Quando e onde', [
            _info(Icons.event_outlined, 'Início',
              DateFormat('dd/MM/yyyy • HH:mm').format(inicio)),
            _info(Icons.event_available_outlined, 'Término',
              DateFormat('dd/MM/yyyy • HH:mm').format(fim)),
            if (local.isNotEmpty)
              _info(Icons.place_outlined, 'Localização', local),
          ]),
          const SizedBox(height: 14),
          _secao('Sobre o evento', [
            Text(evento.descricao.trim().isEmpty
                ? 'Descrição ainda não informada.'
                : evento.descricao,
              style: const TextStyle(height: 1.55,
                color: AppTheme.textoSecundario)),
          ]),
          if (evento.vagasTotal != null ||
              evento.cargaHoraria != null) ...[
            const SizedBox(height: 14),
            _secao('Informações adicionais', [
              if (evento.vagasTotal != null)
                _info(Icons.groups_outlined, 'Capacidade',
                  '${evento.vagasTotal} vagas no total'),
              if (evento.cargaHoraria != null)
                _info(Icons.schedule_outlined, 'Carga horária',
                  '${evento.cargaHoraria} horas'),
            ]),
          ],
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface,
          border: Border(top: BorderSide(color: Color(0xFFEBEDF2)))),
        child: SafeArea(top: false, child: inscrito
          ? Container(
              height: 50,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppTheme.verde.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(14)),
              child: const Row(mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, color: AppTheme.verde),
                  SizedBox(width: 8),
                  Text('Você já está inscrito',
                    style: TextStyle(color: AppTheme.verde,
                      fontWeight: FontWeight.bold)),
                ]),
            )
          : disponivel
              ? GradientButton(
                  texto: 'Inscrever-se',
                  icone: Icons.confirmation_number_outlined,
                  carregando: carregando,
                  onPressed: inscrever)
              : Container(
                  height: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F1F4),
                    borderRadius: BorderRadius.circular(14)),
                  child: Text(status,
                    style: const TextStyle(color: AppTheme.textoSecundario,
                      fontWeight: FontWeight.w600)),
                ),
        ),
      ),
    );
  }

  Widget _secao(String titulo, List<Widget> filhos) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: const TextStyle(fontSize: 17,
            fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          ...filhos,
        ]),
    );
  }

  Widget _info(IconData icone, String titulo, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: AppTheme.roxo.withValues(alpha: .09),
              borderRadius: BorderRadius.circular(11)),
            child: Icon(icone, color: AppTheme.roxo, size: 19)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titulo, style: const TextStyle(fontSize: 12,
                color: AppTheme.textoSecundario)),
              const SizedBox(height: 3),
              Text(valor, style: const TextStyle(
                fontWeight: FontWeight.w600, height: 1.35)),
            ])),
        ]),
    );
  }
}

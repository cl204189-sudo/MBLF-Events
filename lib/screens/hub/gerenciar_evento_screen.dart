import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../config/api_config.dart';
import '../../config/app_theme.dart';
import '../../models/evento.dart';
import 'escolher_plano_screen.dart';
import 'hub_screen.dart';
import 'criar_evento_screen.dart';

class GerenciarEventoScreen extends StatefulWidget {
  final Evento evento;

  const GerenciarEventoScreen({
    super.key,
    required this.evento,
  });

  @override
  State<GerenciarEventoScreen> createState() =>
      _GerenciarEventoScreenState();
}

class _GerenciarEventoScreenState
    extends State<GerenciarEventoScreen> {

  late Evento evento;

  bool processando = false;

  @override
  void initState() {
    super.initState();

    evento = widget.evento;
  }

  Future<String> _token() async {
    final prefs =
        await SharedPreferences.getInstance();

    final token =
        prefs.getString('token');

    if (token == null) {
      throw Exception(
        'Usuário não autenticado.',
      );
    }

    return token;
  }

  Future<void> atualizarEvento() async {
    final token = await _token();

    final url = Uri.parse(
      '${ApiConfig.baseUrl}/eventos/${evento.id}',
    );

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final dados =
          jsonDecode(response.body);

      if (!mounted) return;

      setState(() {
        evento =
            Evento.fromJson(dados);
      });
    }
  }

  Future<void> abrirInscricoes() async {
    await alterarInscricoes(
      abrir: true,
    );
  }

  Future<void> fecharInscricoes() async {
    await alterarInscricoes(
      abrir: false,
    );
  }

  Future<void> alterarInscricoes({
    required bool abrir,
  }) async {
    if (processando) return;

    setState(() {
      processando = true;
    });

    try {
      final token = await _token();

      final acao = abrir
          ? 'abrir-inscricoes'
          : 'fechar-inscricoes';

      final url = Uri.parse(
        '${ApiConfig.baseUrl}/eventos/${evento.id}/$acao',
      );

      final response = await http.put(
        url,
        headers: {
          'Authorization':
              'Bearer $token',
        },
      );

      dynamic dados;

      if (response.body.isNotEmpty) {
        dados =
            jsonDecode(response.body);
      }

      if (response.statusCode != 200) {
        throw Exception(
          dados is Map
              ? dados['mensagem'] ??
                  'Não foi possível alterar as inscrições.'
              : 'Não foi possível alterar as inscrições.',
        );
      }

      await atualizarEvento();

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            abrir
                ? 'Inscrições abertas!'
                : 'Inscrições fechadas.',
          ),
        ),
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
              size: 42,
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
          processando = false;
        });
      }
    }
  }

  Future<void> cancelarEvento() async {
    if (processando) return;
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 44),
        title: const Text('Cancelar este evento?'),
        content: const Text(
          'Esta ação não poderá ser desfeita. Novas inscrições, check-ins, '
          'chats e emissões de certificados serão bloqueados. '
          'Os registros existentes permanecerão no histórico. '
          'Certificados já emitidos deixarão de ser validados publicamente.'
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Voltar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Confirmar cancelamento'),
          ),
        ],
      ),
    );
    if (confirmado != true || !mounted) return;
    setState(() => processando = true);
    try {
      final token = await _token();
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/eventos/${evento.id}/cancelar'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode != 200) {
        String mensagem = 'Não foi possível cancelar o evento.';
        try {
          final body = jsonDecode(response.body);
          if (body is Map) mensagem = (body['mensagem'] ?? body['message'] ?? mensagem).toString();
        } catch (_) {}
        throw Exception(mensagem);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Evento cancelado com sucesso.')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => processando = false);
    }
  }

  String formatarData(
    DateTime? data,
  ) {
    if (data == null) {
      return 'Não ativo';
    }

    return DateFormat(
      'dd/MM/yyyy',
    ).format(data);
  }

  Future<void> confirmarInscricoes(bool abrir) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(abrir ? 'Abrir inscrições?' : 'Fechar inscrições?'),
        content: Text(abrir
          ? 'Novos participantes poderão se inscrever enquanto houver vagas e o evento estiver ativo.'
          : 'Novas inscrições serão bloqueadas. As inscrições já realizadas serão preservadas.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Voltar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirmar')),
        ],
      ),
    );
    if (confirmar == true) await alterarInscricoes(abrir: abrir);
  }

  Future<void> _abrirPlano(String tipo) async {
    final alterou = await Navigator.push<bool>(context,
      MaterialPageRoute(builder: (_) => EscolherPlanoScreen(eventoId: evento.id, tipo: tipo)));
    if (alterou == true) await atualizarEvento();
  }

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final agora = DateTime.now();
    final hubAtivo = evento.hubAte?.isAfter(agora) ?? false;
    final publicacaoAtiva = evento.publicacaoAte?.isAfter(agora) ?? false;
    final bloqueado = ['CANCELADO', 'REMOVIDO_ADMIN', 'ENCERRADO'].contains(evento.status) ||
        !evento.dataFim.isAfter(agora);
    final podeCancelar = !bloqueado;

    return Scaffold(
      appBar: AppBar(title: const Text('Gerenciar evento'), actions: [
        IconButton(onPressed: processando ? null : atualizarEvento,
          tooltip: 'Atualizar', icon: const Icon(Icons.refresh)),
      ]),
      body: RefreshIndicator(
        onRefresh: atualizarEvento,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(gradient: AppTheme.gradientePrincipal,
                borderRadius: BorderRadius.circular(20)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(evento.titulo,
                    style: const TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.bold))),
                  const SizedBox(width: 8),
                  _etiqueta(evento.status.replaceAll('_', ' ')),
                ]),
                const SizedBox(height: 6),
                Text(evento.cidade, style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 12),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  _etiqueta(evento.inscricoesAbertas ? 'Inscrições abertas' : 'Inscrições fechadas'),
                  _etiqueta(hubAtivo ? 'HUB ativo' : 'HUB inativo'),
                ]),
              ]),
            ),
            const SizedBox(height: 22),
            Text('Configurações do evento', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            Card(child: Column(children: [
              _linha(Icons.public_outlined, 'Publicação',
                publicacaoAtiva ? 'Ativa até ${formatarData(evento.publicacaoAte)}' : 'Não ativa',
                () => _abrirPlano('PUBLICACAO'),
                enabled: !bloqueado),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _linha(Icons.dashboard_customize_outlined, 'MBLF HUB',
                hubAtivo ? 'Ativo até ${formatarData(evento.hubAte)}' : 'Não ativo',
                () async {
                  if (hubAtivo) {
                    await Navigator.push(context, MaterialPageRoute(builder: (_) =>
                      HubScreen(eventoId: evento.id, eventoTitulo: evento.titulo, organizador: true)));
                    if (mounted) await atualizarEvento();
                  } else {
                    await _abrirPlano('HUB');
                  }
                }, enabled: hubAtivo || !bloqueado),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _linha(Icons.confirmation_number_outlined, 'Inscrições',
                evento.inscricoesAbertas ? 'Abertas • ${evento.vagasDisponiveis ?? 0} vagas disponíveis' : 'Fechadas',
                () => confirmarInscricoes(!evento.inscricoesAbertas),
                enabled: !bloqueado),
            ])),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: bloqueado || processando ? null : () async {
                  final atualizado = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CriarEventoScreen(evento: evento),
                    ),
                  );
                  if (atualizado == true && mounted) await atualizarEvento();
                },
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Editar evento'),
              ),
            ),
            const SizedBox(height: 20),
            Text('A publicação controla a visibilidade no Explorar. O HUB controla as ferramentas da equipe. '
              'As inscrições podem ser abertas ou fechadas separadamente.',
              style: TextStyle(color: cores.onSurfaceVariant, fontSize: 12)),
            if (podeCancelar) ...[
              const SizedBox(height: 20),
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.warning_amber_outlined, color: cores.error),
                title: Text('Cancelar evento', style: TextStyle(color: cores.error, fontWeight: FontWeight.w600)),
                subtitle: const Text('Ação definitiva; preserva o histórico'),
                trailing: Icon(Icons.chevron_right, color: cores.error),
                onTap: processando ? null : cancelarEvento,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _etiqueta(String texto) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(20)),
    child: Text(texto, style: const TextStyle(color: Colors.white, fontSize: 11,
      fontWeight: FontWeight.w600)),
  );

  Widget _linha(IconData icone, String titulo, String descricao,
      Future<void> Function() acao, {bool enabled = true}) {
    final cores = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      leading: Icon(icone, color: cores.primary),
      title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(descricao, maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: const Icon(Icons.chevron_right),
      enabled: enabled && !processando,
      onTap: enabled && !processando ? () { acao(); } : null,
    );
  }
}

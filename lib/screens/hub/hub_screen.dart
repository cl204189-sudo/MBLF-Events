import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/api_config.dart';
import '../../config/app_theme.dart';
import '../../models/evento.dart';
import '../../models/evento_colaborador.dart';
import '../../models/inscricao.dart';
import '../../services/inscricao_evento_service.dart';
import 'calendario_screen.dart';
import 'certificados_hub_screen.dart';
import 'chat_screen.dart';
import 'checkin_screen.dart';
import 'colaboradores_screen.dart';
import 'dashboard_organizador_screen.dart';
import 'inscritos_screen.dart';
import 'moderacao_screen.dart';
import 'tarefas_screen.dart';

class HubScreen extends StatefulWidget {
  final int eventoId;
  final String eventoTitulo;
  final bool organizador;
  final EventoColaborador? colaborador;

  const HubScreen({
    super.key,
    required this.eventoId,
    required this.eventoTitulo,
    required this.organizador,
    this.colaborador,
  });

  @override
  State<HubScreen> createState() => _HubScreenState();
}

class _HubScreenState extends State<HubScreen> with WidgetsBindingObserver {
  Evento? evento;
  List<Inscricao>? inscricoes;
  String? aviso;
  bool consultando = false;
  bool ativo = true;
  Timer? atualizador;
  EventoColaborador? colaboradorAtual;
  bool verificandoVinculo = false;

  bool get podeChat => widget.organizador || (colaboradorAtual?.podeChat ?? false);
  bool get podeCalendario => widget.organizador || (colaboradorAtual?.podeCalendario ?? false);
  bool get podeTarefas => widget.organizador || (colaboradorAtual?.podeTarefas ?? false);
  bool get podeVerInscritos => widget.organizador || (colaboradorAtual?.podeVerInscritos ?? false);
  bool get podeRegistrarPresencas => widget.organizador || (colaboradorAtual?.podeRegistrarPresencas ?? false);
  bool get podeLiberarCertificados => widget.organizador || (colaboradorAtual?.podeLiberarCertificados ?? false);
  bool get podeModeracao => widget.organizador ||
      (colaboradorAtual?.podeSilenciar ?? false) ||
      (colaboradorAtual?.podeExpulsar ?? false);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    colaboradorAtual = widget.colaborador;
    _atualizar();
    atualizador = Timer.periodic(const Duration(seconds: 8), (_) {
      if (ativo) _atualizar();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    ativo = state == AppLifecycleState.resumed;
    if (ativo) _atualizar();
  }

  @override
  void dispose() {
    atualizador?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<Map<String, String>> _cabecalhos() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) throw Exception('Faça login para acessar o HUB.');
    return {'Authorization': 'Bearer $token'};
  }

  Future<void> _atualizar() async {
    if (consultando) return;
    consultando = true;
    try {
      final resposta = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/eventos/${widget.eventoId}'),
        headers: await _cabecalhos(),
      );
      if (resposta.statusCode != 200) {
        throw Exception('Não foi possível atualizar o evento (${resposta.statusCode}).');
      }
      final novoEvento = Evento.fromJson(jsonDecode(resposta.body));
      // Atualiza permissões do colaborador sem exigir que ele reabra o HUB.
      if (!widget.organizador) {
        await _sincronizarVinculo();
        if (!mounted) return;
      }
      List<Inscricao>? novosInscritos;
      if (podeVerInscritos) {
        try {
          novosInscritos = await InscricaoEventoService().listarPorEvento(widget.eventoId);
        } catch (_) {
          // Não bloqueia os dados do evento se os indicadores estiverem indisponíveis.
        }
      }
      if (!mounted) return;
      setState(() {
        evento = novoEvento;
        if (novosInscritos != null) inscricoes = novosInscritos;
        aviso = null;
      });
    } catch (e) {
      if (mounted) setState(() => aviso = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      consultando = false;
    }
  }

  Future<void> _sincronizarVinculo() async {
    if (verificandoVinculo) return;
    verificandoVinculo = true;
    try {
      final resposta = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/colaboradores/meus'),
        headers: await _cabecalhos(),
      );
      if (resposta.statusCode != 200) return;
      final lista = (jsonDecode(resposta.body) as List<dynamic>)
          .map((item) => EventoColaborador.fromJson(item as Map<String, dynamic>))
          .where((item) => item.eventoId == widget.eventoId)
          .toList();
      if (!mounted) return;
      final ativos = lista.where((item) => item.status == 'ACEITO').toList();
      if (ativos.isEmpty) {
        // Vínculo revogado: não manter atalhos administrativos visíveis.
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Seu acesso de colaborador a este HUB não está mais ativo.'),
        ));
        return;
      }
      final novo = ativos.first;
      if (mounted) setState(() => colaboradorAtual = novo);
    } catch (_) {
      // Falhas temporárias de rede não devem expulsar o usuário da tela.
    } finally {
      verificandoVinculo = false;
    }
  }

  Future<List<EventoColaborador>> _carregarColaboradores() async {
    final resposta = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/colaboradores/evento/${widget.eventoId}'),
      headers: await _cabecalhos(),
    );
    if (resposta.statusCode != 200) {
      throw Exception('Não foi possível carregar os colaboradores.');
    }
    final dados = jsonDecode(resposta.body) as List<dynamic>;
    return dados.map((e) => EventoColaborador.fromJson(e)).toList();
  }

  Future<void> _abrir(Widget tela) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => tela));
    if (mounted) _atualizar();
  }

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final e = evento;
    final ativos = inscricoes?.where((i) {
      final status = i.status.toUpperCase();
      return status != 'CANCELADO' && status != 'CANCELADA';
    }).toList();
    final presentes = ativos?.where((i) => i.status.toUpperCase() == 'PRESENTE').length;
    final vagas = e?.vagasDisponiveis;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu HUB'),
        actions: [
          IconButton(
            onPressed: consultando ? null : _atualizar,
            tooltip: 'Atualizar HUB',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _atualizar,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
          children: [
            _capa(cores, e),
            if (aviso != null) ...[
              const SizedBox(height: 10),
              Text(aviso!, style: TextStyle(color: cores.error)),
            ],
            if (podeVerInscritos || widget.organizador) ...[
              const SizedBox(height: 18),
              Row(children: [
                Expanded(child: _indicador('Inscritos', ativos?.length.toString() ?? '—', Icons.people_outline)),
                const SizedBox(width: 8),
                Expanded(child: _indicador('Presentes', presentes?.toString() ?? '—', Icons.how_to_reg_outlined)),
                const SizedBox(width: 8),
                Expanded(child: _indicador('Vagas livres', vagas?.toString() ?? '—', Icons.event_seat_outlined)),
              ]),
            ],
            const SizedBox(height: 22),
            if (widget.organizador || podeVerInscritos || podeRegistrarPresencas)
              _secao('Gerenciamento', [
                if (widget.organizador)
                  _atalho('Dashboard', 'Estatísticas do evento', Icons.bar_chart_outlined,
                    () => _abrir(DashboardOrganizadorScreen(eventoId: widget.eventoId, eventoTitulo: widget.eventoTitulo))),
                if (podeVerInscritos)
                  _atalho('Participantes', 'Inscrições e presenças', Icons.groups_outlined,
                    () => _abrir(InscritosScreen(eventoId: widget.eventoId, eventoTitulo: widget.eventoTitulo))),
                if (podeRegistrarPresencas)
                  _atalho('Check-in', 'Ler QR Code', Icons.qr_code_scanner,
                    () => _abrir(CheckinScreen(eventoId: widget.eventoId, eventoTitulo: widget.eventoTitulo))),
              ]),
            if (podeChat) _secao('Comunicação', [
              _atalho('Chat geral', 'Participantes do evento', Icons.forum_outlined,
                () => _abrir(ChatScreen(eventoId: widget.eventoId, eventoTitulo: widget.eventoTitulo, canal: 'GERAL'))),
              _atalho('Chat da equipe', 'Organização do evento', Icons.chat_bubble_outline,
                () => _abrir(ChatScreen(eventoId: widget.eventoId, eventoTitulo: widget.eventoTitulo, canal: 'ORGANIZACAO'))),
            ]),
            if (podeCalendario || podeTarefas || podeLiberarCertificados || podeModeracao || widget.organizador)
              _secao('Equipe e atividades', [
                if (podeCalendario)
                  _atalho('Calendário', 'Agenda e atividades', Icons.calendar_month_outlined,
                    () => _abrir(CalendarioScreen(eventoId: widget.eventoId, eventoTitulo: widget.eventoTitulo))),
                if (podeTarefas)
                  _atalho('Tarefas', 'Acompanhar tarefas', Icons.task_alt_outlined,
                    () => _abrir(TarefasScreen(eventoId: widget.eventoId, eventoTitulo: widget.eventoTitulo))),
                if (podeLiberarCertificados)
                  _atalho('Certificados', 'Gerar e liberar', Icons.workspace_premium_outlined,
                    () => _abrir(CertificadosHubScreen(eventoId: widget.eventoId, eventoTitulo: widget.eventoTitulo))),
                if (widget.organizador)
                  _atalho('Colaboradores', 'Permissões da equipe', Icons.manage_accounts_outlined,
                    () => _abrir(ColaboradoresScreen(eventoId: widget.eventoId, eventoTitulo: widget.eventoTitulo))),
                if (podeModeracao)
                  _atalho('Moderação', 'Gerenciar acessos', Icons.admin_panel_settings_outlined,
                    _abrirModeracao),
              ]),
            const SizedBox(height: 8),
            Text('Os dados e permissões são atualizados a cada 8 segundos.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: cores.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }

  Future<void> _abrirModeracao() async {
    try {
      final colaboradores = await _carregarColaboradores();
      if (!mounted) return;
      await _abrir(ModeracaoScreen(
        eventoId: widget.eventoId,
        eventoTitulo: widget.eventoTitulo,
        organizador: widget.organizador,
        podeSilenciar: widget.organizador || (colaboradorAtual?.podeSilenciar ?? false),
        podeExpulsar: widget.organizador || (colaboradorAtual?.podeExpulsar ?? false),
        colaboradores: colaboradores,
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Widget _capa(ColorScheme cores, Evento? e) {
    final imagem = e?.imagemUrl;
    final temImagem = imagem != null && imagem.isNotEmpty;
    final status = e?.status ?? 'CARREGANDO';
    return Container(
      height: 205,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: AppTheme.gradientePrincipal,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(fit: StackFit.expand, children: [
        if (temImagem)
          Image.network('${ApiConfig.baseUrl}$imagem', fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const SizedBox.shrink()),
        if (temImagem)
          const DecoratedBox(decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [Color(0x66000000), Color(0xDD000000)]),
          )),
        Padding(
          padding: const EdgeInsets.all(18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              _etiqueta(widget.organizador ? 'ORGANIZADOR' : 'COLABORADOR'),
              const Spacer(),
              _etiqueta(status),
            ]),
            const Spacer(),
            Text(e?.titulo ?? widget.eventoTitulo,
              maxLines: 2, overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(e == null ? 'Central de organização do evento'
              : '${e.dataInicio.day.toString().padLeft(2, '0')}/${e.dataInicio.month.toString().padLeft(2, '0')}/${e.dataInicio.year}  •  ${e.cidade}',
              style: const TextStyle(color: Colors.white, fontSize: 12)),
          ]),
        ),
      ]),
    );
  }

  Widget _etiqueta(String texto) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.32),
      borderRadius: BorderRadius.circular(30)),
    child: Text(texto, style: const TextStyle(color: Colors.white,
      fontSize: 10, fontWeight: FontWeight.bold)),
  );

  Widget _indicador(String titulo, String valor, IconData icone) => Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 4),
      child: Column(children: [
        Icon(icone, size: 21, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 7),
        Text(valor, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.bold)),
        Text(titulo, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11)),
      ]),
    ),
  );

  Widget _secao(String titulo, List<Widget> atalhos) {
    if (atalhos.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(titulo, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        LayoutBuilder(builder: (context, constraints) {
          final largura = (constraints.maxWidth - 10) / 2;
          return Wrap(spacing: 10, runSpacing: 10,
            children: atalhos.map((a) => SizedBox(width: largura, child: a)).toList());
        }),
      ]),
    );
  }

  Widget _atalho(String titulo, String subtitulo, IconData icone, VoidCallback acao) {
    final cores = Theme.of(context).colorScheme;
    return Material(
      color: cores.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: acao,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          constraints: const BoxConstraints(minHeight: 108),
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cores.outlineVariant)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icone, color: cores.primary, size: 25),
            const SizedBox(height: 10),
            Text(titulo, maxLines: 2, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(height: 3),
            Text(subtitulo, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(color: cores.onSurfaceVariant, fontSize: 10)),
          ]),
        ),
      ),
    );
  }
}

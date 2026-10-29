import '../../widgets/eventos_por_periodo.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import '../../services/admin_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/usuario_service.dart';
import '../../services/evento_service.dart';
import '../../models/evento.dart';

/// Painel de funcionário. Não oferece ações administrativas sem autorização
/// verificada pela API: a versão atual do backend não expõe as permissões
/// atribuídas ao funcionário nem libera as rotas /admin/** para esse perfil.
class FuncionarioScreen extends StatefulWidget {
  const FuncionarioScreen({super.key});

  @override
  State<FuncionarioScreen> createState() => _FuncionarioScreenState();
}

class _FuncionarioScreenState extends State<FuncionarioScreen> {
  Timer? _timer;
  final adminApi = AdminService();
  Map<String, bool> permissoes = {};
  List<Map<String, dynamic>> registros = [];
  String secao = 'Eventos';
  bool buscandoRegistros = false;
  bool _sincronizando = false;
  String? erroPermissoes;
  bool permissoesConsultadas = false;
  String? erroRegistros;
  bool carregando = true;
  bool autorizado = false;
  String? erro;
  String nome = '';
  List<Evento> eventos = [];
  bool carregandoEventos = false;
  String? erroEventos;
  String filtro = '';
  String filtroRegistros = '';

  Future<void> _executarAcao(Future<void> Function() acao) async {
    try {
      await acao();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Operação concluída.')));
      await _carregarRegistros();
      await _carregarEventos();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Não foi possível concluir: $e')));
    }
  }

  Future<void> _confirmarBloqueio(Map<String, dynamic> d) async {
    final id = int.tryParse('${d['id'] ?? ''}');
    if (id == null) return;
    final ativo = d['ativo'] != false;
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: Text(ativo ? 'Bloquear usuário?' : 'Desbloquear usuário?'),
      content: Text('Confirma a alteração de acesso de ${d['nome'] ?? 'usuário'}?'),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirmar'))],
    ));
    if (ok == true) await _executarAcao(() => ativo ? adminApi.bloquearFuncionario(id) : adminApi.desbloquearFuncionario(id));
  }

  Future<void> _confirmarRemocao(Map<String, dynamic> d) async {
    final id = int.tryParse('${d['id'] ?? ''}');
    if (id == null) return;
    final controller = TextEditingController();
    final motivo = await showDialog<String>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Remover evento?'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('Evento: ${d['titulo'] ?? d['nome'] ?? id}'),
        TextField(controller: controller, maxLines: 2, decoration: const InputDecoration(labelText: 'Motivo obrigatório')),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
        FilledButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('Remover'))],
    ));
    controller.dispose();
    if (motivo != null && motivo.isNotEmpty) await _executarAcao(() => adminApi.removerEventoFuncionario(id, motivo));
  }

  Future<void> _carregarEventos() async {
    if (!autorizado) return;
    setState(() { carregandoEventos = true; erroEventos = null; });
    try {
      final lista = await EventoService().listarPublicos();
      if (mounted) setState(() => eventos = lista);
    } catch (e) {
      if (mounted) setState(() => erroEventos = 'Não foi possível consultar os eventos públicos.');
    } finally {
      if (mounted) setState(() => carregandoEventos = false);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(_observer);
    _verificar();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => _sincronizar());
  }

  late final _FuncionarioLifecycleObserver _observer = _FuncionarioLifecycleObserver(() => _sincronizar());

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(_observer);
    super.dispose();
  }

  Future<void> _sincronizar() async {
    if (!mounted || _sincronizando || WidgetsBinding.instance.lifecycleState == AppLifecycleState.paused) return;
    _sincronizando = true;
    try {
      final p = await adminApi.minhasPermissoesFuncionario();
      if (!mounted) return;
      setState(() { permissoes = p; permissoesConsultadas = true; erroPermissoes = null; });
      await _carregarRegistros();
    } catch (e) {
      if (mounted) setState(() {
        erroPermissoes = e.toString().replaceFirst('Exception: ', '');
        permissoesConsultadas = false;
        permissoes = {};
        registros = [];
      });
    }
    finally { _sincronizando = false; }
  }

  Future<void> _carregarRegistros() async {
    if (!mounted) return;
    final chave = secao == 'Usuários' ? 'visualizarUsuarios' : 'visualizarEventos';
    if (permissoes[chave] != true) {
      setState(() { registros = []; erroRegistros = null; });
      return;
    }
    setState(() { buscandoRegistros = true; erroRegistros = null; });
    try {
      final lista = secao == 'Usuários' ? await adminApi.usuariosFuncionario() : await adminApi.eventosFuncionario();
      if (mounted) setState(() { registros = lista; erroRegistros = null; });
    } catch (e) {
      if (mounted) setState(() { registros = []; erroRegistros = e.toString().replaceFirst('Exception: ', ''); });
    } finally {
      if (mounted) setState(() => buscandoRegistros = false);
    }
  }

  Future<void> _verificar() async {
    setState(() {
      carregando = true;
      erro = null;
      autorizado = false;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final perfilLocal = (prefs.getString('perfil') ?? '').trim().toUpperCase();
      final token = prefs.getString('token') ?? '';
      if (perfilLocal != 'FUNCIONARIO' || token.isEmpty) {
        throw Exception('Acesso exclusivo para funcionários autenticados.');
      }

      // Revalida o perfil com a API, evitando confiar só no dado local.
      final dados = await UsuarioService().buscarMeuPerfil();
      final perfilServidor = (dados['perfil'] ?? '').toString().trim().toUpperCase();
      if (perfilServidor != 'FUNCIONARIO' || dados['ativo'] == false) {
        throw Exception('Sua conta não possui acesso ativo de funcionário.');
      }
      if (!mounted) return;
      setState(() {
        autorizado = true;
        nome = (dados['nome'] ?? '').toString();
      });
      await _carregarEventos();
      await _sincronizar();
    } catch (e) {
      if (!mounted) return;
      setState(() => erro = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Área do funcionário'),
        actions: [
          IconButton(
            tooltip: 'Atualizar acesso',
            onPressed: _verificar,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: carregando
          ? const Center(child: CircularProgressIndicator())
          : !autorizado
              ? Center(child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.lock_outline, size: 46),
                    const SizedBox(height: 12),
                    Text(erro ?? 'Acesso não autorizado.',
                      textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    OutlinedButton(onPressed: _verificar,
                      child: const Text('Tentar novamente')),
                  ]),
                ))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: cores.primaryContainer,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.badge_outlined, size: 30),
                          const SizedBox(height: 10),
                          Text('Bem-vindo${nome.isEmpty ? '' : ', $nome'}',
                            style: const TextStyle(
                              fontSize: 19, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          const Text('Perfil confirmado pela API. As ferramentas abaixo dependem das permissões atribuídas pelo administrador.'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text('Central de trabalho', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('Ferramentas disponíveis conforme suas permissões.'),
                    Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [const Icon(Icons.verified_user_outlined), const SizedBox(width: 8),
                          const Expanded(child: Text('Resumo do acesso', style: TextStyle(fontWeight: FontWeight.bold))),
                          Text(permissoesConsultadas ? '${permissoes.values.where((v) => v).length} de 6 concedidas' : 'Aguardando API')]),
                        const SizedBox(height: 8),
                        Wrap(spacing: 8, children: [
                          if (permissoes['visualizarEventos'] == true)
                            ActionChip(label: const Text('Consultar eventos'), onPressed: () {
                              setState(() => secao = 'Eventos'); _carregarRegistros();
                            }),
                          if (permissoes['visualizarUsuarios'] == true)
                            ActionChip(label: const Text('Consultar usuários'), onPressed: () {
                              setState(() => secao = 'Usuários'); _carregarRegistros();
                            }),
                          if (permissoesConsultadas && !permissoes.values.any((v) => v))
                            const Text('Nenhuma permissão administrativa concedida.'),
                        ]),
                      ],
                    ))),
                    if (erroPermissoes != null) Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Não foi possível consultar as permissões', style: TextStyle(fontWeight: FontWeight.bold, color: cores.error)),
                      Text(erroPermissoes!),
                      TextButton(onPressed: _sincronizar, child: const Text('Tentar novamente')),
                    ]))),
                    const SizedBox(height: 18),
                    Row(children: [
                      const Expanded(child: Text('Eventos públicos',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold))),
                      IconButton(tooltip: 'Recarregar eventos',
                        onPressed: carregandoEventos ? null : _carregarEventos,
                        icon: const Icon(Icons.refresh)),
                    ]),
                    const Text('Consulta de informações públicas. Não equivale à permissão administrativa de moderar eventos.'),
                    const SizedBox(height: 10),
                    TextField(
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: 'Buscar evento ou cidade',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: (valor) => setState(() => filtro = valor.trim().toLowerCase()),
                    ),
                    const SizedBox(height: 10),
                    if (carregandoEventos)
                      const Center(child: Padding(padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator()))
                    else if (erroEventos != null)
                      Text(erroEventos!, style: TextStyle(color: cores.error))
                    else ...[
                      EventosPorPeriodo<Evento>(
                        itens: eventos.where((e) => e.titulo.toLowerCase().contains(filtro) || e.cidade.toLowerCase().contains(filtro)).toList(),
                        inicio: (e) => e.dataInicio,
                        fim: (e) => e.dataFim,
                        construir: (evento) => Card(child: ListTile(
                          leading: const Icon(Icons.event_outlined),
                          title: Text(evento.titulo),
                          subtitle: Text('${evento.cidade} • ${evento.tipo}'),
                        )),
                      ),
                      if (!eventos.any((e) => e.titulo.toLowerCase().contains(filtro)
                        || e.cidade.toLowerCase().contains(filtro)))
                        const Padding(padding: EdgeInsets.all(12),
                          child: Text('Nenhum evento público encontrado.')),
                    ],
                    const SizedBox(height: 18),
                    const Text('Permissões do funcionário', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    if (!permissoesConsultadas && erroPermissoes == null) const Text('Consultando permissões da API...'),
                    for (final p in const {
                      'visualizarUsuarios': 'Visualizar usuários',
                      'bloquearUsuarios': 'Bloquear usuários',
                      'visualizarEventos': 'Visualizar eventos',
                      'moderarEventos': 'Moderar eventos',
                      'visualizarPagamentos': 'Visualizar pagamentos',
                      'gerenciarPlanos': 'Gerenciar planos',
                    }.entries)
                      ListTile(dense: true,
                        leading: Icon(permissoes[p.key] == true ? Icons.check_circle_outline : Icons.lock_outline,
                          color: permissoes[p.key] == true ? cores.primary : cores.outline),
                        title: Text(p.value),
                        subtitle: Text(!permissoesConsultadas ? 'Não verificada' : permissoes[p.key] == true ? 'Concedida pela API' : 'Não concedida'),
                        trailing: IconButton(tooltip: 'Entender permissão', icon: const Icon(Icons.info_outline, size: 19), onPressed: () => showDialog<void>(context: context, builder: (ctx) => AlertDialog(title: Text(p.value), content: Text(const {
                          'visualizarUsuarios': 'Permite consultar dados de usuários pela rota autorizada.',
                          'bloquearUsuarios': 'Permite bloquear e desbloquear usuários comuns, com confirmação e auditoria.',
                          'visualizarEventos': 'Permite consultar eventos pela rota autorizada.',
                          'moderarEventos': 'Permite remover eventos com motivo obrigatório e registro de auditoria.',
                          'visualizarPagamentos': 'Depende de endpoint seguro para consultar pagamentos.',
                          'gerenciarPlanos': 'Depende de endpoint seguro para administrar planos.',
                        }[p.key] ?? ''), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fechar'))]))),),
                    const SizedBox(height: 12),
                    if (permissoes['visualizarUsuarios'] == true || permissoes['visualizarEventos'] == true) ...[
                      const Text('Consultas autorizadas', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                      Wrap(spacing: 8, children: [
                        if (permissoes['visualizarEventos'] == true)
                          ChoiceChip(label: const Text('Eventos'), selected: secao == 'Eventos',
                            onSelected: (_) { setState(() => secao = 'Eventos'); _carregarRegistros(); }),
                        if (permissoes['visualizarUsuarios'] == true)
                          ChoiceChip(label: const Text('Usuários'), selected: secao == 'Usuários',
                            onSelected: (_) { setState(() => secao = 'Usuários'); _carregarRegistros(); }),
                      ]),
                      const SizedBox(height: 8),
                      TextField(
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search),
                          hintText: secao == 'Usuários' ? 'Buscar nome, e-mail ou perfil' : 'Buscar evento, cidade ou situação',
                          border: const OutlineInputBorder(), isDense: true,
                        ),
                        onChanged: (v) => setState(() => filtroRegistros = v.trim().toLowerCase()),
                      ),
                      if (buscandoRegistros) const LinearProgressIndicator(),
                      if (erroRegistros != null) Text('Erro na consulta: $erroRegistros', style: TextStyle(color: cores.error)),
                      Builder(builder: (context) {
                        final visiveis = registros.where((d) => d.values.join(' ').toLowerCase().contains(filtroRegistros)).toList();
                        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                          Padding(padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text('${visiveis.length} de ${registros.length} registros', style: Theme.of(context).textTheme.bodySmall)),
                          if (!buscandoRegistros && visiveis.isEmpty && erroRegistros == null)
                            const Padding(padding: EdgeInsets.all(12), child: Text('Nenhum registro encontrado.')),
                          if (secao == 'Eventos')
                            EventosPorPeriodo<Map<String, dynamic>>(
                              itens: visiveis,
                              inicio: (d) => DateTime.tryParse('${d['dataInicio'] ?? ''}'),
                              fim: (d) => DateTime.tryParse('${d['dataFim'] ?? ''}'),
                              construir: (d) => Card(child: ListTile(
                                leading: const Icon(Icons.event_outlined),
                                title: Text('${d['titulo'] ?? d['nome'] ?? 'Evento'}'),
                                subtitle: Text('Cidade: ${d['cidade'] ?? '-'}\nSituação: ${d['status'] ?? d['statusEvento'] ?? '-'} • ID: ${d['id'] ?? '-'}'),
                                trailing: permissoes['moderarEventos'] == true && '${d['status'] ?? d['statusEvento'] ?? ''}' != 'REMOVIDO_ADMIN' ? IconButton(tooltip: 'Remover evento', icon: const Icon(Icons.report_outlined), onPressed: () => _confirmarRemocao(d)) : null,
                              )),
                            )
                          else
                            for (final d in visiveis)
                              Card(child: ListTile(
                                leading: const Icon(Icons.person_outline),
                                title: Text('${d['nome'] ?? 'Usuário'}'),
                                subtitle: Text('E-mail: ${d['email'] ?? '-'}\nPerfil: ${d['perfil'] ?? '-'} • Situação: ${d['ativo'] == false ? 'Bloqueado' : 'Ativo'}'),
                                trailing: permissoes['bloquearUsuarios'] == true ? IconButton(tooltip: d['ativo'] == false ? 'Desbloquear' : 'Bloquear', icon: Icon(d['ativo'] == false ? Icons.lock_open_outlined : Icons.lock_outline), onPressed: () => _confirmarBloqueio(d)) : null,
                              )),
                        ]);
                      }),
                    ],
                    const Text('Ações de pagamentos e planos ainda exigem endpoints específicos e continuam indisponíveis.'),
                  ],
                ),
    );
  }
}

class _FuncionarioLifecycleObserver extends WidgetsBindingObserver {
  final VoidCallback aoRetornar;
  _FuncionarioLifecycleObserver(this.aoRetornar);
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) aoRetornar();
  }
}

import '../../widgets/eventos_por_periodo.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/admin_service.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});
  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final api = AdminService();
  Timer? _timer;
  String pesquisa = '';
  String filtroPerfil = 'Todos';
  bool _consultando = false;
  List<Map<String, dynamic>> resumoUsuarios = [];
  List<Map<String, dynamic>> resumoEventos = [];
  bool resumoCarregando = false;
  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  bool? autorizado;
  int aba = 0;
  bool carregando = false;
  String? erro;
  List<Map<String, dynamic>> dados = [];

  @override
  void initState() {
    super.initState();
    _verificar();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (autorizado == true && WidgetsBinding.instance.lifecycleState != AppLifecycleState.paused) {
        if (aba == 0) { _carregarResumo(); } else { carregar(silencioso: true); }
      }
    });
  }
  Future<void> _verificar() async {
    final prefs = await SharedPreferences.getInstance();
    final ok = (prefs.getString('perfil') ?? '').trim().toUpperCase() == 'ADMIN' &&
        (prefs.getString('token') ?? '').isNotEmpty;
    if (!mounted) return;
    setState(() => autorizado = ok);
    if (ok) { await _carregarResumo(); await carregar(); }
  }

  Future<void> _carregarResumo() async {
    if (!mounted || resumoCarregando) return;
    setState(() => resumoCarregando = true);
    try {
      final usuarios = await api.usuarios();
      final eventos = await api.eventos();
      if (mounted) setState(() { resumoUsuarios = usuarios; resumoEventos = eventos; });
    } catch (_) { // As demais abas continuam disponíveis em falhas parciais.
    } finally {
      if (mounted) setState(() => resumoCarregando = false);
    }
  }

  void _abrirAba(int indice, {String perfil = 'Todos'}) {
    setState(() { aba = indice; filtroPerfil = perfil; pesquisa = ''; });
    if (indice != 0) carregar();
  }

  Widget _indicador(String titulo, int valor, IconData icone, Color cor) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(.55)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(padding: const EdgeInsets.all(9), decoration: BoxDecoration(
          color: cor.withOpacity(.10), borderRadius: BorderRadius.circular(11)),
          child: Icon(icone, color: cor, size: 20)),
        const Spacer(),
        Text('$valor', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 3),
        Text(titulo, maxLines: 1, overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ]),
    );
  }

  Widget _secaoTitulo(String titulo, {String? subtitulo}) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(titulo, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
      if (subtitulo != null) ...[
        const SizedBox(height: 4),
        Text(subtitulo, style: Theme.of(context).textTheme.bodySmall),
      ],
    ]),
  );

  Widget _painel(Widget child) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(.55)),
    ),
    child: child,
  );

  Widget _linhaResumo(String nome, String valor, {Color? cor}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(children: [
      Expanded(child: Text(nome, style: Theme.of(context).textTheme.bodyMedium)),
      Text(valor, style: TextStyle(fontWeight: FontWeight.w700, color: cor)),
    ]),
  );

  Widget _visaoGeral() {
    final tema = Theme.of(context);
    final cores = tema.colorScheme;
    final funcionarios = resumoUsuarios.where((u) =>
      (u['perfil'] ?? '').toString().toUpperCase() == 'FUNCIONARIO').length;
    final bloqueados = resumoUsuarios.where((u) => u['ativo'] == false).length;
    final ativos = resumoUsuarios.where((u) => u['ativo'] == true).length;
    final admins = resumoUsuarios.where((u) =>
      (u['perfil'] ?? '').toString().toUpperCase() == 'ADMIN').length;
    final comuns = resumoUsuarios.where((u) =>
      (u['perfil'] ?? '').toString().toUpperCase() == 'USUARIO').length;
    final periodos = <PeriodoEvento, int>{for (final p in PeriodoEvento.values) p: 0};
    for (final evento in resumoEventos) {
      final periodo = periodoEvento(_dataEvento(evento, 'dataInicio'), _dataEvento(evento, 'dataFim'));
      periodos[periodo] = periodos[periodo]! + 1;
    }
    final statusEventos = <String, int>{};
    for (final evento in resumoEventos) {
      final status = (evento['status'] ?? evento['statusEvento'] ?? 'Não informado').toString();
      statusEventos[status] = (statusEventos[status] ?? 0) + 1;
    }
    return RefreshIndicator(onRefresh: _carregarResumo, child: ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [cores.primary, cores.primary.withOpacity(.78)]),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.shield_outlined, color: Colors.white, size: 28),
            const SizedBox(height: 14),
            const Text('Central administrativa', style: TextStyle(color: Colors.white,
              fontSize: 23, fontWeight: FontWeight.w800)),
            const SizedBox(height: 7),
            Text('Acompanhe a plataforma e gerencie os registros em um só lugar.',
              style: TextStyle(color: Colors.white.withOpacity(.90), height: 1.35)),
          ]),
        ),
        const SizedBox(height: 20),
        _secaoTitulo('Indicadores da plataforma', subtitulo: 'Totais obtidos dos registros disponíveis na API.'),
        if (resumoCarregando) ...[const LinearProgressIndicator(), const SizedBox(height: 12)],
        LayoutBuilder(builder: (context, constraints) => GridView.count(
          crossAxisCount: constraints.maxWidth >= 680 ? 4 : 2,
          mainAxisSpacing: 10, crossAxisSpacing: 10,
          childAspectRatio: constraints.maxWidth >= 680 ? 1.65 : 1.25,
          shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          children: [
            _indicador('Usuários', resumoUsuarios.length, Icons.groups_outlined, cores.primary),
            _indicador('Eventos', resumoEventos.length, Icons.event_note_outlined, cores.tertiary),
            _indicador('Funcionários', funcionarios, Icons.badge_outlined, cores.primary),
            _indicador('Bloqueados', bloqueados, Icons.person_off_outlined, cores.error),
          ],
        )),
        const SizedBox(height: 22),
        _secaoTitulo('Contas e acessos'),
        _painel(Column(children: [
          _linhaResumo('Contas ativas', '$ativos', cor: cores.primary),
          const Divider(height: 1),
          _linhaResumo('Contas bloqueadas', '$bloqueados', cor: cores.error),
          const Divider(height: 1),
          _linhaResumo('Usuários comuns', '$comuns'),
          const Divider(height: 1),
          _linhaResumo('Funcionários', '$funcionarios'),
          const Divider(height: 1),
          _linhaResumo('Administradores', '$admins'),
          const Divider(height: 1),
          _linhaResumo('Status não informado', '${resumoUsuarios.length - ativos - bloqueados}'),
        ])),
        const SizedBox(height: 22),
        _secaoTitulo('Eventos por período', subtitulo: 'Classificação automática pelas datas de início e término.'),
        _painel(Column(children: [
          _linhaResumo('Próximos', '${periodos[PeriodoEvento.proximos]}'),
          const Divider(height: 1),
          _linhaResumo('Em andamento', '${periodos[PeriodoEvento.andamento]}'),
          const Divider(height: 1),
          _linhaResumo('Encerrados', '${periodos[PeriodoEvento.encerrados]}'),
          const Divider(height: 1),
          _linhaResumo('Sem datas válidas', '${periodos[PeriodoEvento.semData]}'),
        ])),
        const SizedBox(height: 22),
        _secaoTitulo('Situação administrativa dos eventos'),
        _painel(Column(children: [
          _linhaResumo('Total de eventos', '${resumoEventos.length}'),
          for (final entry in statusEventos.entries) ...[
            const Divider(height: 1),
            _linhaResumo(entry.key, '${entry.value}'),
          ],
          if (statusEventos.isEmpty) const Padding(
            padding: EdgeInsets.only(top: 8), child: Text('Nenhum evento retornado pela API.')),
        ])),
        const SizedBox(height: 22),
        _secaoTitulo('Acesso rápido', subtitulo: 'Escolha a área que deseja administrar.'),
        _painel(Column(children: [
          _atalho(Icons.people_outline, 'Usuários', 'Contas, bloqueios e informações', () => _abrirAba(1)),
          const Divider(height: 1),
          _atalho(Icons.badge_outlined, 'Funcionários', 'Perfis e permissões', () => _abrirAba(1, perfil: 'FUNCIONARIO')),
          const Divider(height: 1),
          _atalho(Icons.event_outlined, 'Eventos', 'Dados e moderação', () => _abrirAba(2)),
          const Divider(height: 1),
          _atalho(Icons.history_outlined, 'Histórico', 'Ações administrativas registradas', () => _abrirAba(3)),
        ])),
      ],
    ));
  }

  Widget _atalho(IconData icone, String titulo, String descricao, VoidCallback acao) =>
    ListTile(contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: Icon(icone, color: Theme.of(context).colorScheme.onPrimaryContainer)),
      title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(descricao), trailing: const Icon(Icons.chevron_right), onTap: acao);

  Future<void> carregar({bool silencioso = false}) async {
    if (_consultando || !mounted || aba == 0) return;
    _consultando = true;
    if (!silencioso) setState(() { carregando = true; erro = null; });
    try {
      final resultado = aba == 1 ? await api.usuarios() :
          aba == 2 ? await api.eventos() : await api.historico();
      if (mounted) setState(() => dados = resultado);
    } catch (e) {
      if (mounted && !silencioso) setState(() { dados = []; erro = e.toString().replaceFirst('Exception: ', ''); });
    } finally {
      _consultando = false;
      if (mounted && !silencioso) setState(() => carregando = false);
    }
  }

  Future<bool> confirmar(String titulo, String mensagem) async =>
      await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
        title: Text(titulo), content: Text(mensagem), actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirmar')),
        ])) ?? false;

  Future<void> executar(Future<void> Function() acao) async {
    try {
      await acao();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Operação concluída.')));
      await carregar();
      await _carregarResumo();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    }
  }

  Future<void> promover(int id) async {
    final nomes = <String, String>{
      'visualizarUsuarios': 'Visualizar usuários',
      'bloquearUsuarios': 'Bloquear usuários',
      'visualizarEventos': 'Visualizar eventos',
      'moderarEventos': 'Moderar eventos',
      'visualizarPagamentos': 'Visualizar pagamentos',
      'gerenciarPlanos': 'Gerenciar planos',
    };
    final permissoes = {for (final chave in nomes.keys) chave: false};
    final aprovado = await showDialog<bool>(context: context, builder: (ctx) => StatefulBuilder(
      builder: (ctx, atualizar) => AlertDialog(
        title: const Text('Permissões do funcionário'),
        content: SizedBox(width: 360, child: SingleChildScrollView(child: Column(
          mainAxisSize: MainAxisSize.min,
          children: nomes.entries.map((item) => CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(item.value, style: const TextStyle(fontSize: 14)),
            value: permissoes[item.key],
            onChanged: (v) => atualizar(() => permissoes[item.key] = v ?? false),
          )).toList(),
        ))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Salvar')),
        ],
      ),
    ));
    if (aprovado == true) await executar(() => api.tornarFuncionario(id, permissoes));
  }

  Future<void> remover(int id) async {
    final controller = TextEditingController();
    final motivo = await showDialog<String>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Remover evento'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('Esta ação remove o evento administrativamente. Informe a justificativa.'),
        const SizedBox(height: 12),
        TextField(controller: controller, maxLines: 3, maxLength: 300,
          decoration: const InputDecoration(labelText: 'Motivo obrigatório')),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
        FilledButton(onPressed: () {
          final texto = controller.text.trim();
          if (texto.length >= 10) Navigator.pop(ctx, texto);
        }, child: const Text('Remover')),
      ],
    ));
    // Não descartar o controller enquanto o diálogo ainda executa animações.
    if (motivo != null && mounted && await confirmar('Confirmar remoção', 'Remover o evento #$id?')) {
      await executar(() => api.removerEvento(id, motivo));
    }
  }

  void _mostrarDetalhes(Map<String, dynamic> registro) {
    final campos = registro.entries.where((e) => e.value != null).toList();
    showDialog<void>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Informações do registro'),
      content: SizedBox(width: 480, child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
          children: campos.map((campo) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(campo.key, style: Theme.of(ctx).textTheme.labelMedium),
              SelectableText('${campo.value}'),
            ]),
          )).toList(),
        ),
      )),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fechar'))],
    ));
  }

  Widget item(Map<String, dynamic> d) {
    final id = (d['id'] as num?)?.toInt();
    final cores = Theme.of(context).colorScheme;
    if (aba == 1) {
      final ativo = d['ativo'] == true;
      final perfil = (d['perfil'] ?? '').toString();
      return Padding(padding: const EdgeInsets.only(bottom: 10), child: _painel(Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(backgroundColor: cores.primaryContainer,
              child: Icon(Icons.person_outline, color: cores.onPrimaryContainer)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${d['nome'] ?? 'Usuário'}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              Text('${d['email'] ?? 'E-mail não informado'}',
                maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
            ])),
            _status(ativo ? 'Ativo' : 'Bloqueado', ativo ? cores.primary : cores.error),
          ]),
          const SizedBox(height: 14),
          Text('Perfil: $perfil   •   ID: ${id ?? '-'}', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          TextButton.icon(onPressed: () => _mostrarDetalhes(d),
            icon: const Icon(Icons.open_in_new, size: 17), label: const Text('Ver detalhes')),
          if (id != null) Wrap(spacing: 8, runSpacing: 4, children: [
            OutlinedButton.icon(onPressed: () async {
              if (await confirmar(ativo ? 'Bloquear usuário?' : 'Desbloquear usuário?', 'Usuário #$id')) {
                await executar(() => ativo ? api.bloquear(id) : api.desbloquear(id));
              }
            }, icon: Icon(ativo ? Icons.block : Icons.lock_open, size: 17),
              label: Text(ativo ? 'Bloquear' : 'Desbloquear')),
            if (perfil.toUpperCase() != 'ADMIN')
              OutlinedButton.icon(onPressed: () => promover(id),
                icon: const Icon(Icons.badge_outlined, size: 17), label: const Text('Funcionário')),
          ]),
        ],
      )));
    }
    if (aba == 2) {
      final titulo = d['titulo'] ?? d['nome'] ?? 'Evento';
      final status = d['status'] ?? d['statusEvento'] ?? 'Não informado';
      return Padding(padding: const EdgeInsets.only(bottom: 10), child: _painel(Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(backgroundColor: cores.tertiaryContainer,
              child: Icon(Icons.event_outlined, color: cores.onTertiaryContainer)),
            const SizedBox(width: 12),
            Expanded(child: Text('$titulo', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
          ]),
          const SizedBox(height: 10),
          Text('ID: ${id ?? '-'}  •  Situação: $status', style: Theme.of(context).textTheme.bodySmall),
          if (d['tipo'] != null) _detalheLinha(Icons.category_outlined, 'Tipo: ${d['tipo']}'),
          if (d['dataInicio'] != null) _detalheLinha(Icons.calendar_today_outlined, 'Início: ${d['dataInicio']}'),
          if (d['cidade'] != null) _detalheLinha(Icons.place_outlined, '${d['cidade']}'),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 4, children: [
            TextButton.icon(onPressed: () => _mostrarDetalhes(d),
              icon: const Icon(Icons.open_in_new, size: 17), label: const Text('Ver detalhes')),
            if (id != null && status.toString().toUpperCase() != 'REMOVIDO_ADMIN')
              OutlinedButton.icon(onPressed: () => remover(id),
                icon: const Icon(Icons.remove_circle_outline, size: 17), label: const Text('Remover evento')),
          ]),
        ],
      )));
    }
    return Padding(padding: const EdgeInsets.only(bottom: 10), child: _painel(
      ListTile(contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(backgroundColor: cores.primaryContainer,
          child: Icon(Icons.history, color: cores.onPrimaryContainer)),
        title: Text('${d['acao'] ?? 'Ação administrativa'}', style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text('${d['descricao'] ?? ''}\nPor: ${d['usuarioNome'] ?? '-'}  •  ${d['dataAcao'] ?? ''}'),
        isThreeLine: true, trailing: const Icon(Icons.chevron_right),
        onTap: () => _mostrarDetalhes(d),
      )));
  }

  Widget _status(String texto, Color cor) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(color: cor.withOpacity(.10), borderRadius: BorderRadius.circular(30)),
    child: Text(texto, style: TextStyle(color: cor, fontWeight: FontWeight.w700, fontSize: 11)));

  Widget _detalheLinha(IconData icone, String texto) => Padding(
    padding: const EdgeInsets.only(top: 7),
    child: Row(children: [Icon(icone, size: 15, color: Theme.of(context).colorScheme.onSurfaceVariant),
      const SizedBox(width: 7), Expanded(child: Text(texto, style: Theme.of(context).textTheme.bodySmall))]));

  DateTime? _dataEvento(Map<String, dynamic> dados, String campo) {
    final valor = dados[campo];
    if (valor == null) return null;
    return DateTime.tryParse(valor.toString());
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Administração'), actions: [
      PopupMenuButton<int>(
        tooltip: 'Abrir seção administrativa',
        icon: const Icon(Icons.menu),
        onSelected: (indice) => _abrirAba(indice),
        itemBuilder: (_) => const [
          PopupMenuItem(value: 0, child: Text('Início')),
          PopupMenuItem(value: 1, child: Text('Usuários')),
          PopupMenuItem(value: 2, child: Text('Eventos')),
          PopupMenuItem(value: 3, child: Text('Histórico')),
        ],
      ),
      IconButton(onPressed: autorizado == true ? () { if (aba == 0) { _carregarResumo(); } else { carregar(); } } : null,
        tooltip: 'Atualizar', icon: const Icon(Icons.refresh)),
    ]),
    body: autorizado == null
      ? const Center(child: CircularProgressIndicator())
      : autorizado == false
        ? const Center(child: Text('Acesso restrito a administradores.'))
        : Column(children: [
            Expanded(child: aba == 0 ? _visaoGeral() : Column(children: [
              Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: TextField(
                key: ValueKey(aba),
                decoration: const InputDecoration(prefixIcon: Icon(Icons.search),
                  hintText: 'Buscar por nome, e-mail, cidade ou evento', isDense: true,
                  border: OutlineInputBorder()),
                onChanged: (v) => setState(() => pesquisa = v.trim().toLowerCase()),
              )),
              if (aba == 1) Padding(padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Wrap(spacing: 6, children: ['Todos', 'USUARIO', 'FUNCIONARIO', 'ADMIN']
                  .map((v) => ChoiceChip(label: Text(v), selected: filtroPerfil == v,
                    onSelected: (_) => setState(() => filtroPerfil = v))).toList())),
              Expanded(child: carregando
                ? const Center(child: CircularProgressIndicator())
                : erro != null
                  ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Text(erro!, textAlign: TextAlign.center),
                      TextButton(onPressed: carregar, child: const Text('Tentar novamente')),
                    ]))
                  : Builder(builder: (context) {
                      final filtrados = dados.where((d) {
                        final texto = d.values.join(' ').toLowerCase();
                        final perfilOk = aba != 1 || filtroPerfil == 'Todos' ||
                            (d['perfil'] ?? '').toString().toUpperCase() == filtroPerfil;
                        return perfilOk && texto.contains(pesquisa);
                      }).toList();
                      return RefreshIndicator(onRefresh: () => carregar(), child: filtrados.isEmpty
                        ? ListView(children: const [Padding(padding: EdgeInsets.all(24),
                            child: Center(child: Text('Nenhum registro encontrado.')))])
                         : aba == 2
                        ? ListView(padding: const EdgeInsets.fromLTRB(12, 8, 12, 20), children: [
                            EventosPorPeriodo<Map<String, dynamic>>(
                              itens: filtrados,
                              inicio: (d) => _dataEvento(d, 'dataInicio'),
                              fim: (d) => _dataEvento(d, 'dataFim'),
                              construir: item,
                            ),
                          ])
                        : ListView.builder(padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
                            itemCount: filtrados.length, itemBuilder: (_, i) => item(filtrados[i])));
                    })),
            ])),
          ]),
  );
}

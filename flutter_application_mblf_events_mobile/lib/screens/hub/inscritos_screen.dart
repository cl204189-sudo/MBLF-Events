import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/inscricao.dart';
import '../../services/inscricao_evento_service.dart';

class InscritosScreen extends StatefulWidget {
  final int eventoId;
  final String eventoTitulo;
  const InscritosScreen({super.key, required this.eventoId, required this.eventoTitulo});

  @override
  State<InscritosScreen> createState() => _InscritosScreenState();
}

class _InscritosScreenState extends State<InscritosScreen> with WidgetsBindingObserver {
  final service = InscricaoEventoService();
  final buscaController = TextEditingController();
  List<Inscricao> inscritos = [];
  bool carregando = true;
  bool buscando = false;
  bool ativo = true;
  String? erro;
  String filtro = 'Todos';
  Timer? timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    carregar();
    timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (ativo) carregar(silencioso: true);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    ativo = state == AppLifecycleState.resumed;
    if (ativo) carregar(silencioso: true);
  }

  @override
  void dispose() {
    timer?.cancel();
    buscaController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  bool _cancelada(Inscricao i) => i.status.toUpperCase().startsWith('CANCELAD');
  bool _presente(Inscricao i) => i.status.toUpperCase() == 'PRESENTE';

  Future<void> carregar({bool silencioso = false}) async {
    if (buscando) return;
    buscando = true;
    if (!silencioso && mounted) setState(() { carregando = true; erro = null; });
    try {
      final lista = await service.listarPorEvento(widget.eventoId);
      if (!mounted) return;
      setState(() { inscritos = lista; erro = null; });
    } catch (e) {
      if (!mounted) return;
      if (!silencioso) {
        setState(() { erro = e.toString().replaceFirst('Exception: ', ''); });
      }
    } finally {
      buscando = false;
      if (mounted && carregando) setState(() => carregando = false);
    }
  }

  Future<void> editarPresenca(Inscricao i) async {
    if (_cancelada(i)) return;
    final presente = !_presente(i);
    final motivo = TextEditingController();
    final confirmar = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: Text(presente ? 'Registrar presença manual?' : 'Remover presença?'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('Participante: ${i.usuarioNome}. Esta alteração será registrada para auditoria.'),
        const SizedBox(height: 12),
        TextField(controller: motivo, maxLength: 500, maxLines: 2,
          decoration: const InputDecoration(labelText: 'Motivo obrigatório (mín. 5 caracteres)')),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Voltar')),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirmar')),
      ],
    ));
    final texto = motivo.text.trim();
    motivo.dispose();
    if (confirmar != true) return;
    if (texto.length < 5) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe um motivo com pelo menos 5 caracteres.')));
      return;
    }
    try {
      await service.alterarPresencaManual(eventoId: widget.eventoId,
        inscricaoId: i.id, presente: presente, motivo: texto);
      await carregar();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Presença atualizada.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final ativos = inscritos.where((i) => !_cancelada(i)).toList();
    final presentes = ativos.where(_presente).length;
    final cancelados = inscritos.length - ativos.length;
    final pesquisa = buscaController.text.trim().toLowerCase();
    final exibidos = inscritos.where((i) {
      if (filtro == 'Presentes' && !_presente(i)) return false;
      if (filtro == 'Pendentes' && (_presente(i) || _cancelada(i))) return false;
      if (filtro == 'Cancelados' && !_cancelada(i)) return false;
      return pesquisa.isEmpty ||
          i.usuarioNome.toLowerCase().contains(pesquisa) ||
          i.id.toString().contains(pesquisa);
    }).toList()
      ..sort((a, b) => a.usuarioNome.toLowerCase().compareTo(b.usuarioNome.toLowerCase()));
    final cores = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciar participantes'),
        actions: [
          IconButton(
            onPressed: buscando ? null : () => carregar(),
            tooltip: 'Atualizar participantes',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: carregar,
        child: carregando
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                Text(widget.eventoTitulo, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(child: _resumo('Ativos', ativos.length, Icons.people_outline)),
                  const SizedBox(width: 8),
                  Expanded(child: _resumo('Presentes', presentes, Icons.check_circle_outline)),
                  const SizedBox(width: 8),
                  Expanded(child: _resumo('Cancelados', cancelados, Icons.person_off_outlined)),
                ]),
                const SizedBox(height: 18),
                TextField(
                  controller: buscaController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Buscar nome ou número da inscrição',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    suffixIcon: pesquisa.isEmpty ? null : IconButton(
                      tooltip: 'Limpar pesquisa',
                      icon: const Icon(Icons.close),
                      onPressed: () { buscaController.clear(); setState(() {}); },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: ['Todos', 'Presentes', 'Pendentes', 'Cancelados'].map((item) =>
                    Padding(
                      padding: const EdgeInsets.only(right: 7),
                      child: ChoiceChip(
                        label: Text(item),
                        selected: filtro == item,
                        onSelected: (_) => setState(() => filtro = item),
                      ),
                    ),
                  ).toList()),
                ),
                const SizedBox(height: 12),
                Text('${exibidos.length} resultado(s)', style: TextStyle(color: cores.onSurfaceVariant)),
                if (erro != null) ...[
                  const SizedBox(height: 12),
                  Text(erro!, style: TextStyle(color: cores.error)),
                  TextButton(onPressed: carregar, child: const Text('Tentar novamente')),
                ],
                const SizedBox(height: 8),
                if (exibidos.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(28),
                    child: Center(child: Text('Nenhum participante encontrado.')),
                  )
                else
                  ...exibidos.map((i) => Card(
                    child: ListTile(
                      leading: CircleAvatar(child: Text(
                        i.usuarioNome.isEmpty ? '?' : i.usuarioNome[0].toUpperCase(),
                      )),
                      title: Text(i.usuarioNome.isEmpty ? 'Participante #${i.usuarioId}' : i.usuarioNome),
                      subtitle: Text('Inscrição #${i.id} • ${i.dataInscricao == null ? "Data não informada" : "${i.dataInscricao!.day.toString().padLeft(2, '0')}/${i.dataInscricao!.month.toString().padLeft(2, '0')}/${i.dataInscricao!.year}"}'),
                      trailing: _status(i),
                      onTap: () => showDialog<void>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(i.usuarioNome.isEmpty ? 'Participante' : i.usuarioNome),
                          content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('Inscrição: #${i.id}'),
                            Text('Situação: ${i.status}'),
                            Text('ID do participante: ${i.usuarioId}'),
                            if (i.dataInscricao != null) Text('Inscrito em: ${i.dataInscricao!.day}/${i.dataInscricao!.month}/${i.dataInscricao!.year}'),
                            if (i.dataCancelamento != null) Text('Cancelado em: ${i.dataCancelamento!.day}/${i.dataCancelamento!.month}/${i.dataCancelamento!.year}'),
                          ]),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fechar')),
                            if (!_cancelada(i)) TextButton.icon(
                              icon: const Icon(Icons.fact_check_outlined),
                              label: Text(_presente(i) ? 'Remover presença' : 'Registrar presença'),
                              onPressed: () { Navigator.pop(context); editarPresenca(i); },
                            ),
                          ],
                        ),
                      ),
                    ),
                  )),
              ],
            ),
      ),
    );
  }

  Widget _resumo(String titulo, int valor, IconData icone) => Card(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
      child: Column(children: [
        Icon(icone, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 8),
        Text('$valor', style: const TextStyle(fontSize: 23, fontWeight: FontWeight.bold)),
        Text(titulo, style: const TextStyle(fontSize: 11)),
      ]),
    ),
  );

  Widget _status(Inscricao i) {
    final cor = _cancelada(i) ? Theme.of(context).colorScheme.error
      : _presente(i) ? Colors.green : Theme.of(context).colorScheme.primary;
    return Text(
      _cancelada(i) ? 'Cancelado' : _presente(i) ? 'Presente' : 'Pendente',
      style: TextStyle(color: cor, fontWeight: FontWeight.w600, fontSize: 12),
    );
  }
}

import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../../config/api_config.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';

import '../../config/app_theme.dart';
import '../../services/criar_evento_service.dart';
import '../../models/evento.dart';

class CriarEventoScreen
    extends StatefulWidget {

  final Evento? evento;

  const CriarEventoScreen({
    super.key,
    this.evento,
  });

  @override
  State<CriarEventoScreen>
      createState() =>
          _CriarEventoScreenState();
}

class _CriarEventoScreenState
    extends State<CriarEventoScreen> {

  final service =
      CriarEventoService();

  final tituloController =
      TextEditingController();

  final descricaoController =
      TextEditingController();

  final tipoController =
      TextEditingController();

  final enderecoController =
      TextEditingController();

  final cidadeController =
      TextEditingController();

  final vagasController =
      TextEditingController();

  final cargaController =
      TextEditingController();

  DateTime? inicio;
  DateTime? fim;

  bool carregando = false;
  XFile? imagemSelecionada;

  Future<void> escolherImagem() async {
    try {
      final arquivo = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 80,
      );
      if (arquivo != null && mounted) {
        if ((await arquivo.length()) > 5 * 1024 * 1024) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('A imagem deve ter até 5 MB.')),
          );
          return;
        }
        setState(() => imagemSelecionada = arquivo);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível selecionar a imagem: $e')),
      );
    }
  }

  final _formKey = GlobalKey<FormState>();
  bool _datasValidadas = false;

  String? _validarTexto(
    String? valor,
    String campo, {
    required int minimo,
    required int maximo,
    bool exigirLetras = true,
    bool cidade = false,
  }) {
    final texto = (valor ?? '').trim();
    if (texto.isEmpty) return 'Informe $campo.';
    if (texto.length < minimo) return 'Use pelo menos $minimo caracteres.';
    if (texto.length > maximo) return 'Use no máximo $maximo caracteres.';
    if (RegExp(r'\s{2,}').hasMatch(texto)) {
      return 'Evite espaços repetidos.';
    }
    if (exigirLetras && !RegExp(r'[A-Za-zÀ-ÖØ-öø-ÿ]').hasMatch(texto)) {
      return 'Informe um texto válido, não apenas números ou símbolos.';
    }
    if (cidade && !RegExp(r"^[A-Za-zÀ-ÖØ-öø-ÿ\s.'’\\-]+$").hasMatch(texto)) {
      return 'A cidade não deve conter números ou símbolos especiais.';
    }
    return null;
  }

  String? _validarNumero(String? valor, String campo, int maximo) {
    final texto = (valor ?? '').trim();
    if (texto.isEmpty) return 'Informe $campo.';
    if (!RegExp(r'^\d+$').hasMatch(texto)) {
      return 'Use apenas números inteiros.';
    }
    final numero = int.tryParse(texto);
    if (numero == null || numero < 1 || numero > maximo) {
      return 'Informe um valor entre 1 e $maximo.';
    }
    return null;
  }

  String? _erroDataInicio() {
    if (inicio == null) return 'Selecione o início do evento.';
    // Na edição, um evento existente pode ter começado no passado.
    if (!modoEdicao && !inicio!.isAfter(DateTime.now())) {
      return 'O início precisa ser no futuro.';
    }
    return null;
  }

  String? _erroDataFim() {
    if (fim == null) return 'Selecione o término do evento.';
    if (inicio != null) {
      final duracao = fim!.difference(inicio!);
      if (duracao < const Duration(minutes: 15)) {
        return 'O evento deve durar pelo menos 15 minutos.';
      }
    }
    return null;
  }

  bool get modoEdicao => widget.evento != null;

  @override
  void initState() {
    super.initState();
    final evento = widget.evento;
    if (evento != null) {
      tituloController.text = evento.titulo;
      descricaoController.text = evento.descricao;
      tipoController.text = evento.tipo;
      enderecoController.text = evento.endereco;
      cidadeController.text = evento.cidade;
      vagasController.text = (evento.vagasTotal ?? evento.vagasDisponiveis ?? 0).toString();
      cargaController.text = (evento.cargaHoraria ?? 0).toString();
      inicio = evento.dataInicio;
      fim = evento.dataFim;
    }
  }

  Future<DateTime?> escolherDataHora(
    DateTime? atual,
  ) async {

    final agora =
        DateTime.now();

    final data =
        await showDatePicker(
      context: context,
      initialDate:
          atual ??
              agora.add(
                const Duration(days: 1),
              ),
      firstDate: atual != null && atual.isBefore(agora)
          ? DateTime(2000)
          : DateTime(agora.year, agora.month, agora.day),
      lastDate: DateTime(2035),
    );

    if (data == null ||
        !mounted) {
      return null;
    }

    final hora =
        await showTimePicker(
      context: context,
      initialTime:
          atual != null
              ? TimeOfDay.fromDateTime(
                  atual,
                )
              : const TimeOfDay(
                  hour: 9,
                  minute: 0,
                ),
    );

    if (hora == null) {
      return null;
    }

    return DateTime(
      data.year,
      data.month,
      data.day,
      hora.hour,
      hora.minute,
    );
  }

  Future<void> criar() async {

    setState(() => _datasValidadas = true);
    final formularioValido = _formKey.currentState?.validate() ?? false;
    final datasValidas = _erroDataInicio() == null && _erroDataFim() == null;
    if (!formularioValido || !datasValidas) return;

    // Após a validação, ambos são inteiros válidos e não nulos.
    final int vagas = int.parse(vagasController.text.trim());
    final int carga = int.parse(cargaController.text.trim());

    setState(() {
      carregando = true;
    });

    try {

      late final Map<String, dynamic> resultado;
      if (modoEdicao) {
        resultado = await service.atualizar(
          id: widget.evento!.id,
          titulo: tituloController.text.trim(),
          descricao: descricaoController.text.trim(),
          tipo: tipoController.text.trim(),
          endereco: enderecoController.text.trim(),
          cidade: cidadeController.text.trim(),
          dataInicio: inicio!,
          dataFim: fim!,
          cargaHoraria: carga,
          vagasTotal: vagas,
        );
      } else {
        resultado = await service.criar(
        titulo:
            tituloController.text.trim(),
        descricao:
            descricaoController.text.trim(),
        tipo:
            tipoController.text.trim(),
        endereco:
            enderecoController.text.trim(),
        cidade:
            cidadeController.text.trim(),
        dataInicio: inicio!,
        dataFim: fim!,
        cargaHoraria: carga,
        vagasTotal: vagas,
        );
      }

      if (imagemSelecionada != null) {
        final id = modoEdicao ? widget.evento!.id : resultado['id'];
        if (id is! int) {
          throw Exception('Evento salvo, mas não foi possível identificar o ID para enviar a imagem.');
        }
        try {
          await service.enviarImagem(eventoId: id, imagem: imagemSelecionada!);
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Evento salvo, mas a imagem não foi enviada: $e')),
          );
          Navigator.pop(context, true);
          return;
        }
      }
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            modoEdicao ? 'Evento atualizado com sucesso!' : 'Evento criado com sucesso!',
          ),
        ),
      );

      Navigator.pop(
        context,
        true,
      );

    } catch (erro) {

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (_) =>
            AlertDialog(
          title: Text(modoEdicao ? 'Não foi possível atualizar' : 'Não foi possível criar'),
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
                Navigator.pop(
                  context,
                );
              },
              child: const Text(
                'Entendi',
              ),
            ),
          ],
        ),
      );

    } finally {

      if (mounted) {
        setState(() {
          carregando = false;
        });
      }
    }
  }

  @override
  void dispose() {
    tituloController.dispose();
    descricaoController.dispose();
    tipoController.dispose();
    enderecoController.dispose();
    cidadeController.dispose();
    vagasController.dispose();
    cargaController.dispose();

    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) {

    return Scaffold(
      appBar: AppBar(
        title: Text(
          modoEdicao ? 'Editar evento' : 'Criar evento',
          style: TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ),

      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
        padding:
            const EdgeInsets.all(20),
        children: [

          Container(
            padding:
                const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient:
                  AppTheme.gradientePrincipal,
              borderRadius:
                  BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.event_available,
                  color: Colors.white,
                  size: 35,
                ),

                SizedBox(height: 12),

                Text(
                  modoEdicao ? 'Editar evento' : 'Novo evento',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                SizedBox(height: 5),

                Text(
                  modoEdicao
                      ? 'Atualize os dados do evento e salve as alterações.'
                      : 'O evento será criado como rascunho. Depois você poderá ativar publicação, HUB e inscrições.',
                  style: TextStyle(
                    color:
                        Colors.white70,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 25),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Imagem de capa do evento',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  if (imagemSelecionada != null)
                    FutureBuilder<List<int>>(
                      future: imagemSelecionada!.readAsBytes(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const LinearProgressIndicator();
                        return Image.memory(
                          Uint8List.fromList(snapshot.data!),
                          height: 160, fit: BoxFit.cover,
                        );
                      },
                    )
                  else if (widget.evento?.imagemUrl != null)
                    Image.network(
                      '${ApiConfig.baseUrl}${widget.evento!.imagemUrl}',
                      height: 160, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported_outlined),
                    )
                  else
                    const SizedBox(height: 90,
                      child: Center(child: Icon(Icons.add_photo_alternate_outlined, size: 48))),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: carregando ? null : escolherImagem,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Selecionar imagem (JPG/PNG, até 5 MB)'),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 18),

          TextFormField(
            controller: tituloController,
            validator: (v) => _validarTexto(v, 'o título', minimo: 5, maximo: 100),
            decoration:
                const InputDecoration(
              labelText:
                  'Título do evento',
              prefixIcon: Icon(
                Icons.title,
              ),
            ),
          ),

          const SizedBox(height: 14),

          TextFormField(
            controller: descricaoController,
            validator: (v) => _validarTexto(v, 'a descrição', minimo: 20, maximo: 2000),
            maxLines: 4,
            decoration:
                const InputDecoration(
              labelText: 'Descrição',
              prefixIcon: Icon(
                Icons.description_outlined,
              ),
            ),
          ),

          const SizedBox(height: 14),

          TextFormField(
            controller: tipoController,
            validator: (v) => _validarTexto(v, 'o tipo do evento', minimo: 3, maximo: 40),
            decoration:
                const InputDecoration(
              labelText:
                  'Tipo do evento',
              hintText:
                  'Festival, Palestra, Feira...',
              prefixIcon: Icon(
                Icons.category_outlined,
              ),
            ),
          ),

          const SizedBox(height: 14),

          TextFormField(
            controller: cidadeController,
            validator: (v) => _validarTexto(v, 'a cidade', minimo: 2, maximo: 80, cidade: true),
            decoration:
                const InputDecoration(
              labelText: 'Cidade',
              prefixIcon: Icon(
                Icons.location_city,
              ),
            ),
          ),

          const SizedBox(height: 14),

          TextFormField(
            controller: enderecoController,
            validator: (v) => _validarTexto(v, 'o endereço', minimo: 8, maximo: 200),
            decoration:
                const InputDecoration(
              labelText: 'Endereço',
              prefixIcon: Icon(
                Icons.location_on_outlined,
              ),
            ),
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: vagasController,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) => _validarNumero(v, 'a quantidade de vagas', 100000),
                  keyboardType:
                      TextInputType.number,
                  decoration:
                      const InputDecoration(
                    labelText: 'Vagas',
                    prefixIcon: Icon(
                      Icons.groups_outlined,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: TextFormField(
                  controller: cargaController,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) => _validarNumero(v, 'a carga horária', 1000),
                  keyboardType:
                      TextInputType.number,
                  decoration:
                      const InputDecoration(
                    labelText:
                        'Carga horária',
                    prefixIcon: Icon(
                      Icons.schedule,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          _data(
            'Início',
            inicio,
            _datasValidadas ? _erroDataInicio() : null,
            () async {
              final escolhida =
                  await escolherDataHora(
                inicio,
              );

              if (escolhida != null) {
                setState(() {
                  inicio = escolhida;
                  _datasValidadas = true;
                });
              }
            },
          ),

          const SizedBox(height: 10),

          _data(
            'Fim',
            fim,
            _datasValidadas ? _erroDataFim() : null,
            () async {
              final escolhida =
                  await escolherDataHora(
                fim,
              );

              if (escolhida != null) {
                setState(() {
                  fim = escolhida;
                  _datasValidadas = true;
                });
              }
            },
          ),

          const SizedBox(height: 28),

          SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed:
                  carregando
                      ? null
                      : criar,
              icon: carregando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2,
                        color:
                            Colors.white,
                      ),
                    )
                  : Icon(
                      modoEdicao ? Icons.save_outlined : Icons.add,
                    ),
              label: Text(
                modoEdicao ? 'Salvar alterações' : 'Criar evento',
              ),
            ),
          ),

          const SizedBox(height: 25),
        ],
      ),
      ),
    );
  }

  Widget _data(
    String titulo,
    DateTime? data,
    String? erro,
    VoidCallback onTap,
  ) {

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: erro == null ? const Color(0xFFE8EAF0) : Theme.of(context).colorScheme.error,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        leading: const Icon(
          Icons.calendar_month_outlined,
          color: AppTheme.roxo,
        ),
        title: Text(titulo),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(data == null ? 'Selecionar data e horário'
              : DateFormat('dd/MM/yyyy • HH:mm').format(data)),
            if (erro != null)
              Text(erro, style: TextStyle(
                color: Theme.of(context).colorScheme.error, fontSize: 12)),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        isThreeLine: erro != null,
        dense: true,
      ),
    );
  }
}
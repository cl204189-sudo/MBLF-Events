import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/app_theme.dart';
import '../../models/mensagem.dart';
import '../../services/mensagem_service.dart';

class ChatScreen extends StatefulWidget {
  final int eventoId;
  final String eventoTitulo;
  final String canal;

  const ChatScreen({
    super.key,
    required this.eventoId,
    required this.eventoTitulo,
    this.canal = 'ORGANIZACAO',
  });

  @override
  State<ChatScreen> createState() =>
      _ChatScreenState();
}

class _ChatScreenState
    extends State<ChatScreen> with WidgetsBindingObserver {
  final MensagemService service =
      MensagemService();

  final TextEditingController
      mensagemController =
      TextEditingController();

  final ScrollController scrollController =
      ScrollController();

  List<Mensagem> mensagens = [];

  int? usuarioId;

  bool carregando = true;
  bool enviando = false;
  Timer? _atualizador;
  bool _consultando = false;
  bool _emPrimeiroPlano = true;
  String? _erroAtualizacao;
  int _naoLidas = 0;
  int? _ultimoIdLido;
  String get _chaveLeitura =>
      'chat_lido_${usuarioId}_${widget.eventoId}_${widget.canal}';

  Future<void> _registrarLeitura() async {
    if (usuarioId == null || mensagens.isEmpty) return;
    final ultimo = mensagens.map((m) => m.id).reduce((a,b) => a > b ? a : b);
    if (_ultimoIdLido != null && ultimo <= _ultimoIdLido!) return;
    _ultimoIdLido = ultimo;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_chaveLeitura, ultimo);
    if (mounted && _naoLidas != 0) setState(() => _naoLidas = 0);
  }



  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);
    carregar();
    _atualizador = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_emPrimeiroPlano && !_consultando && !carregando) {
        _buscarNovasMensagens();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _emPrimeiroPlano = state == AppLifecycleState.resumed;
    if (_emPrimeiroPlano) _buscarNovasMensagens();
  }

  Future<void> _buscarNovasMensagens() async {
    if (_consultando || !mounted) return;
    _consultando = true;
    try {
      final lista = await service.listar(widget.eventoId, canal: widget.canal);
      if (!mounted) return;
      final antigos = mensagens.map((m) => m.id).toSet();
      final haNovas = lista.any((m) => !antigos.contains(m.id));
      final mudou = haNovas || lista.length != mensagens.length;
      final novasDeOutros = lista.where((m) =>
          !antigos.contains(m.id) && m.usuarioId != usuarioId).length;
      final noFim = scrollController.hasClients &&
          scrollController.position.extentAfter < 160;
      if (mudou || _erroAtualizacao != null) {
        setState(() {
          if (mudou) mensagens = lista;
          if (novasDeOutros > 0 && !noFim) _naoLidas += novasDeOutros;
          _erroAtualizacao = null;
        });
        if (novasDeOutros > 0 && noFim) {
          _irParaFinal();
          _registrarLeitura();
        }
        if (novasDeOutros > 0 && !noFim && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$novasDeOutros nova(s) mensagem(ns) no ' 
                '${widget.canal == 'GERAL' ? 'chat geral' : 'chat da organização'}'),
              duration: const Duration(seconds: 2),
              action: SnackBarAction(label: 'Ver', onPressed: () {
                _irParaFinal();
                _registrarLeitura();
              }),
            ),
          );
        }
      }
    } catch (_) {
      if (mounted && _erroAtualizacao == null) {
        setState(() => _erroAtualizacao =
            'Sem conexão para atualizar mensagens. Tentando novamente...');
      }
    } finally {
      _consultando = false;
    }
  }


  Future<void> carregar() async {
    try {
      final prefs =
          await SharedPreferences.getInstance();

      final id =
          prefs.getInt('usuarioId');

      final lista =
          await service.listar(
        widget.eventoId, canal: widget.canal,
      );

      if (!mounted) return;

      final ultimoLido = prefs.getInt('chat_lido_${id}_${widget.eventoId}_${widget.canal}') ?? 0;
      setState(() {
        usuarioId = id;
        mensagens = lista;
        _ultimoIdLido = ultimoLido;
        _naoLidas = lista.where((m) => m.id > ultimoLido && m.usuarioId != id).length;
        carregando = false;
      });
      _irParaFinal();
      _registrarLeitura();
    } catch (erro) {
      if (!mounted) return;

      setState(() {
        carregando = false;
      });

      mostrarErro(erro);
    }
  }

  Future<void> enviar() async {
    final texto =
        mensagemController.text.trim();

    if (texto.isEmpty) {
      return;
    }

    setState(() {
      enviando = true;
    });

    try {
      final novaMensagem =
          await service.enviar(
        widget.eventoId,
        texto, canal: widget.canal,
      );

      if (!mounted) return;

      mensagemController.clear();

      setState(() {
        if (!mensagens.any((m) => m.id == novaMensagem.id)) {
          mensagens.add(novaMensagem);
        }
      });

      _irParaFinal();
      _registrarLeitura();
    } catch (erro) {
      mostrarErro(erro);
    } finally {
      if (mounted) {
        setState(() {
          enviando = false;
        });
      }
    }
  }

  void mostrarErro(Object erro) {
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
  }

  void _irParaFinal() {
    WidgetsBinding.instance
        .addPostFrameCallback(
      (_) {
        if (!scrollController.hasClients) {
          return;
        }

        scrollController.animateTo(
          scrollController
              .position
              .maxScrollExtent,
          duration:
              const Duration(
            milliseconds: 300,
          ),
          curve: Curves.easeOut,
        );
      },
    );
  }

  @override
  void dispose() {
    _atualizador?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    mensagemController.dispose();
    scrollController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          if (_naoLidas > 0)
            TextButton.icon(
              onPressed: () {
                _irParaFinal();
                _registrarLeitura();
              },
              icon: const Icon(Icons.mark_chat_read_outlined),
              label: Text('$_naoLidas nova(s)'),
            ),
        ],
        title: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              widget.canal == 'GERAL' ? 'Chat geral' : 'Chat da organização',
              style: TextStyle(
                fontWeight:
                    FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              widget.eventoTitulo,
              style: const TextStyle(
                fontSize: 12,
                color:
                    AppTheme.textoSecundario,
              ),
            ),
          ],
        ),
      ),

      body: Column(
        children: [
          if (_erroAtualizacao != null)
            MaterialBanner(
              content: Text(_erroAtualizacao!),
              actions: [TextButton(
                onPressed: _buscarNovasMensagens,
                child: const Text('Tentar agora'),
              )],
            ),
          Expanded(
            child: carregando
                ? const Center(
                    child:
                        CircularProgressIndicator(),
                  )
                : mensagens.isEmpty
                    ? const Center(
                        child: Text(
                          'Nenhuma mensagem ainda.\nComece a conversa!',
                          textAlign:
                              TextAlign.center,
                          style: TextStyle(
                            color: AppTheme
                                .textoSecundario,
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: carregar,
                        child:
                            ListView.builder(
                          controller:
                              scrollController,
                          padding:
                              const EdgeInsets
                                  .fromLTRB(
                            16,
                            16,
                            16,
                            20,
                          ),
                          itemCount:
                              mensagens.length,
                          itemBuilder:
                              (context, index) {
                            return _mensagem(
                              mensagens[index],
                            );
                          },
                        ),
                      ),
          ),

          _campoMensagem(),
        ],
      ),
    );
  }

  Widget _mensagem(
    Mensagem mensagem,
  ) {
    final minha =
        mensagem.usuarioId ==
            usuarioId;

    final horario =
        mensagem.dataEnvio != null
            ? DateFormat('HH:mm')
                .format(
                mensagem.dataEnvio!,
              )
            : '';

    return Align(
      alignment: minha
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Container(
        constraints:
            const BoxConstraints(
          maxWidth: 300,
        ),
        margin:
            const EdgeInsets.only(
          bottom: 10,
        ),
        padding:
            const EdgeInsets.fromLTRB(
          14,
          10,
          14,
          9,
        ),
        decoration: BoxDecoration(
          gradient: minha
              ? AppTheme
                  .gradientePrincipal
              : null,
          color:
              minha ? null : Theme.of(context).colorScheme.surfaceContainerHigh,
          borderRadius:
              BorderRadius.only(
            topLeft:
                const Radius.circular(18),
            topRight:
                const Radius.circular(18),
            bottomLeft: Radius.circular(
              minha ? 18 : 5,
            ),
            bottomRight: Radius.circular(
              minha ? 5 : 18,
            ),
          ),
          border: minha
              ? null
              : Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            if (!minha)
              Text(
                mensagem.usuarioNome,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.roxo,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

            if (!minha)
              const SizedBox(height: 3),

            Text(
              mensagem.mensagem,
              style: TextStyle(
                color: minha
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurface,
                fontSize: 15,
              ),
            ),

            const SizedBox(height: 5),

            Align(
              alignment:
                  Alignment.centerRight,
              child: Text(
                horario,
                style: TextStyle(
                  fontSize: 10,
                  color: minha
                      ? Colors.white70
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _campoMensagem() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        14,
        10,
        14,
        14,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller:
                    mensagemController,
                minLines: 1,
                maxLines: 4,
                textInputAction:
                    TextInputAction.newline,
                decoration:
                    const InputDecoration(
                  hintText:
                      'Escreva uma mensagem...',
                  prefixIcon: Icon(
                    Icons
                        .chat_bubble_outline,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 10),

            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: AppTheme
                    .gradientePrincipal,
                borderRadius:
                    BorderRadius.circular(
                  15,
                ),
              ),
              child: IconButton(
                onPressed:
                    enviando
                        ? null
                        : enviar,
                icon: enviando
                    ? const SizedBox(
                        width: 19,
                        height: 19,
                        child:
                            CircularProgressIndicator(
                          color:
                              Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons.send_rounded,
                        color:
                            Colors.white,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
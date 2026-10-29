import 'dart:async';
import 'package:flutter/material.dart';

import '../../config/app_theme.dart';
import '../../models/evento.dart';
import '../../services/evento_service.dart';
import '../../services/favorito_service.dart';
import 'detalhes_evento_screen.dart';

class FavoritosScreen
    extends StatefulWidget {
  const FavoritosScreen({
    super.key,
  });

  @override
  State<FavoritosScreen>
      createState() =>
          _FavoritosScreenState();
}

class _FavoritosScreenState
    extends State<FavoritosScreen> with WidgetsBindingObserver {
  Timer? _atualizacaoTimer;
  bool _emPrimeiroPlano = true;
  bool _atualizando = false;
  final EventoService eventoService =
      EventoService();

  final FavoritoService favoritoService =
      FavoritoService();

  List<Evento> favoritos = [];

  bool carregando = true;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _emPrimeiroPlano = state == AppLifecycleState.resumed;
    if (_emPrimeiroPlano && mounted) carregar(silencioso: true);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _atualizacaoTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_emPrimeiroPlano && !_atualizando && mounted) {
        carregar(silencioso: true);
      }
    });

    carregar();
  }

  Future<void> carregar({bool silencioso = false}) async {
    if (_atualizando) return;
    _atualizando = true;
    try {
      final eventos =
          await eventoService
              .listarPublicos();

      final ids =
          await favoritoService
              .listarIds();

      final lista = eventos
          .where(
            (evento) =>
                ids.contains(
              evento.id,
            ),
          )
          .toList();

      if (!mounted) return;

      setState(() {
        favoritos = lista;
        carregando = false;
      });
    } catch (erro) {
      if (!mounted) return;

      setState(() {
        carregando = false;
      });
    }
    finally {
      _atualizando = false;
    }
  }

  Future<void> remover(
    Evento evento,
  ) async {
    await favoritoService.remover(
      evento.id,
    );

    await carregar();

    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content: Text(
          'Evento removido dos favoritos.',
        ),
      ),
    );
  }

  @override
  void dispose() {
    _atualizacaoTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Favoritos',
          style: TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ),

      body: carregando
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : favoritos.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize:
                        MainAxisSize.min,
                    children: [
                      Icon(
                        Icons
                            .favorite_border,
                        size: 65,
                        color: AppTheme
                            .textoSecundario,
                      ),

                      SizedBox(
                        height: 14,
                      ),

                      Text(
                        'Nenhum evento favorito.',
                        style: TextStyle(
                          color: AppTheme
                              .textoSecundario,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding:
                      const EdgeInsets.all(
                    20,
                  ),
                  itemCount:
                      favoritos.length,
                  itemBuilder:
                      (context, index) {
                    final evento =
                        favoritos[index];

                    return Container(
                      margin:
                          const EdgeInsets
                              .only(
                        bottom: 12,
                      ),
                      decoration:
                          BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius:
                            BorderRadius
                                .circular(20),
                        border:
                            Border.all(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                      child: ListTile(
                        contentPadding:
                            const EdgeInsets
                                .all(15),

                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DetalhesEventoScreen(
                                evento: evento,
                              ),
                            ),
                          );

                          if (!mounted) return;

                          await carregar();
                        },

                        leading:
                            Container(
                          width: 46,
                          height: 46,
                          decoration:
                              BoxDecoration(
                            gradient: AppTheme
                                .gradientePrincipal,
                            borderRadius:
                                BorderRadius
                                    .circular(
                              14,
                            ),
                          ),
                          child:
                              const Icon(
                            Icons.event,
                            color:
                                Colors.white,
                          ),
                        ),

                        title: Text(
                          evento.titulo,
                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                        subtitle: Text(
                          evento.cidade,
                        ),

                        trailing:
                            IconButton(
                          onPressed: () {
                            remover(
                              evento,
                            );
                          },
                          icon:
                              const Icon(
                            Icons.favorite,
                            color:
                                Colors.red,
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
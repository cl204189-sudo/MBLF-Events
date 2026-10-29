import 'package:flutter/material.dart';

import '../../config/app_theme.dart';
import '../../services/usuario_service.dart';

class EditarPerfilScreen
    extends StatefulWidget {
  const EditarPerfilScreen({
    super.key,
  });

  @override
  State<EditarPerfilScreen>
      createState() =>
          _EditarPerfilScreenState();
}

class _EditarPerfilScreenState
    extends State<EditarPerfilScreen> {
  final UsuarioService service =
      UsuarioService();

  final nomeController =
      TextEditingController();

  final emailController =
      TextEditingController();

  final telefoneController =
      TextEditingController();

  bool carregando = true;
  bool salvando = false;

  @override
  void initState() {
    super.initState();

    carregar();
  }

  Future<void> carregar() async {
    try {
      final usuario =
          await service.buscarMeuPerfil();

      if (!mounted) return;

      nomeController.text =
          usuario['nome'] ?? '';

      emailController.text =
          usuario['email'] ?? '';

      telefoneController.text =
          usuario['telefone'] ?? '';

      setState(() {
        carregando = false;
      });
    } catch (erro) {
      if (!mounted) return;

      setState(() {
        carregando = false;
      });

      mostrarErro(erro);
    }
  }

  Future<void> salvar() async {
    final nome =
        nomeController.text.trim();

    final email =
        emailController.text.trim();

    final telefone =
        telefoneController.text.trim();

    if (nome.isEmpty) {
      mostrarMensagem(
        'Informe seu nome.',
      );
      return;
    }

    if (email.isEmpty) {
      mostrarMensagem(
        'Informe seu email.',
      );
      return;
    }

    setState(() {
      salvando = true;
    });

    try {
      await service.atualizarMeuPerfil(
        nome: nome,
        email: email,
        telefone: telefone,
      );

      if (!mounted) return;

      await showDialog(
        context: context,
        builder: (_) {
          return AlertDialog(
            icon: const Icon(
              Icons.check_circle,
              color: AppTheme.verde,
              size: 48,
            ),
            title: const Text(
              'Perfil atualizado!',
            ),
            content: const Text(
              'Suas informações foram salvas com sucesso.',
            ),
            actions: [
              FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text(
                  'Continuar',
                ),
              ),
            ],
          );
        },
      );

      if (!mounted) return;

      Navigator.pop(
        context,
        true,
      );
    } catch (erro) {
      mostrarErro(erro);
    } finally {
      if (mounted) {
        setState(() {
          salvando = false;
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

  void mostrarErro(
    Object erro,
  ) {
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
            'Não foi possível salvar',
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
  }

  @override
  void dispose() {
    nomeController.dispose();
    emailController.dispose();
    telefoneController.dispose();

    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Editar perfil',
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
          : ListView(
              padding:
                  const EdgeInsets.all(
                20,
              ),
              children: [
                Container(
                  padding:
                      const EdgeInsets.all(
                    20,
                  ),
                  decoration:
                      BoxDecoration(
                    gradient: AppTheme
                        .gradientePrincipal,
                    borderRadius:
                        BorderRadius.circular(
                      24,
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons
                            .manage_accounts_outlined,
                        color:
                            Colors.white,
                        size: 35,
                      ),
                      SizedBox(
                        width: 14,
                      ),
                      Expanded(
                        child: Text(
                          'Atualize suas informações pessoais',
                          style:
                              TextStyle(
                            color:
                                Colors.white,
                            fontSize: 18,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                  height: 25,
                ),

                TextField(
                  controller:
                      nomeController,
                  textCapitalization:
                      TextCapitalization
                          .words,
                  decoration:
                      const InputDecoration(
                    labelText: 'Nome',
                    prefixIcon: Icon(
                      Icons
                          .person_outline,
                    ),
                  ),
                ),

                const SizedBox(
                  height: 14,
                ),

                TextField(
                  controller:
                      emailController,
                  keyboardType:
                      TextInputType
                          .emailAddress,
                  decoration:
                      const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(
                      Icons.email_outlined,
                    ),
                  ),
                ),

                const SizedBox(
                  height: 14,
                ),

                TextField(
                  controller:
                      telefoneController,
                  keyboardType:
                      TextInputType.phone,
                  decoration:
                      const InputDecoration(
                    labelText:
                        'Telefone',
                    prefixIcon: Icon(
                      Icons.phone_outlined,
                    ),
                  ),
                ),

                const SizedBox(
                  height: 28,
                ),

                SizedBox(
                  height: 52,
                  child:
                      FilledButton.icon(
                    onPressed: salvando
                        ? null
                        : salvar,
                    icon: salvando
                        ? const SizedBox(
                            width: 19,
                            height: 19,
                            child:
                                CircularProgressIndicator(
                              strokeWidth:
                                  2,
                              color: Colors
                                  .white,
                            ),
                          )
                        : const Icon(
                            Icons
                                .save_outlined,
                          ),
                    label: const Text(
                      'Salvar alterações',
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
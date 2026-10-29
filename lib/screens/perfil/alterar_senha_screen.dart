import 'package:flutter/material.dart';

import '../../config/app_theme.dart';
import '../../services/usuario_service.dart';

class AlterarSenhaScreen
    extends StatefulWidget {
  const AlterarSenhaScreen({
    super.key,
  });

  @override
  State<AlterarSenhaScreen>
      createState() =>
          _AlterarSenhaScreenState();
}

class _AlterarSenhaScreenState
    extends State<AlterarSenhaScreen> {
  final UsuarioService service =
      UsuarioService();

  final senhaAtualController =
      TextEditingController();

  final novaSenhaController =
      TextEditingController();

  final confirmarSenhaController =
      TextEditingController();

  bool salvando = false;

  bool mostrarSenhaAtual = false;
  bool mostrarNovaSenha = false;
  bool mostrarConfirmacao = false;

  Future<void> salvar() async {
    final senhaAtual =
        senhaAtualController.text.trim();

    final novaSenha =
        novaSenhaController.text.trim();

    final confirmacao =
        confirmarSenhaController.text.trim();

    if (senhaAtual.isEmpty) {
      mostrarMensagem(
        'Informe sua senha atual.',
      );
      return;
    }

    if (novaSenha.isEmpty) {
      mostrarMensagem(
        'Informe a nova senha.',
      );
      return;
    }

    if (novaSenha.length < 6) {
      mostrarMensagem(
        'A nova senha deve possuir pelo menos 6 caracteres.',
      );
      return;
    }

    if (novaSenha != confirmacao) {
      mostrarMensagem(
        'As novas senhas não coincidem.',
      );
      return;
    }

    setState(() {
      salvando = true;
    });

    try {
      await service.alterarSenha(
        senhaAtual: senhaAtual,
        novaSenha: novaSenha,
      );

      if (!mounted) return;

      await showDialog(
        context: context,
        builder: (_) {
          return AlertDialog(
            icon: const Icon(
              Icons.check_circle,
              color: AppTheme.verde,
              size: 50,
            ),
            title: const Text(
              'Senha alterada!',
            ),
            content: const Text(
              'Sua nova senha foi salva com sucesso.',
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

      Navigator.pop(context);
    } catch (erro) {
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (_) {
          return AlertDialog(
            icon: const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 44,
            ),
            title: const Text(
              'Não foi possível alterar',
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

  @override
  void dispose() {
    senhaAtualController.dispose();
    novaSenhaController.dispose();
    confirmarSenhaController.dispose();

    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Alterar senha',
          style: TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ),

      body: ListView(
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
            child: const Row(
              children: [
                Icon(
                  Icons.lock_reset_outlined,
                  color: Colors.white,
                  size: 36,
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Proteja sua conta com uma senha segura.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 25),

          TextField(
            controller:
                senhaAtualController,
            obscureText:
                !mostrarSenhaAtual,
            decoration: InputDecoration(
              labelText: 'Senha atual',
              prefixIcon: const Icon(
                Icons.lock_outline,
              ),
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    mostrarSenhaAtual =
                        !mostrarSenhaAtual;
                  });
                },
                icon: Icon(
                  mostrarSenhaAtual
                      ? Icons
                          .visibility_off_outlined
                      : Icons
                          .visibility_outlined,
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),

          TextField(
            controller:
                novaSenhaController,
            obscureText:
                !mostrarNovaSenha,
            decoration: InputDecoration(
              labelText: 'Nova senha',
              prefixIcon: const Icon(
                Icons.key_outlined,
              ),
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    mostrarNovaSenha =
                        !mostrarNovaSenha;
                  });
                },
                icon: Icon(
                  mostrarNovaSenha
                      ? Icons
                          .visibility_off_outlined
                      : Icons
                          .visibility_outlined,
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),

          TextField(
            controller:
                confirmarSenhaController,
            obscureText:
                !mostrarConfirmacao,
            decoration: InputDecoration(
              labelText:
                  'Confirmar nova senha',
              prefixIcon: const Icon(
                Icons.verified_user_outlined,
              ),
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    mostrarConfirmacao =
                        !mostrarConfirmacao;
                  });
                },
                icon: Icon(
                  mostrarConfirmacao
                      ? Icons
                          .visibility_off_outlined
                      : Icons
                          .visibility_outlined,
                ),
              ),
            ),
          ),

          const SizedBox(height: 28),

          SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed:
                  salvando
                      ? null
                      : salvar,
              icon: salvando
                  ? const SizedBox(
                      width: 19,
                      height: 19,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2,
                        color:
                            Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons
                          .lock_reset_outlined,
                    ),
              label: const Text(
                'Alterar senha',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
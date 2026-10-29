import 'package:flutter/material.dart';

import '../../config/app_theme.dart';
import '../../services/auth_service.dart';
import '../../widgets/gradient_button.dart';
import '../main_navigation_screen.dart';
import 'cadastro_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() =>
      _LoginScreenState();
}

class _LoginScreenState
    extends State<LoginScreen> {

  final TextEditingController
      emailController =
      TextEditingController();

  final TextEditingController
      senhaController =
      TextEditingController();

  final AuthService authService =
      AuthService();

  bool carregando = false;
  bool mostrarSenha = false;

  Future<void> fazerLogin() async {
    final email =
        emailController.text.trim();

    final senha =
        senhaController.text;

    if (email.isEmpty ||
        senha.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Preencha email e senha.',
          ),
        ),
      );

      return;
    }

    setState(() {
      carregando = true;
    });

    try {
      await authService.login(
        email,
        senha,
      );

      if (!mounted) {
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              const MainNavigationScreen(),
        ),
      );
    } catch (erro) {
      if (!mounted) {
        return;
      }

      String mensagem =
          erro.toString();

      mensagem = mensagem.replaceFirst(
        'Exception: ',
        '',
      );

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            mensagem,
          ),
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
    emailController.dispose();
    senhaController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 26,
          ),
          child: Column(
            children: [
              const SizedBox(height: 50),

              Container(
                width: 170,
                padding:
                    const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black
                          .withValues(
                            alpha: 0.06,
                          ),
                      blurRadius: 20,
                      offset:
                          const Offset(0, 8),
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/images/LOGO2.png',
                ),
              ),

              const SizedBox(height: 35),

              const Align(
                alignment:
                    Alignment.centerLeft,
                child: Text(
                  'Bem-vindo!',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight:
                        FontWeight.bold,
                    color:
                        AppTheme.texto,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              const Align(
                alignment:
                    Alignment.centerLeft,
                child: Text(
                  'Entre na sua conta para continuar.',
                  style: TextStyle(
                    fontSize: 15,
                    color:
                        AppTheme.textoSecundario,
                  ),
                ),
              ),

              const SizedBox(height: 34),

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

              const SizedBox(height: 16),

              TextField(
                controller:
                    senhaController,
                obscureText:
                    !mostrarSenha,
                decoration:
                    InputDecoration(
                  labelText: 'Senha',

                  prefixIcon:
                      const Icon(
                    Icons.lock_outline,
                  ),

                  suffixIcon:
                      IconButton(
                    onPressed: () {
                      setState(() {
                        mostrarSenha =
                            !mostrarSenha;
                      });
                    },
                    icon: Icon(
                      mostrarSenha
                          ? Icons
                              .visibility_off_outlined
                          : Icons
                              .visibility_outlined,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 26),

              GradientButton(
                texto: 'Entrar',
                icone:
                    Icons.login_rounded,
                carregando:
                    carregando,
                onPressed: fazerLogin,
              ),

              const SizedBox(height: 24),

              Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  const Text(
                    'Ainda não tem uma conta?',
                    style: TextStyle(
                      color: AppTheme
                          .textoSecundario,
                    ),
                  ),

                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CadastroScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      'Cadastre-se',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
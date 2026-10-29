import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import '../../config/app_theme.dart';
import '../../widgets/gradient_button.dart';

class CadastroScreen extends StatefulWidget {
  const CadastroScreen({super.key});

  @override
  State<CadastroScreen> createState() => _CadastroScreenState();
}

class _CadastroScreenState extends State<CadastroScreen> {
  final nomeController = TextEditingController();
  final emailController = TextEditingController();
  final telefoneController = TextEditingController();
  final senhaController = TextEditingController();
  final confirmarSenhaController = TextEditingController();

  bool carregando = false;
  bool mostrarSenha = false;
  bool mostrarConfirmacao = false;

  Future<void> cadastrar() async {
    final nome = nomeController.text.trim();
    final email = emailController.text.trim();
    final telefone = telefoneController.text.trim();
    final senha = senhaController.text;
    final confirmarSenha = confirmarSenhaController.text;

    if (nome.isEmpty ||
        email.isEmpty ||
        telefone.isEmpty ||
        senha.isEmpty ||
        confirmarSenha.isEmpty) {
      mostrarMensagem(
        'Preencha todos os campos.',
      );
      return;
    }

    if (senha != confirmarSenha) {
      mostrarMensagem(
        'As senhas não são iguais.',
      );
      return;
    }

    if (senha.length < 6) {
      mostrarMensagem(
        'A senha deve possuir pelo menos 6 caracteres.',
      );
      return;
    }

    setState(() {
      carregando = true;
    });

    try {
      final url = Uri.parse(
        '${ApiConfig.baseUrl}/usuarios/criar',
      );

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'nome': nome,
          'email': email,
          'telefone': telefone,
          'senha': senha,
        }),
      );

      dynamic dados;

      if (response.body.isNotEmpty) {
        dados = jsonDecode(response.body);
      }

      if (response.statusCode == 200 ||
          response.statusCode == 201) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Conta criada com sucesso! Faça seu login.',
            ),
          ),
        );

        Navigator.pop(context);
      } else {
        mostrarMensagem(
          dados is Map
              ? dados['mensagem'] ?? 'Não foi possível criar a conta.'
              : 'Não foi possível criar a conta.',
        );
      }
    } catch (erro) {
      mostrarMensagem(
        'Não foi possível conectar com o servidor.',
      );
    } finally {
      if (mounted) {
        setState(() {
          carregando = false;
        });
      }
    }
  }

  void mostrarMensagem(String mensagem) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
      ),
    );
  }

  @override
  void dispose() {
    nomeController.dispose();
    emailController.dispose();
    telefoneController.dispose();
    senhaController.dispose();
    confirmarSenhaController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Criar conta',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 26,
            vertical: 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 64,
                height: 6,
                decoration: BoxDecoration(
                  gradient: AppTheme.gradientePrincipal,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'Faça parte do\nMBLF Events',
                style: TextStyle(
                  fontSize: 30,
                  height: 1.15,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.texto,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                'Crie sua conta para descobrir, participar e organizar eventos.',
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: AppTheme.textoSecundario,
                ),
              ),

              const SizedBox(height: 30),

              TextField(
                controller: nomeController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nome completo',
                  prefixIcon: Icon(
                    Icons.person_outline,
                  ),
                ),
              ),

              const SizedBox(height: 15),

              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(
                    Icons.email_outlined,
                  ),
                ),
              ),

              const SizedBox(height: 15),

              TextField(
                controller: telefoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Telefone',
                  prefixIcon: Icon(
                    Icons.phone_outlined,
                  ),
                ),
              ),

              const SizedBox(height: 15),

              TextField(
                controller: senhaController,
                obscureText: !mostrarSenha,
                decoration: InputDecoration(
                  labelText: 'Senha',
                  prefixIcon: const Icon(
                    Icons.lock_outline,
                  ),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        mostrarSenha = !mostrarSenha;
                      });
                    },
                    icon: Icon(
                      mostrarSenha
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 15),

              TextField(
                controller: confirmarSenhaController,
                obscureText: !mostrarConfirmacao,
                decoration: InputDecoration(
                  labelText: 'Confirmar senha',
                  prefixIcon: const Icon(
                    Icons.lock_outline,
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
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              GradientButton(
                texto: 'Criar minha conta',
                icone: Icons.person_add_alt_1_rounded,
                carregando: carregando,
                onPressed: cadastrar,
              ),

              const SizedBox(height: 20),

              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Já tenho uma conta',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
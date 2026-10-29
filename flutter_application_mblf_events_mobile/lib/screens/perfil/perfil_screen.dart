import 'package:flutter/material.dart';
import '../../main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/app_theme.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';
import '../certificados/meus_certificados_screen.dart';
import '../inscricoes/minhas_inscricoes_screen.dart';
import '../eventos/favoritos_screen.dart';
import 'editar_perfil_screen.dart';
import 'alterar_senha_screen.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  String nome = '';
  String email = '';
  String perfil = '';

  bool carregando = true;

  @override
  void initState() {
    super.initState();
    carregarUsuario();
  }

  Future<void> carregarUsuario() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      nome = prefs.getString('nome') ?? '';
      email = prefs.getString('email') ?? '';
      perfil = prefs.getString('perfil') ?? '';
      carregando = false;
    });
  }

  Future<void> logout() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Sair da conta?'),
          content: const Text(
            'Você precisará fazer login novamente para acessar o aplicativo.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Sair'),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    final authService = AuthService();

    await authService.logout();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
      (route) => false,
    );
  }

  String iniciais() {
    if (nome.trim().isEmpty) {
      return 'MB';
    }

    final partes = nome.trim().split(' ');

    if (partes.length == 1) {
      return partes.first.substring(0, 1).toUpperCase();
    }

    return '${partes.first[0]}${partes.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Meu Perfil',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: carregando
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                20,
                10,
                20,
                110,
              ),
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: AppTheme.gradientePrincipal,
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(
                            alpha: 0.18,
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(
                              alpha: 0.35,
                            ),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            iniciais(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 23,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 16),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nome,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 21,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 5),

                            Text(
                              email,
                              style: const TextStyle(
                                color: Colors.white70,
                              ),
                            ),

                            const SizedBox(height: 10),

                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(
                                  alpha: 0.16,
                                ),
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Text(
                                perfil.isEmpty
                                    ? 'USUÁRIO'
                                    : perfil,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                const Text(
                  'Minha conta',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                _opcao(
                    icone: Icons.manage_accounts_outlined,
                    titulo: 'Editar perfil',
                    subtitulo:
                        'Nome, email, telefone e senha',
                    onTap: () async {
                      final alterou =
                          await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const EditarPerfilScreen(),
                        ),
                      );

                      if (alterou == true) {
                        await carregarUsuario();
                      }
                    },
                  ),

                _opcao(
                    icone: Icons.lock_reset_outlined,
                    titulo: 'Alterar senha',
                    subtitulo:
                        'Atualize sua senha de acesso',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const AlterarSenhaScreen(),
                        ),
                      );
                    },
                  ),  

                _opcao(
                  icone: Icons.confirmation_number_outlined,
                  titulo: 'Minhas inscrições',
                  subtitulo: 'Ingressos, inscrições e QR Codes',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const MinhasInscricoesScreen(),
                      ),
                    );
                  },
                ),

                _opcao(
                  icone: Icons.favorite_outline,
                  titulo: 'Favoritos',
                  subtitulo:
                      'Eventos que você salvou',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const FavoritosScreen(),
                      ),
                    );
                  },
                ),

                _opcao(
                  icone: Icons.workspace_premium_outlined,
                  titulo: 'Meus certificados',
                  subtitulo: 'Certificados liberados dos seus eventos',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const MeusCertificadosScreen(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24),
                const Text('Aparência',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(children: [
                    const Icon(Icons.dark_mode_outlined, color: AppTheme.roxo),
                    const SizedBox(width: 12),
                    const Expanded(child: Text('Tema do aplicativo')),
                    DropdownButtonHideUnderline(
                      child: DropdownButton<ThemeMode>(
                        value: MblfThemeController.of(context).modo,
                        items: const [
                          DropdownMenuItem(value: ThemeMode.system,
                            child: Text('Sistema')),
                          DropdownMenuItem(value: ThemeMode.light,
                            child: Text('Claro')),
                          DropdownMenuItem(value: ThemeMode.dark,
                            child: Text('Escuro')),
                        ],
                        onChanged: (modo) {
                          if (modo != null) {
                            MblfThemeController.of(context).alterar(modo);
                          }
                        },
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 24),

                _opcao(
                  icone: Icons.logout_rounded,
                  titulo: 'Sair',
                  subtitulo: 'Encerrar sua sessão',
                  corIcone: Colors.red,
                  onTap: logout,
                ),
              ],
            ),
    );
  }

  Widget _opcao({
    required IconData icone,
    required String titulo,
    required String subtitulo,
    required VoidCallback onTap,
    Color? corIcone,
  }) {
    final cor = corIcone ?? AppTheme.roxo;

    return Container(
      margin: const EdgeInsets.only(
        bottom: 11,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: const Color(0xFFEBEDF2),
        ),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 7,
        ),
        leading: Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            color: cor.withValues(
              alpha: 0.10,
            ),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(
            icone,
            color: cor,
          ),
        ),
        title: Text(
          titulo,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitulo,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textoSecundario,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right,
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';

import '../../config/app_theme.dart';

class SobreNosScreen extends StatelessWidget {
  final VoidCallback? onVoltar;

  const SobreNosScreen({
    super.key,
    this.onVoltar,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Voltar',
          icon: const Icon(Icons.arrow_back),
          onPressed: onVoltar ?? () => Navigator.maybePop(context),
        ),
        title: const Text(
          'Sobre nós',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          20,
          10,
          20,
          30,
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: AppTheme.gradientePrincipal,
              borderRadius: BorderRadius.circular(26),
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Image.asset(
                  'assets/images/LOGO3.png',
                  width: 80,
                  height: 80,
                  fit: BoxFit.contain,
                ),

                const SizedBox(height: 14),

                const Text(
                  'MBLF Events',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Uma plataforma criada para facilitar a organização, divulgação e participação em eventos.',
                  style: TextStyle(
                    color: Colors.white70,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          const Text(
            'Sobre o projeto',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

           Text(
            'O MBLF Events é um sistema desenvolvido para centralizar diferentes etapas da gestão de eventos em uma única plataforma. '
            'O projeto permite criar e divulgar eventos, controlar inscrições, utilizar QR Code para check-in, emitir certificados, '
            'gerenciar colaboradores, utilizar o HUB de organização e acompanhar diferentes informações relacionadas ao evento.',
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),

          const SizedBox(height: 30),

          const Text(
            'Nossa equipe',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

           Text(
            'O projeto foi dividido entre quatro integrantes, cada um responsável por uma parte do sistema.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 18),

          _integrante(
            context: context,
            numero: 1,
            nome: 'Matheus Juventino Bedesque',
            funcao: 'API e Banco de Dados',
            descricao:
                'Responsável pelo desenvolvimento da API, regras de negócio, autenticação com JWT, integração com o banco de dados e estruturação das informações do sistema.',
            icone: Icons.storage_outlined,
          ),

          _integrante(
            context: context,
            numero: 2,
            nome: 'Brenda Marroni Machado Pereira',
            funcao: 'Desenvolvimento Web',
            descricao:
                'Responsável pelo desenvolvimento da aplicação Web e pela construção das interfaces utilizadas no navegador.',
            icone: Icons.language_outlined,
          ),

          _integrante(
            context: context,
            numero: 3,
            nome: 'Leandro Lizardo Amador',
            funcao: 'Desenvolvimento Mobile',
            descricao:
                'Responsável pelo desenvolvimento do aplicativo mobile em Flutter e pela integração do aplicativo com a API.',
            icone: Icons.phone_android_outlined,
          ),

          _integrante(
            context: context,
            numero: 4,
            nome: 'Felipe Romolini Amorim',
            funcao: 'Desktop e Relatórios',
            descricao:
                'Responsável pelo desenvolvimento da aplicação Desktop e pelas funcionalidades de geração e visualização de relatórios.',
            icone: Icons.desktop_windows_outlined,
          ),

          const SizedBox(height: 25),

          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.groups_2_outlined,
                  color: AppTheme.roxo,
                  size: 32,
                ),

                SizedBox(height: 10),

                Text(
                  'Trabalho em equipe',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(height: 6),

                Text(
                  'Apesar da divisão de responsabilidades, todas as partes do sistema trabalham de forma integrada para formar o MBLF Events.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _integrante({
    required BuildContext context,
    required int numero,
    required String nome,
    required String funcao,
    required String descricao,
    required IconData icone,
  }) {
    return Container(
      margin: const EdgeInsets.only(
        bottom: 14,
      ),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: AppTheme.gradientePrincipal,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              icone,
              color: Colors.white,
              size: 25,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  nome,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  funcao,
                  style: const TextStyle(
                    color: AppTheme.roxo,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  descricao,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
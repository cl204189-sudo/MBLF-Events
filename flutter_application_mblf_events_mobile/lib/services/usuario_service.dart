import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';

class UsuarioService {
  Future<String> _token() async {
    final prefs =
        await SharedPreferences.getInstance();

    final token =
        prefs.getString('token');

    if (token == null) {
      throw Exception(
        'Usuário não autenticado.',
      );
    }

    return token;
  }

  Future<void> alterarSenha({
  required String senhaAtual,
  required String novaSenha,
  }) async {
  final token = await _token();

  final url = Uri.parse(
    '${ApiConfig.baseUrl}/usuarios/me/senha',
  );

  final response = await http.put(
    url,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode({
      'senhaAtual': senhaAtual,
      'novaSenha': novaSenha,
    }),
  );

  if (response.statusCode == 200 ||
      response.statusCode == 204) {
    return;
  }

  dynamic dados;

  if (response.body.isNotEmpty) {
    dados = jsonDecode(response.body);
  }

  throw Exception(
    dados is Map
        ? dados['mensagem'] ??
            'Não foi possível alterar a senha.'
        : 'Não foi possível alterar a senha.',
  );
}

  Future<Map<String, dynamic>>
      buscarMeuPerfil() async {
    final token = await _token();

    final url = Uri.parse(
      '${ApiConfig.baseUrl}/usuarios/me',
    );

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(
        jsonDecode(response.body),
      );
    }

    throw Exception(
      'Não foi possível carregar o perfil.',
    );
  }

  Future<Map<String, dynamic>>
      atualizarMeuPerfil({
    required String nome,
    required String email,
    required String telefone,
    String senha = '',
  }) async {
    final token = await _token();

    final url = Uri.parse(
      '${ApiConfig.baseUrl}/usuarios/me',
    );

    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
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
      dados =
          jsonDecode(response.body);
    }

    if (response.statusCode == 200) {
      final resultado =
          Map<String, dynamic>.from(
        dados,
      );

      final prefs =
          await SharedPreferences.getInstance();

      await prefs.setString(
        'nome',
        resultado['nome'] ?? nome,
      );

      await prefs.setString(
        'email',
        resultado['email'] ?? email,
      );

      return resultado;
    }

    throw Exception(
      dados is Map
          ? dados['mensagem'] ??
              'Não foi possível atualizar o perfil.'
          : 'Não foi possível atualizar o perfil.',
    );
  }
}
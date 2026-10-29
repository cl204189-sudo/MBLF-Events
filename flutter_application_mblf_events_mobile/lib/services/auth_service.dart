import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class AuthService {
  static const _tempoLimite = Duration(seconds: 15);

  Future<Map<String, dynamic>> login(String email, String senha) async {
    http.Response response;
    try {
      response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'senha': senha}),
      ).timeout(_tempoLimite);
    } on TimeoutException {
      throw Exception('A conexão demorou demais. Verifique a API e a rede.');
    } on SocketException {
      throw Exception('Não foi possível conectar à API. Confira o IP e a rede.');
    } on http.ClientException {
      throw Exception('Falha de conexão com a API. Confira o endereço e o servidor.');
    }

    dynamic body;
    try {
      body = jsonDecode(response.body);
    } on FormatException {
      throw Exception('A API retornou uma resposta inválida (${response.statusCode}).');
    }
    if (response.statusCode != 200) {
      final mensagem = body is Map ? body['mensagem'] : null;
      throw Exception(mensagem?.toString() ??
          (response.statusCode == 401 ? 'Email ou senha incorretos.' :
          'Erro no login (${response.statusCode}).'));
    }
    if (body is! Map || body['token'] is! String ||
        (body['token'] as String).trim().isEmpty || body['id'] is! num) {
      throw Exception('Resposta de login incompleta: token ou usuário ausente.');
    }
    final prefs = await SharedPreferences.getInstance();
    // Não apaga preferências de tema nem outras configurações locais.
    await prefs.setString('token', body['token'] as String);
    await prefs.setInt('usuarioId', (body['id'] as num).toInt());
    await prefs.setString('nome', (body['nome'] ?? '').toString());
    await prefs.setString('email', (body['email'] ?? email).toString());
    await prefs.setString('perfil', (body['perfil'] ?? '').toString());
    return Map<String, dynamic>.from(body);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<bool> estaLogado() async {
    final token = await getToken();
    if (token == null || token.isEmpty) return false;
    // JWT expirado deve ser descartado, mesmo sem conexão.
    final partes = token.split('.');
    if (partes.length == 3) {
      try {
        final payload = jsonDecode(utf8.decode(base64Url.decode(
          base64Url.normalize(partes[1]))));
        if (payload is Map && payload['exp'] is num &&
            DateTime.now().millisecondsSinceEpoch >=
                (payload['exp'] as num).toDouble() * 1000) {
          await limparSessao();
          return false;
        }
      } catch (_) {
        // A validação definitiva do token continua sendo responsabilidade da API.
      }
    }
    return true;
  }

  Future<void> limparSessao() async {
    final prefs = await SharedPreferences.getInstance();
    for (final chave in ['token', 'usuarioId', 'nome', 'email', 'perfil']) {
      await prefs.remove(chave);
    }
  }

  Future<void> logout() => limparSessao();
}

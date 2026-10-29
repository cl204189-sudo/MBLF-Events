import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';

class ModeracaoService {
  Future<String> _token() async {
    final prefs =
        await SharedPreferences.getInstance();

    final token = prefs.getString('token');

    if (token == null) {
      throw Exception(
        'Usuário não autenticado.',
      );
    }

    return token;
  }

  Future<void> silenciar(
    int eventoId,
    int alvoId,
    String motivo,
  ) async {
    final token = await _token();

    final url = Uri.parse(
      '${ApiConfig.baseUrl}/moderacoes/evento/$eventoId/silenciar',
    );

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'alvoId': alvoId,
        'motivo': motivo,
      }),
    );

    _validarResposta(
      response,
      'Não foi possível silenciar o usuário.',
    );
  }

  Future<void> dessilenciar(
    int eventoId,
    int alvoId,
  ) async {
    final token = await _token();

    final url = Uri.parse(
      '${ApiConfig.baseUrl}/moderacoes/evento/$eventoId/dessilenciar',
    );

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'alvoId': alvoId,
      }),
    );

    _validarResposta(
      response,
      'Não foi possível retirar o silenciamento.',
    );
  }

  Future<void> expulsar(
    int eventoId,
    int alvoId,
    String motivo,
  ) async {
    final token = await _token();

    final url = Uri.parse(
      '${ApiConfig.baseUrl}/moderacoes/evento/$eventoId/expulsar',
    );

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'alvoId': alvoId,
        'motivo': motivo,
      }),
    );

    _validarResposta(
      response,
      'Não foi possível expulsar o usuário.',
    );
  }

  Future<void> silenciarTodos(
    int eventoId,
  ) async {
    final token = await _token();

    final url = Uri.parse(
      '${ApiConfig.baseUrl}/moderacoes/evento/$eventoId/silenciar-todos',
    );

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    _validarResposta(
      response,
      'Não foi possível silenciar todos.',
    );
  }

  Future<void> liberarTodos(
    int eventoId,
  ) async {
    final token = await _token();

    final url = Uri.parse(
      '${ApiConfig.baseUrl}/moderacoes/evento/$eventoId/liberar-todos',
    );

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    _validarResposta(
      response,
      'Não foi possível liberar todos.',
    );
  }

  Future<List<Map<String, dynamic>>> historico(int eventoId) async {
    final token = await _token();
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/moderacoes/evento/$eventoId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    _validarResposta(response, 'Não foi possível consultar o histórico.');
    final dados = jsonDecode(response.body) as List<dynamic>;
    return dados.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  void _validarResposta(
    http.Response response,
    String mensagemPadrao,
  ) {
    if (response.statusCode == 200 ||
        response.statusCode == 201) {
      return;
    }

    dynamic dados;

    if (response.body.isNotEmpty) {
      dados = jsonDecode(response.body);
    }

    throw Exception(
      dados is Map
          ? dados['mensagem'] ?? mensagemPadrao
          : mensagemPadrao,
    );
  }
}
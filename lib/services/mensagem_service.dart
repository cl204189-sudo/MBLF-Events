import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../models/mensagem.dart';

class MensagemService {
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

  Future<List<Mensagem>> listar(
    int eventoId, {String canal = 'ORGANIZACAO'}
  ) async {
    final token = await _token();

    final url = Uri.parse(
      '${ApiConfig.baseUrl}/mensagens/evento/$eventoId/canal/$canal',
    );

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> dados =
          jsonDecode(response.body);

      return dados
          .map(
            (json) =>
                Mensagem.fromJson(json),
          )
          .toList();
    }

    dynamic dados;

    if (response.body.isNotEmpty) {
      dados = jsonDecode(response.body);
    }

    throw Exception(
      dados is Map
          ? dados['mensagem'] ??
              'Não foi possível carregar o chat.'
          : 'Não foi possível carregar o chat.',
    );
  }

  Future<Mensagem> enviar(
    int eventoId,
    String texto, {String canal = 'ORGANIZACAO'}
  ) async {
    final token = await _token();

    final url = Uri.parse(
      '${ApiConfig.baseUrl}/mensagens/evento/$eventoId/canal/$canal',
    );

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'mensagem': texto,
      }),
    );

    dynamic dados;

    if (response.body.isNotEmpty) {
      dados = jsonDecode(response.body);
    }

    if (response.statusCode == 200 ||
        response.statusCode == 201) {
      return Mensagem.fromJson(dados);
    }

    throw Exception(
      dados is Map
          ? dados['mensagem'] ??
              'Não foi possível enviar a mensagem.'
          : 'Não foi possível enviar a mensagem.',
    );
  }
}
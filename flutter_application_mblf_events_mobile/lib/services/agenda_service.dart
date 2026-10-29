import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../models/agenda_evento.dart';

class AgendaService {
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

  Future<List<AgendaEvento>> listar(
    int eventoId,
  ) async {
    final token = await _token();

    final url = Uri.parse(
      '${ApiConfig.baseUrl}/agenda/evento/$eventoId',
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
                AgendaEvento.fromJson(json),
          )
          .toList();
    }

    throw Exception(
      'Não foi possível carregar o calendário.',
    );
  }

  /// Consulta somente a programação de eventos com inscrição ativa.
  Future<List<AgendaEvento>> listarParaInscrito(int eventoId) async {
    final token = await _token();
    final url = Uri.parse('${ApiConfig.baseUrl}/agenda/evento/$eventoId/programacao');
    final response = await http.get(url, headers: {'Authorization': 'Bearer $token'});
    if (response.statusCode == 200) {
      final dados = jsonDecode(utf8.decode(response.bodyBytes)) as List;
      return dados.map((e) => AgendaEvento.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception(response.statusCode == 403 || response.statusCode == 400
        ? 'Você não tem uma inscrição ativa neste evento.'
        : 'Não foi possível carregar a programação (${response.statusCode}).');
  }

  Future<void> criar(
    int eventoId, {
    required String titulo,
    required String descricao,
    required DateTime dataInicio,
    DateTime? dataFim,
    required String tipo,
  }) async {
    final token = await _token();

    final url = Uri.parse(
      '${ApiConfig.baseUrl}/agenda/evento/$eventoId',
    );

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'titulo': titulo,
        'descricao': descricao,
        'dataInicio':
            dataInicio.toIso8601String(),
        'dataFim':
            dataFim?.toIso8601String(),
        'tipo': tipo,
      }),
    );

    if (response.statusCode != 200 &&
        response.statusCode != 201) {
      dynamic dados;

      if (response.body.isNotEmpty) {
        dados = jsonDecode(response.body);
      }

      throw Exception(
        dados is Map
            ? dados['mensagem'] ??
                'Não foi possível criar o compromisso.'
            : 'Não foi possível criar o compromisso.',
      );
    }
  }
}
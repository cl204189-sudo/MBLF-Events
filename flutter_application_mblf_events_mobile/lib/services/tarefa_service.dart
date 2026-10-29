import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../models/tarefa_evento.dart';

class TarefaService {
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

  Future<List<TarefaEvento>> listar(
    int eventoId,
  ) async {
    final token = await _token();

    final url = Uri.parse(
      '${ApiConfig.baseUrl}/tarefas/evento/$eventoId',
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
                TarefaEvento.fromJson(json),
          )
          .toList();
    }

    throw Exception(
      'Não foi possível carregar as tarefas.',
    );
  }

  Future<void> criar(
    int eventoId, {
    required String titulo,
    required String descricao,
    required String prioridade,
    required DateTime? prazo,
    int? responsavelId,
  }) async {
    final token = await _token();

    final url = Uri.parse(
      '${ApiConfig.baseUrl}/tarefas/evento/$eventoId',
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
        'prioridade': prioridade,
        'prazo': prazo?.toIso8601String(),
        'responsavelId': responsavelId,
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
                'Não foi possível criar a tarefa.'
            : 'Não foi possível criar a tarefa.',
      );
    }
  }

  Future<void> alterarStatus(
    int tarefaId,
    String status,
  ) async {
    final token = await _token();

    final url = Uri.parse(
      '${ApiConfig.baseUrl}/tarefas/$tarefaId/status?status=$status',
    );

    final response = await http.put(
      url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Não foi possível alterar o status.',
      );
    }
  }
}
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../models/inscricao.dart';

class InscricaoEventoService {
  Future<void> alterarPresencaManual({required int eventoId, required int inscricaoId,
      required bool presente, required String motivo}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) throw Exception('Usuário não autenticado');
    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/presencas/evento/$eventoId/inscricao/$inscricaoId/manual'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: jsonEncode({'presente': presente, 'motivo': motivo}),
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Não foi possível alterar a presença (HTTP ${response.statusCode}). ${response.body}');
    }
  }

  Future<List<Inscricao>> listarPorEvento(
    int eventoId,
  ) async {
    final prefs =
        await SharedPreferences.getInstance();

    final token = prefs.getString('token');

    if (token == null) {
      throw Exception(
        'Usuário não autenticado.',
      );
    }

    final url = Uri.parse(
      '${ApiConfig.baseUrl}/inscricoes/evento/$eventoId',
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
                Inscricao.fromJson(json),
          )
          .toList();
    }

    throw Exception(
      'Não foi possível carregar os inscritos.',
    );
  }
}
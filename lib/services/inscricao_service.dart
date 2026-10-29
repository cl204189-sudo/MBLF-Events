import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../models/inscricao.dart';

class InscricaoService {
  Future<List<Inscricao>> listarMinhas() async {
    final prefs =
        await SharedPreferences.getInstance();

    final token =
        prefs.getString('token');

    if (token == null) {
      throw Exception(
        'Usuário não autenticado.',
      );
    }

    final url = Uri.parse(
      '${ApiConfig.baseUrl}/inscricoes/minhas',
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
      'Não foi possível carregar suas inscrições.',
    );
  }

  Future<void> cancelar(
    int inscricaoId,
  ) async {
    final prefs =
        await SharedPreferences.getInstance();

    final token =
        prefs.getString('token');

    if (token == null) {
      throw Exception(
        'Usuário não autenticado.',
      );
    }

    final url = Uri.parse(
      '${ApiConfig.baseUrl}/inscricoes/$inscricaoId/cancelar',
    );

    final response = await http.put(
      url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      dynamic dados;

      if (response.body.isNotEmpty) {
        dados =
            jsonDecode(response.body);
      }

      throw Exception(
        dados is Map
            ? dados['mensagem'] ??
                'Erro ao cancelar inscrição.'
            : 'Erro ao cancelar inscrição.',
      );
    }
  }
}
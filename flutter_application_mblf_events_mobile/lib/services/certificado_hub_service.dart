import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../models/certificado.dart';

class CertificadoHubService {
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

  Future<List<Certificado>> listarPorEvento(
    int eventoId,
  ) async {
    final token = await _token();

    final url = Uri.parse(
      '${ApiConfig.baseUrl}/certificados/evento/$eventoId',
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
                Certificado.fromJson(json),
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
              'Não foi possível carregar os certificados.'
          : 'Não foi possível carregar os certificados.',
    );
  }

  Future<void> gerar(int inscricaoId) async {
    final token = await _token();
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/certificados/gerar/$inscricaoId'),
      headers: {'Authorization': 'Bearer $token'},
    ).timeout(const Duration(seconds: 20));
    if (response.statusCode != 200 && response.statusCode != 201) {
      String mensagem = 'Não foi possível gerar o certificado.';
      try {
        final dados = jsonDecode(response.body);
        if (dados is Map && dados['mensagem'] != null) {
          mensagem = dados['mensagem'].toString();
        }
      } catch (_) {}
      throw Exception(mensagem);
    }
  }

  Future<void> liberar(
    int certificadoId,
  ) async {
    final token = await _token();

    final url = Uri.parse(
      '${ApiConfig.baseUrl}/certificados/$certificadoId/liberar',
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
        dados = jsonDecode(response.body);
      }

      throw Exception(
        dados is Map
            ? dados['mensagem'] ??
                'Não foi possível liberar o certificado.'
            : 'Não foi possível liberar o certificado.',
      );
    }
  }
}
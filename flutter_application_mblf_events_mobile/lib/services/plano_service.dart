import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../models/plano.dart';

class PlanoService {
  Future<List<Plano>> listarAtivos() async {
    final url = Uri.parse(
      '${ApiConfig.baseUrl}/planos/ativos',
    );

    final response =
        await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> dados =
          jsonDecode(response.body);

      return dados
          .map(
            (json) =>
                Plano.fromJson(json),
          )
          .toList();
    }

    throw Exception(
      'Não foi possível carregar os planos.',
    );
  }

  Future<void> simularPagamento({
    required int eventoId,
    required int planoId,
  }) async {
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
      '${ApiConfig.baseUrl}/pagamentos/simular',
    );

    final response = await http.post(
      url,
      headers: {
        'Content-Type':
            'application/json',
        'Authorization':
            'Bearer $token',
      },
      body: jsonEncode({
        'eventoId': eventoId,
        'planoId': planoId,
      }),
    );

    dynamic dados;

    if (response.body.isNotEmpty) {
      dados =
          jsonDecode(response.body);
    }

    if (response.statusCode != 200 &&
        response.statusCode != 201) {
      throw Exception(
        dados is Map
            ? dados['mensagem'] ??
                'Não foi possível realizar o pagamento.'
            : 'Não foi possível realizar o pagamento.',
      );
    }
  }
}
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../models/certificado.dart';

class CertificadoService {
  Future<List<Certificado>>
      listarMeus() async {

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
      '${ApiConfig.baseUrl}/certificados/meus',
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

    throw Exception(
      'Não foi possível carregar os certificados.',
    );
  }
}
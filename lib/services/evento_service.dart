import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/evento.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EventoService {
  Future<List<Evento>> listarPublicos() async {
    final url = Uri.parse(
      '${ApiConfig.baseUrl}/eventos/publicos',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> dados =
          jsonDecode(response.body);

      return dados
          .map(
            (json) => Evento.fromJson(json),
          )
          .toList();
    }

    throw Exception(
      'Não foi possível carregar os eventos.',
    );
  }

  Future<Evento> buscarPorId(
  int eventoId,
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
    '${ApiConfig.baseUrl}/eventos/$eventoId',
  );

  final response = await http.get(
    url,
    headers: {
      'Authorization': 'Bearer $token',
    },
  );

  if (response.statusCode == 200) {
    return Evento.fromJson(
      jsonDecode(response.body),
    );
  }

  throw Exception(
    'Não foi possível atualizar o evento.',
  );
}
}
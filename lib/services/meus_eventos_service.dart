import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../models/evento.dart';
import '../models/evento_colaborador.dart';

class MeusEventosService {
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

  Future<int> _usuarioId() async {
    final prefs =
        await SharedPreferences.getInstance();

    final id =
        prefs.getInt('usuarioId');

    if (id == null) {
      throw Exception(
        'Usuário não identificado.',
      );
    }

    return id;
  }

  Future<List<Evento>>
      listarEventosOrganizados() async {

    final token = await _token();
    final usuarioId = await _usuarioId();

    final url = Uri.parse(
      '${ApiConfig.baseUrl}/eventos/organizador/$usuarioId',
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
                Evento.fromJson(json),
          )
          .toList();
    }

    throw Exception(
      'Não foi possível carregar os eventos organizados.',
    );
  }

  Future<List<EventoColaborador>>
    listarColaboracoes() async {

  final token = await _token();

  final url = Uri.parse(
    '${ApiConfig.baseUrl}/colaboradores/meus',
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
              EventoColaborador.fromJson(
            json,
          ),
        )
        .where(
          (colaborador) =>
              colaborador.status == 'ACEITO',
        )
        .toList();
  }

  throw Exception(
    'Não foi possível carregar as colaborações.',
  );
}
}
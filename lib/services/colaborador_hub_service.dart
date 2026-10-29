import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../models/evento_colaborador.dart';

class ColaboradorHubService {
  Future<String> _token() async {
    final prefs =
        await SharedPreferences.getInstance();

    final token = prefs.getString('token');

    if (token == null) {
      throw Exception(
        'Usuário não autenticado.',
      );
    }

    return token;
  }

  Future<List<EventoColaborador>> listar(
    int eventoId,
  ) async {
    final token = await _token();

    final url = Uri.parse(
      '${ApiConfig.baseUrl}/colaboradores/evento/$eventoId',
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
                EventoColaborador.fromJson(json),
          )
          .toList();
    }

    throw Exception(
      'Não foi possível carregar os colaboradores.',
    );
  }

  Future<void> convidar({
  required int eventoId,
  required String email,
  required String funcao,
}) async {
  final token = await _token();

  final url = Uri.parse(
    '${ApiConfig.baseUrl}/colaboradores/evento/$eventoId/convidar-email',
  );

  final response = await http.post(
    url,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode({
      'email': email,
      'funcao': funcao,
    }),
  );

  _validar(
    response,
    'Não foi possível enviar o convite.',
  );
}

  Future<void> remover({required int eventoId, required int usuarioId}) async {
    final token = await _token();
    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/colaboradores/evento/$eventoId/usuario/$usuarioId/remover'),
      headers: {'Authorization': 'Bearer $token'},
    );
    _validar(response, 'Não foi possível remover o colaborador.');
  }

  Future<void> alterarPermissoes({
    required int eventoId,
    required int usuarioId,
    required bool podeChat,
    required bool podeCalendario,
    required bool podeTarefas,
    required bool podeVerInscritos,
    required bool podeRegistrarPresencas,
    required bool podeVerRelatorios,
    required bool podeSilenciar,
    required bool podeExpulsar,
    required bool podeLiberarCertificados,
  }) async {
    final token = await _token();

    final url = Uri.parse(
      '${ApiConfig.baseUrl}/colaboradores/evento/$eventoId/usuario/$usuarioId/permissoes',
    );

    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'podeChat': podeChat,
        'podeCalendario': podeCalendario,
        'podeTarefas': podeTarefas,
        'podeVerInscritos': podeVerInscritos,
        'podeRegistrarPresencas':
            podeRegistrarPresencas,
        'podeVerRelatorios':
            podeVerRelatorios,
        'podeSilenciar': podeSilenciar,
        'podeExpulsar': podeExpulsar,
        'podeLiberarCertificados':
            podeLiberarCertificados,
      }),
    );

    _validar(
      response,
      'Não foi possível alterar as permissões.',
    );
  }

  void _validar(
    http.Response response,
    String mensagemPadrao,
  ) {
    if (response.statusCode == 200 ||
        response.statusCode == 201) {
      return;
    }

    dynamic dados;

    if (response.body.isNotEmpty) {
      dados = jsonDecode(response.body);
    }

    throw Exception(
      dados is Map
          ? dados['mensagem'] ??
              mensagemPadrao
          : mensagemPadrao,
    );
  }
}
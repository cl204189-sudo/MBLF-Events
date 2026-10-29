import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../models/notificacao.dart';

class NotificacaoService {
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

  Future<List<Notificacao>>
      listarMinhas() async {
    final token = await _token();

    final url = Uri.parse(
      '${ApiConfig.baseUrl}/notificacoes/minhas',
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
                Notificacao.fromJson(
              json,
            ),
          )
          .toList();
    }

    throw Exception(
      'Não foi possível carregar as notificações.',
    );
  }

  Future<void> aceitarConvite(
  int eventoId,
) async {
  final token = await _token();

  final url = Uri.parse(
    '${ApiConfig.baseUrl}/colaboradores/evento/$eventoId/aceitar',
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
              'Não foi possível aceitar o convite.'
          : 'Não foi possível aceitar o convite.',
    );
  }
}

Future<int> contarNaoLidas() async {
  final lista = await listarMinhas();

  return lista
      .where(
        (notificacao) =>
            !notificacao.lida,
      )
      .length;
}

Future<String?> statusConvite(
  int eventoId,
) async {
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

  if (response.statusCode != 200) {
    throw Exception(
      'Não foi possível verificar o convite.',
    );
  }

  final List<dynamic> dados =
      jsonDecode(response.body);

  for (final item in dados) {
    if (item['eventoId'] == eventoId) {
      return item['status'];
    }
  }

  return null;
}

Future<void> recusarConvite(
  int eventoId,
) async {
  final token = await _token();

  final url = Uri.parse(
    '${ApiConfig.baseUrl}/colaboradores/evento/$eventoId/recusar',
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
              'Não foi possível recusar o convite.'
          : 'Não foi possível recusar o convite.',
    );
  }
}

  Future<void> marcarComoLida(
    int id,
  ) async {
    final token = await _token();

    final url = Uri.parse(
      '${ApiConfig.baseUrl}/notificacoes/$id/lida',
    );

    final response = await http.put(
      url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Não foi possível atualizar a notificação.',
      );
    }
  }
}
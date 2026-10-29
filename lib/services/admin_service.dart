import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class AdminService {
  Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null || token.isEmpty) throw Exception('Faça login novamente.');
    return {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'};
  }

  Future<dynamic> _request(String method, String path, {Object? body, Map<String, String>? query}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path').replace(queryParameters: query);
    final headers = await _headers();
    late http.Response response;
    if (method == 'GET') {
      response = await http.get(uri, headers: headers);
    } else {
      response = await http.put(uri, headers: headers, body: body == null ? null : jsonEncode(body));
    }
    if (response.statusCode == 401) throw Exception('Sessão expirada. Entre novamente.');
    if (response.statusCode == 403) throw Exception('Acesso negado pela API.');
    if (response.statusCode < 200 || response.statusCode >= 300) {
      String msg = 'Erro ${response.statusCode} ao acessar a API.';
      try {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data is Map && data['mensagem'] != null) msg = data['mensagem'].toString();
      } catch (_) {}
      throw Exception(msg);
    }
    if (response.bodyBytes.isEmpty) return null;
    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  Future<Map<String, bool>> minhasPermissoesFuncionario() async {
    final data = await _request('GET', '/funcionario/minhas-permissoes') as Map;
    return data.map((k, v) => MapEntry(k.toString(), v == true));
  }
  Future<void> bloquearFuncionario(int id) async => _request('PUT', '/funcionario/usuarios/$id/bloquear');
  Future<void> desbloquearFuncionario(int id) async => _request('PUT', '/funcionario/usuarios/$id/desbloquear');
  Future<void> removerEventoFuncionario(int id, String motivo) async =>
      _request('PUT', '/funcionario/eventos/$id/remover', query: {'motivo': motivo});
  Future<List<Map<String, dynamic>>> usuariosFuncionario() async =>
      (await _request('GET', '/funcionario/usuarios') as List)
          .map((e) => Map<String, dynamic>.from(e as Map)).toList();
  Future<List<Map<String, dynamic>>> eventosFuncionario() async =>
      (await _request('GET', '/funcionario/eventos') as List)
          .map((e) => Map<String, dynamic>.from(e as Map)).toList();
  Future<List<Map<String, dynamic>>> usuarios() async =>
      (await _request('GET', '/usuarios/todos') as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  Future<List<Map<String, dynamic>>> eventos() async =>
      (await _request('GET', '/eventos/todos') as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  Future<List<Map<String, dynamic>>> historico() async =>
      (await _request('GET', '/historico-admin') as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  Future<void> bloquear(int id) async => _request('PUT', '/admin/usuarios/$id/bloquear');
  Future<void> desbloquear(int id) async => _request('PUT', '/admin/usuarios/$id/desbloquear');
  Future<void> removerEvento(int id, String motivo) async =>
      _request('PUT', '/admin/eventos/$id/remover', query: {'motivo': motivo});
  Future<void> tornarFuncionario(int id, Map<String, bool> permissoes) async =>
      _request('PUT', '/admin/usuarios/$id/funcionario', body: permissoes);
}

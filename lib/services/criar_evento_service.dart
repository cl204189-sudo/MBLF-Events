import 'dart:convert';
import 'package:image_picker/image_picker.dart';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';

class CriarEventoService {

  Future<void> enviarImagem({required int eventoId, required XFile imagem}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) throw Exception('Usuário não autenticado.');
    final bytes = await imagem.readAsBytes();
    if (bytes.length > 5 * 1024 * 1024) {
      throw Exception('A imagem deve ter até 5 MB.');
    }
    final extensao = imagem.name.toLowerCase().endsWith('.png') ? 'png' : 'jpg';
    final requisicao = http.MultipartRequest('POST',
        Uri.parse('${ApiConfig.baseUrl}/eventos/$eventoId/imagem'));
    requisicao.headers['Authorization'] = 'Bearer $token';
    requisicao.files.add(http.MultipartFile.fromBytes('arquivo', bytes,
        filename: 'imagem.$extensao'));
    final resposta = await http.Response.fromStream(await requisicao.send());
    if (resposta.statusCode != 200) {
      throw Exception('Não foi possível enviar a imagem (HTTP ${resposta.statusCode}).');
    }
  }

  Future<Map<String, dynamic>> criar({
    required String titulo,
    required String descricao,
    required String tipo,
    required String endereco,
    required String cidade,
    required DateTime dataInicio,
    required DateTime dataFim,
    required int cargaHoraria,
    required int vagasTotal,
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
      '${ApiConfig.baseUrl}/eventos/criar',
    );

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'titulo': titulo,
        'descricao': descricao,
        'tipo': tipo,
        'endereco': endereco,
        'cidade': cidade,
        'dataInicio':
            dataInicio.toIso8601String(),
        'dataFim':
            dataFim.toIso8601String(),
        'cargaHoraria': cargaHoraria,
        'vagasTotal': vagasTotal,
      }),
    );

    dynamic dados;

    if (response.body.isNotEmpty) {
      dados = jsonDecode(
        response.body,
      );
    }

    if (response.statusCode == 200 ||
        response.statusCode == 201) {

      return Map<String, dynamic>.from(
        dados,
      );
    }

    throw Exception(
      dados is Map
          ? dados['mensagem'] ??
              'Não foi possível criar o evento.'
          : 'Não foi possível criar o evento.',
    );
  }
  Future<Map<String, dynamic>> atualizar({
    required int id,
    required String titulo,
    required String descricao,
    required String tipo,
    required String endereco,
    required String cidade,
    required DateTime dataInicio,
    required DateTime dataFim,
    required int cargaHoraria,
    required int vagasTotal,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) {
      throw Exception('Usuário não autenticado.');
    }

    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/eventos/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'titulo': titulo,
        'descricao': descricao,
        'tipo': tipo,
        'endereco': endereco,
        'cidade': cidade,
        'dataInicio': dataInicio.toIso8601String(),
        'dataFim': dataFim.toIso8601String(),
        'cargaHoraria': cargaHoraria,
        'vagasTotal': vagasTotal,
      }),
    );

    dynamic dados;
    if (response.body.isNotEmpty) {
      try {
        dados = jsonDecode(response.body);
      } catch (_) {
        dados = null;
      }
    }

    if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 204) {
      if (dados is Map) return Map<String, dynamic>.from(dados);
      return <String, dynamic>{'id': id};
    }

    throw Exception(
      dados is Map
          ? dados['mensagem'] ?? 'Não foi possível atualizar o evento.'
          : 'Não foi possível atualizar o evento (HTTP ${response.statusCode}).',
    );
  }

}
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';

class ValidarCertificadoScreen extends StatefulWidget {
  const ValidarCertificadoScreen({super.key});
  @override
  State<ValidarCertificadoScreen> createState() => _ValidarCertificadoScreenState();
}

class _ValidarCertificadoScreenState extends State<ValidarCertificadoScreen> {
  final _controller = TextEditingController();
  bool _loading = false;
  String? _error;
  Map<String, dynamic>? _data;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _validar() async {
    final code = _controller.text.trim();
    if (code.isEmpty) {
      setState(() { _error = 'Digite o código de validação.'; _data = null; });
      return;
    }
    setState(() { _loading = true; _error = null; _data = null; });
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/certificados/validar/${Uri.encodeComponent(code)}');
      final res = await http.get(url).timeout(const Duration(seconds: 12));
      if (!mounted) return;
      if (res.statusCode == 200) {
        final json = jsonDecode(utf8.decode(res.bodyBytes));
        if (json is! Map<String, dynamic>) throw const FormatException();
        setState(() => _data = json);
      } else if (res.statusCode == 404) {
        setState(() => _error = 'Certificado não encontrado ou não liberado.');
      } else {
        setState(() => _error = 'Não foi possível validar (HTTP ${res.statusCode}).');
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'Falha na conexão com a API.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Validar certificado')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        const Icon(Icons.verified_outlined, size: 50),
        const SizedBox(height: 12),
        const Text('Consulte a autenticidade de um certificado liberado pelo MBLF Events.',
          textAlign: TextAlign.center),
        const SizedBox(height: 20),
        TextField(
          controller: _controller,
          maxLength: 100,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) { if (!_loading) _validar(); },
          decoration: const InputDecoration(
            labelText: 'Código de validação',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.key),
          ),
        ),
        FilledButton.icon(
          onPressed: _loading ? null : _validar,
          icon: const Icon(Icons.search),
          label: Text(_loading ? 'Consultando...' : 'Validar certificado'),
        ),
        if (_error != null) Padding(
          padding: const EdgeInsets.only(top: 18),
          child: Card(child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(_error!, style: TextStyle(color: colors.error)),
          )),
        ),
        if (_data != null) Padding(
          padding: const EdgeInsets.only(top: 18),
          child: Card(child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(Icons.verified, color: colors.primary),
                const SizedBox(width: 8),
                const Text('Certificado válido',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ]),
              const Divider(height: 24),
              _info('Participante', _data!['nomeParticipante']),
              _info('Evento', _data!['tituloEvento']),
              _info('Carga horária', _data!['cargaHoraria'] == null
                  ? null : '${_data!['cargaHoraria']} horas'),
              _info('Código', _data!['codigo']),
              _info('Data da liberação', _data!['dataLiberacao']),
            ]),
          )),
        ),
      ]),
    );
  }

  Widget _info(String label, dynamic value) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 3),
      SelectableText((value ?? 'Não informado').toString()),
    ]),
  );
}

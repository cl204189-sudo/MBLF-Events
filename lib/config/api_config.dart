import 'package:flutter/foundation.dart';

/// Endereco base da API Spring Boot, sem barra no final.
///
/// Para testar de qualquer rede, use um endereco HTTPS acessivel ao celular:
/// flutter build apk --release --dart-define=API_BASE_URL=https://SEU-TUNEL.trycloudflare.com
///
/// Sem --dart-define, usa localhost no navegador/desktop e 10.0.2.2
/// no emulador Android. Em celular fisico, informe API_BASE_URL.
class ApiConfig {
  static const String _configurada = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl => _configurada.isNotEmpty
      ? _configurada.replaceAll(RegExp(r'/+$'), '')
      : (kIsWeb || defaultTargetPlatform != TargetPlatform.android
          ? 'http://localhost:8080'
          : 'http://10.0.2.2:8080');
}

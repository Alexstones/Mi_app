import 'dart:convert';

import 'package:http/http.dart' as http;

import 'iot_alert_service.dart';

/// Cliente HTTP del ESP32. No genera datos: siempre consulta el dispositivo.
class Esp32HttpSource {
  Esp32HttpSource({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static Uri parseEndpoint(String value) {
    final uri = Uri.tryParse(value.trim());
    if (uri == null ||
        !uri.hasAuthority ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        uri.userInfo.isNotEmpty) {
      throw const FormatException('Ingresa una URL HTTP(S) válida del ESP32.');
    }
    return uri;
  }

  Future<Esp32Telemetry> fetch(String endpoint) async {
    final uri = parseEndpoint(endpoint);
    final response = await _client.get(uri).timeout(const Duration(seconds: 6));
    if (response.statusCode != 200) {
      throw StateError('ESP32 respondió HTTP ${response.statusCode}.');
    }
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('El ESP32 debe devolver un objeto JSON.');
    }
    return Esp32Telemetry.fromJson(decoded);
  }

  void dispose() => _client.close();
}

import 'database_helper.dart';

/// Fotografía de sensores enviada por un ESP32 a través de JSON.
class Esp32Telemetry {
  final String nodeId;
  final String location;
  final double? temperature;
  final double? humidity;

  const Esp32Telemetry({
    required this.nodeId,
    required this.location,
    this.temperature,
    this.humidity,
  });

  factory Esp32Telemetry.fromJson(Map<String, dynamic> json) {
    final id = (json['nodeId'] ?? json['node_id'] ?? 'ESP32_01').toString().trim();
    final location = (json['location'] ?? json['ubicacion'] ?? 'Sin ubicación')
        .toString().trim();
    final temperature = _readNumber(
      json['temperature'] ?? json['temperature_celsius'] ?? json['temperatura'],
      'temperature',
    );
    final humidity = _readNumber(
      json['humidity'] ?? json['humedad'],
      'humidity',
    );

    if (id.isEmpty || id.length > 100) {
      throw const FormatException('El identificador del nodo no es válido.');
    }
    if (temperature == null && humidity == null) {
      throw const FormatException(
        'El ESP32 debe enviar temperature y/o humidity.',
      );
    }
    if (humidity != null && (humidity < 0 || humidity > 100)) {
      throw const FormatException('La humedad debe estar entre 0 y 100%.');
    }
    return Esp32Telemetry(
      nodeId: id,
      location: location.isEmpty ? 'Sin ubicación' : location,
      temperature: temperature,
      humidity: humidity,
    );
  }

  static double? _readNumber(Object? raw, String field) {
    if (raw == null) return null;
    final value = raw is num ? raw.toDouble() : double.tryParse(raw.toString());
    if (value == null || !value.isFinite) {
      throw FormatException('$field debe ser un número finito.');
    }
    return value;
  }
}

/// Aplica la misma regla de negocio para todas las lecturas reales del hardware.
class IoTAlertService {
  IoTAlertService({DatabaseHelper? database})
      : _database = database ?? DatabaseHelper.instance;

  final DatabaseHelper _database;

  Future<IoTInsertSummary> record(
    Esp32Telemetry telemetry, {
    double temperatureThreshold = 35.0,
    DateTime? recordedAt,
  }) {
    if (!temperatureThreshold.isFinite) {
      throw const FormatException('El umbral debe ser un número finito.');
    }
    return _database.saveIotTelemetry(
      nodeId: telemetry.nodeId,
      location: telemetry.location,
      temperature: telemetry.temperature,
      humidity: telemetry.humidity,
      temperatureThreshold: temperatureThreshold,
      timestamp: (recordedAt ?? DateTime.now()).toUtc().toIso8601String(),
    );
  }
}

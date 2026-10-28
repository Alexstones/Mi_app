import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mi_app/database_helper.dart';
import 'package:mi_app/esp32_http_source.dart';
import 'package:mi_app/iot_alert_service.dart';

void main() {
  test('ESP32: analiza temperatura y humedad y exige valores válidos', () {
    final sample = Esp32Telemetry.fromJson({
      'nodeId': 'ESP32_TEST_A3',
      'location': 'Aula',
      'temperature': 36.2,
      'humidity': 61,
    });
    expect(sample.temperature, 36.2);
    expect(sample.humidity, 61);
    expect(
      () => Esp32Telemetry.fromJson({'nodeId': 'x'}),
      throwsFormatException,
    );
    expect(
      () => Esp32Telemetry.fromJson({'temperature': 'NaN'}),
      throwsFormatException,
    );
    expect(
      () => Esp32Telemetry.fromJson({'humidity': 110}),
      throwsFormatException,
    );
  });

  test('HTTP: consume JSON real del endpoint y rechaza respuestas inválidas',
      () async {
    final source = Esp32HttpSource(
      client: MockClient((request) async {
        expect(request.url.path, '/reading');
        return http.Response(
          jsonEncode({'nodeId': 'ESP32_HTTP', 'temperature': 39.2}),
          200,
        );
      }),
    );
    final sample = await source.fetch('http://192.168.4.1/reading');
    expect(sample.nodeId, 'ESP32_HTTP');
    expect(sample.temperature, 39.2);
    source.dispose();

    expect(
      () => Esp32HttpSource.parseEndpoint('file:///etc/passwd'),
      throwsFormatException,
    );
  });

  test('SQLite: persiste lecturas, nodo y alertas sólo sobre el umbral',
      () async {
    final service = IoTAlertService();
    final db = DatabaseHelper.instance;
    const node = 'ESP32_TEST_ACTIVIDAD_3';
    final before = await db.getAllAlerts();
    final initial = before.where((alert) => alert.nodoId == node).length;

    final atLimit = await service.record(
      const Esp32Telemetry(
        nodeId: node,
        location: 'Laboratorio',
        temperature: 35.0,
        humidity: 50,
      ),
      recordedAt: DateTime.utc(2026, 10, 28),
    );
    expect(atLimit.readings, 2);
    expect(atLimit.alerts, 0);

    final exceeded = await service.record(
      const Esp32Telemetry(
        nodeId: node,
        location: 'Laboratorio',
        temperature: 36.5,
      ),
      temperatureThreshold: 35,
      recordedAt: DateTime.utc(2026, 10, 28, 1),
    );
    expect(exceeded.readings, 1);
    expect(exceeded.alerts, 1);

    final alerts = await db.getAllAlerts();
    final newAlerts = alerts.where((alert) => alert.nodoId == node).toList();
    expect(newAlerts.length, initial + 1);
    expect(newAlerts.first.valor, 36.5);
    expect(newAlerts.first.umbral, 35);
    expect(newAlerts.first.lecturaId, isNotNull);

    final readings = await db.getAllReadings();
    expect(
      readings.any((r) =>
          r.nodoId == node && r.sensorType == 'humidity' && r.value == 50),
      isTrue,
    );
    expect(
      readings.any((r) =>
          r.nodoId == node &&
          r.sensorType == 'temperature' &&
          r.value == 36.5 &&
          r.umbral == 35),
      isTrue,
    );
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:mi_app/database_helper.dart';

void main() {
  group('DatabaseHelper IoT tests (Módulo 2 SQLite)', () {
    test('modelo NodoIoT mapea correctamente a Map y fromMap', () {
      final nodo = NodoIoT(
          id: 'ESP32_01', nombre: 'Sensor Invernadero', ubicacion: 'Zona Sur');
      final map = nodo.toMap();
      final fromMap = NodoIoT.fromMap(map);

      expect(fromMap.id, 'ESP32_01');
      expect(fromMap.nombre, 'Sensor Invernadero');
      expect(fromMap.ubicacion, 'Zona Sur');
    });

    test('modelo AlertaNodo castea números correctamente y mapea a Map', () {
      final alerta = AlertaNodo(
        id: 1,
        nodoId: 'ESP32_01',
        tipo: 'temperature',
        valor: 37.8,
        timestamp: '2026-09-30 12:00:00',
      );
      final map = alerta.toMap();
      final fromMap = AlertaNodo.fromMap(map);

      expect(fromMap.nodoId, 'ESP32_01');
      expect(fromMap.valor, 37.8);
      expect(fromMap.tipo, 'temperature');
    });

    test('modelo SensorReading soporta columna migrada ubicacion_nodo', () {
      final reading = SensorReading(
        sensorType: 'temperature',
        value: 29.5,
        timestamp: '2026-09-30 12:00:00',
        ubicacionNodo: 'Invernadero A',
      );

      final map = reading.toMap();
      expect(map['ubicacion_nodo'], 'Invernadero A');

      final fromMap = SensorReading.fromMap(map);
      expect(fromMap.ubicacionNodo, 'Invernadero A');
    });

    test('insertAlerta y getAlertasPorTipo registran y filtran alertas',
        () async {
      final helper = DatabaseHelper.instance;
      await helper.insertAlerta(
        AlertaNodo(
          nodoId: 'ESP32_TEST',
          tipo: 'temperature',
          valor: 39.2,
          timestamp: '2026-09-30 12:30:00',
        ),
      );

      final alertas = await helper.getAlertasPorTipo('temperature');
      expect(alertas.any((a) => a.nodoId == 'ESP32_TEST' && a.valor == 39.2),
          isTrue);
    });

    test('insertBatchReadings guarda lecturas y permite consultarlas por tipo',
        () async {
      final helper = DatabaseHelper.instance;
      await helper.insertBatchReadings([
        SensorReading(
          sensorType: 'temperature',
          value: 24.5,
          timestamp: '2026-10-01T12:00:00Z',
        ),
        SensorReading(
          sensorType: 'humidity',
          value: 61.0,
          timestamp: '2026-10-01T12:00:01Z',
        ),
      ]);

      final readings = await helper.getReadingsByType('temperature');
      expect(readings.any((reading) => reading.value == 24.5), isTrue);
      expect(readings.every((reading) => reading.sensorType == 'temperature'), isTrue);
    });

    test('permite guardar y editar manualmente lecturas de temperatura y humedad', () async {
      final helper = DatabaseHelper.instance;

      // 1. Guardar lectura manual de humedad
      final newId = await helper.insertReading(
        SensorReading(
          sensorType: 'humidity',
          value: 55.0,
          timestamp: '2026-10-07 14:00:00',
          ubicacionNodo: 'Invernadero B',
        ),
      );
      expect(newId, isPositive);

      // 2. Editar manualmente la lectura
      final updatedReading = SensorReading(
        id: newId,
        sensorType: 'humidity',
        value: 78.5, // Nuevo valor editado manualmente
        timestamp: '2026-10-07 14:05:00',
        ubicacionNodo: 'Invernadero B - Zona Húmeda',
      );
      final affected = await helper.updateReading(updatedReading);
      expect(affected, 1);

      // 3. Verificar que se actualizó
      final all = await helper.getAllReadings();
      final edited = all.firstWhere((r) => r.id == newId);
      expect(edited.value, 78.5);
      expect(edited.ubicacionNodo, 'Invernadero B - Zona Húmeda');

      // 4. Eliminar
      final deleted = await helper.deleteReading(newId);
      expect(deleted, 1);
    });
  });
}

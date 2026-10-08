import 'package:flutter_test/flutter_test.dart';
import 'package:mi_app/csv_node_manager.dart';

void main() {
  group('Práctica Guiada 1.2: CsvNodeManager Checksum SHA-256 tests', () {
    final manager = CsvNodeManager();

    test('generateCsvWithChecksum genera cabecera # CHECKSUM: con hash SHA-256', () {
      final rows = [
        ['id', 'nombre', 'ubicacion'],
        ['ESP32_01', 'Sensor Invernadero', 'Zona Norte'],
      ];

      final csvString = manager.generateCsvWithChecksum(rows);

      expect(csvString.startsWith('# CHECKSUM:'), isTrue);
      expect(csvString.contains('ESP32_01,Sensor Invernadero,Zona Norte'), isTrue);
    });

    test('verifyCsvContent aprueba archivo íntegro sin alteraciones', () {
      final rows = [
        ['id', 'nombre', 'ubicacion'],
        ['ESP32_01', 'Sensor Invernadero', 'Zona Norte'],
        ['ESP32_02', 'Sensor Almacén', 'Zona Central'],
      ];

      final originalContent = manager.generateCsvWithChecksum(rows);
      final result = manager.verifyCsvContent(originalContent);

      expect(result.isValid, isTrue);
      expect(result.wasAlteredManually, isFalse);
      expect(result.parsedCsv?.length, 3);
      expect(result.parsedCsv?[1][0], 'ESP32_01');
    });

    test('detecta modificación manual en Excel o texto y lanza ALERTA DE SEGURIDAD', () {
      final rows = [
        ['id', 'nombre', 'ubicacion'],
        ['ESP32_01', 'Sensor Invernadero', 'Zona Norte'],
      ];

      final originalContent = manager.generateCsvWithChecksum(rows);

      // Simular que alguien abrió el archivo en Excel y cambió "Zona Norte" por "Zona Sur"
      final alteredContent = originalContent.replaceAll('Zona Norte', 'Zona Sur');

      final result = manager.verifyCsvContent(alteredContent);

      expect(result.isValid, isFalse);
      expect(result.wasAlteredManually, isTrue);
      expect(result.message.contains('ALERTA DE SEGURIDAD'), isTrue);
      expect(result.message.contains('alterado o corrupto'), isTrue);
      expect(result.originalChecksum != result.recalculatedChecksum, isTrue);
    });

    test('detecta modificación de valores numéricos o IDs alterados', () {
      final rows = [
        ['id', 'valor'],
        ['ESP32_01', 25.5],
      ];

      final original = manager.generateCsvWithChecksum(rows);

      // Modificación manual en Excel de 25.5 a 99.9
      final manualEdit = original.replaceAll('25.5', '99.9');

      final result = manager.verifyCsvContent(manualEdit);

      expect(result.isValid, isFalse);
      expect(result.wasAlteredManually, isTrue);
    });

    test('falla si falta la cabecera # CHECKSUM:', () {
      const csvSinChecksum = 'id,nombre\nESP32_01,Invernadero';
      final result = manager.verifyCsvContent(csvSinChecksum);

      expect(result.isValid, isFalse);
      expect(result.message.contains('CHECKSUM'), isTrue);
    });
  });
}


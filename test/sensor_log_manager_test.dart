import 'package:flutter_test/flutter_test.dart';
import 'package:mi_app/sensor_log_manager.dart';

void main() {
  group('SensorLogManager', () {
    final manager = SensorLogManager();

    test('genera 100 lecturas con timestamp y checksum íntegro', () {
      final content = manager.generateLog(startTime: DateTime.utc(2026, 1, 1));
      final result = manager.verifyLogContent(content);

      expect(result.isValid, isTrue);
      expect(result.parsedCsv, hasLength(101));
      expect(result.parsedCsv!.first, ['timestamp', 'temperature_celsius']);
      expect(result.parsedCsv![1][0], '2026-01-01T00:00:00.000Z');
    });

    test('detecta alteraciones en el log', () {
      final content = manager.generateLog(startTime: DateTime.utc(2026, 1, 1));
      final corrupted = content.replaceFirst('20.0', '99.0');
      final result = manager.verifyLogContent(corrupted);

      expect(result.isValid, isFalse);
      expect(result.wasAlteredManually, isTrue);
    });
  });
}

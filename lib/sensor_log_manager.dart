import 'csv_node_manager.dart';
import 'encrypted_json_storage.dart';

class SensorLogManager {
  SensorLogManager({
    EncryptedJsonStorage? storage,
    CsvNodeManager? csvManager,
  })  : _storage = storage ?? EncryptedJsonStorage(),
        _csvManager = csvManager ?? CsvNodeManager();

  static const filename = 'sensor_readings.csv';
  final EncryptedJsonStorage _storage;
  final CsvNodeManager _csvManager;

  String generateLog({DateTime? startTime}) {
    final startedAt = startTime ?? DateTime.now();
    final rows = <List<dynamic>>[
      ['timestamp', 'temperature_celsius'],
      for (var index = 0; index < 100; index++)
        [
          startedAt.add(Duration(seconds: index)).toIso8601String(),
          (20 + (index % 150) / 10).toStringAsFixed(1),
        ],
    ];
    return _csvManager.generateCsvWithChecksum(rows);
  }

  CsvVerificationResult verifyLogContent(String content) =>
      _csvManager.verifyCsvContent(content);

  Future<String> generateAndSave({DateTime? startTime}) {
    return _storage.saveCsv(filename, generateLog(startTime: startTime));
  }

  Future<CsvVerificationResult> verifySavedLog() async {
    final content = await _storage.readCsv(filename);
    if (content == null) {
      return const CsvVerificationResult(
        isValid: false,
        message: 'No se encontró un log de sensores para validar.',
      );
    }
    return _csvManager.verifyCsvContent(content);
  }
}

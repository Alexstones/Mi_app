import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'node_file_storage.dart';

/// Resultado de la verificación de integridad
class CsvVerificationResult {
  final bool isValid;
  final String message;
  final String? originalChecksum;
  final String? recalculatedChecksum;
  final List<List<dynamic>>? parsedCsv;
  final bool wasAlteredManually;

  const CsvVerificationResult({
    required this.isValid,
    required this.message,
    this.originalChecksum,
    this.recalculatedChecksum,
    this.parsedCsv,
    this.wasAlteredManually = false,
  });
}

class CsvNodeManager {
  final NodeFileStorage _fileStorage = getNodeFileStorage();

  /// Datos de ejemplo de Nodos IoT para la configuración
  static List<List<dynamic>> getDefaultNodes() {
    return [
      ['id', 'nombre', 'ubicacion', 'tipo_sensor'],
      ['ESP32_01', 'Sensor Invernadero', 'Zona Norte', 'temperature'],
      ['ESP32_02', 'Sensor Almacén', 'Zona Central', 'humidity'],
      ['ESP32_03', 'Sensor Cultivo', 'Zona Sur', 'soil_moisture'],
    ];
  }

  /// Genera la cadena de texto CSV con la cabecera # CHECKSUM:<sha256>
  String generateCsvWithChecksum(List<List<dynamic>> rows) {
    // Convertir lista a formato CSV y asegurar formato estandarizado
    String csvData = const ListToCsvConverter(eol: '\n').convert(rows).trim();

    // Calcular Checksum SHA-256 para validación de integridad
    var bytes = utf8.encode(csvData);
    var checksum = sha256.convert(bytes).toString();

    // Guardar cabecera con checksum e información de nodos
    return '# CHECKSUM:$checksum\n$csvData\n';
  }

  /// Verifica el contenido CSV validando el Checksum SHA-256 contra modificaciones manuales en Excel
  CsvVerificationResult verifyCsvContent(String fileContent) {
    if (fileContent.trim().isEmpty) {
      return const CsvVerificationResult(
        isValid: false,
        message: 'El archivo CSV está vacío.',
      );
    }

    // Normalizar saltos de línea (\r\n de Windows/Excel a \n)
    final normalized = fileContent.replaceAll('\r\n', '\n');

    // Buscar cabecera # CHECKSUM: tolerando comas añadidas por Excel (# CHECKSUM:hash,,,) o comillas
    final checksumRegex = RegExp(r'#\s*CHECKSUM:\s*([a-fA-F0-9]{64})');
    final checksumMatch = checksumRegex.firstMatch(normalized);

    if (checksumMatch == null) {
      return const CsvVerificationResult(
        isValid: false,
        message: 'El archivo no contiene la cabecera "# CHECKSUM:". No es un archivo de configuración válido.',
      );
    }

    final originalChecksum = checksumMatch.group(1)!.toLowerCase();

    // Extraer las líneas de datos posteriores a la cabecera del Checksum
    final lines = normalized.split('\n');
    final headerIndex = lines.indexWhere((l) => l.contains('CHECKSUM:'));
    String csvBody = lines.sublist(headerIndex + 1).join('\n').trim();

    // Calcular el Checksum de los datos recibidos
    var recalculatedChecksum = sha256.convert(utf8.encode(csvBody)).toString().toLowerCase();

    // Si coincide exactamente
    if (originalChecksum == recalculatedChecksum) {
      List<List<dynamic>> parsedCsv = const CsvToListConverter(eol: '\n').convert(csvBody);
      return CsvVerificationResult(
        isValid: true,
        message: 'Datos de nodos válidos cargados correctamente.',
        originalChecksum: originalChecksum,
        recalculatedChecksum: recalculatedChecksum,
        parsedCsv: parsedCsv,
      );
    } else {
      // Requisito: detectar alteración manual en Excel o editor
      return CsvVerificationResult(
        isValid: false,
        wasAlteredManually: true,
        originalChecksum: originalChecksum,
        recalculatedChecksum: recalculatedChecksum,
        message: 'ALERTA DE SEGURIDAD: El archivo CSV ha sido alterado o corrupto. '
            'Se detectó que el archivo fue modificado manualmente después de ser exportado.',
      );
    }
  }

  /// Paso 2: Exportar a archivo con Checksum SHA-256
  Future<String> exportNodesToCsv(List<List<dynamic>> rows) async {
    final fileContent = generateCsvWithChecksum(rows);
    return await _fileStorage.writeConfig(fileContent);
  }

  /// Paso 2: Verificar e importar desde ruta o almacenamiento de archivo
  Future<bool> verifyAndImportCsv(String filePath) async {
    try {
      final fileContent = await _fileStorage.readConfig(filePath);
      if (fileContent == null) return false;

      final result = verifyCsvContent(fileContent);
      if (result.isValid) {
        debugPrint('Datos de nodos válidos cargados correctamente: ${result.parsedCsv}');
        return true;
      } else {
        debugPrint(result.message);
        return false;
      }
    } catch (e) {
      debugPrint('Error al verificar archivo CSV: $e');
      return false;
    }
  }
}


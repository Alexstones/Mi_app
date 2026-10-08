import 'dart:convert';

/// Utilería para convertir estructuras JSON (Map o List) en formato CSV estándar (RFC 4180).
class CsvConverter {
  const CsvConverter._();

  /// Convierte un objeto o lista JSON decodificado a una cadena CSV.
  static String convertJsonToCsv(dynamic json) {
    if (json is List) {
      return _convertListToCsv(json);
    } else if (json is Map) {
      return _convertMapToCsv(json);
    } else {
      throw const FormatException(
        'El contenido debe ser un objeto JSON ({...}) o una lista ([...]).',
      );
    }
  }

  static String _convertListToCsv(List<dynamic> list) {
    if (list.isEmpty) {
      return '';
    }

    // Si todos los elementos son mapas (filas con columnas)
    if (list.every((item) => item is Map)) {
      final headers = <String>[];
      for (final item in list) {
        for (final key in (item as Map).keys) {
          final keyStr = key.toString();
          if (!headers.contains(keyStr)) {
            headers.add(keyStr);
          }
        }
      }

      final rows = <List<String>>[];
      rows.add(headers);

      for (final item in list) {
        final map = item as Map;
        final row = headers.map((header) {
          final value = map[header];
          return _formatValue(value);
        }).toList();
        rows.add(row);
      }

      return _encodeCsv(rows);
    }

    // Lista de elementos primitivos o mixtos
    final rows = <List<String>>[
      ['valor'],
      ...list.map((item) => [_formatValue(item)]),
    ];
    return _encodeCsv(rows);
  }

  static String _convertMapToCsv(Map<dynamic, dynamic> map) {
    if (map.isEmpty) {
      return '';
    }

    // Caso 1: El mapa envuelve una lista de registros, ej: {"datos": [...]} o {"usuarios": [...]}
    if (map.length == 1 && map.values.first is List) {
      final list = map.values.first as List;
      if (list.isNotEmpty && list.first is Map) {
        return _convertListToCsv(list);
      }
    }

    // Caso 2: Todos los valores del mapa son mapas (ej: {"usr1": {...}, "usr2": {...}})
    if (map.values.every((v) => v is Map)) {
      final subHeaders = <String>[];
      for (final v in map.values) {
        for (final key in (v as Map).keys) {
          final keyStr = key.toString();
          if (!subHeaders.contains(keyStr)) {
            subHeaders.add(keyStr);
          }
        }
      }

      final headers = ['clave', ...subHeaders];
      final rows = <List<String>>[headers];

      for (final entry in map.entries) {
        final subMap = entry.value as Map;
        final row = <String>[entry.key.toString()];
        for (final header in subHeaders) {
          row.add(_formatValue(subMap[header]));
        }
        rows.add(row);
      }

      return _encodeCsv(rows);
    }

    // Caso 3: Objeto único con pares clave-valor (ej: {"nombre": "Ana", "activo": true})
    final headers = map.keys.map((k) => k.toString()).toList();
    final row = headers.map((k) => _formatValue(map[k])).toList();

    return _encodeCsv([headers, row]);
  }

  static String _formatValue(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is num || value is bool) return value.toString();
    return jsonEncode(value);
  }

  static String _encodeCsv(List<List<String>> rows) {
    return rows.map((row) => row.map(_escapeCell).join(',')).join('\r\n');
  }

  static String _escapeCell(String cell) {
    if (cell.contains(',') ||
        cell.contains('"') ||
        cell.contains('\n') ||
        cell.contains('\r')) {
      return '"${cell.replaceAll('"', '""')}"';
    }
    return cell;
  }

  /// Convierte una cadena CSV en formato JSON decodificado (Map o List).
  static dynamic convertCsvToJson(String csvContent) {
    final rows = parseCsv(csvContent);
    if (rows.isEmpty) {
      return <String, dynamic>{};
    }

    final headers = rows.first.map((h) => h.trim()).toList();
    if (headers.isEmpty || (headers.length == 1 && headers.first.isEmpty)) {
      return <String, dynamic>{};
    }

    if (rows.length == 1) {
      // Solo cabeceras
      final singleMap = <String, dynamic>{};
      for (final h in headers) {
        singleMap[h] = '';
      }
      return singleMap;
    }

    final records = <Map<String, dynamic>>[];

    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.length == 1 && row.first.trim().isEmpty && i == rows.length - 1) {
        continue;
      }

      final map = <String, dynamic>{};
      for (int h = 0; h < headers.length; h++) {
        final header = headers[h];
        final rawValue = h < row.length ? row[h] : '';
        map[header] = _parseScalar(rawValue);
      }
      records.add(map);
    }

    if (records.length == 1) {
      return records.first;
    }
    return records;
  }

  /// Parsea una cadena CSV según la especificación RFC 4180.
  static List<List<String>> parseCsv(String input) {
    final rows = <List<String>>[];
    if (input.trim().isEmpty) {
      return rows;
    }

    final currentRow = <String>[];
    final currentCell = StringBuffer();
    bool insideQuotes = false;
    int i = 0;

    while (i < input.length) {
      final char = input[i];

      if (insideQuotes) {
        if (char == '"') {
          if (i + 1 < input.length && input[i + 1] == '"') {
            currentCell.write('"');
            i += 2;
            continue;
          } else {
            insideQuotes = false;
            i++;
            continue;
          }
        } else {
          currentCell.write(char);
          i++;
          continue;
        }
      } else {
        if (char == '"') {
          insideQuotes = true;
          i++;
          continue;
        } else if (char == ',') {
          currentRow.add(currentCell.toString());
          currentCell.clear();
          i++;
          continue;
        } else if (char == '\r') {
          if (i + 1 < input.length && input[i + 1] == '\n') {
            i++;
          }
          currentRow.add(currentCell.toString());
          currentCell.clear();
          rows.add(List<String>.from(currentRow));
          currentRow.clear();
          i++;
          continue;
        } else if (char == '\n') {
          currentRow.add(currentCell.toString());
          currentCell.clear();
          rows.add(List<String>.from(currentRow));
          currentRow.clear();
          i++;
          continue;
        } else {
          currentCell.write(char);
          i++;
          continue;
        }
      }
    }

    currentRow.add(currentCell.toString());
    if (currentRow.isNotEmpty && (currentRow.length > 1 || currentRow.first.isNotEmpty)) {
      rows.add(currentRow);
    }

    return rows;
  }

  static dynamic _parseScalar(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '';
    if (trimmed.toLowerCase() == 'true') return true;
    if (trimmed.toLowerCase() == 'false') return false;

    final intVal = int.tryParse(trimmed);
    if (intVal != null) return intVal;

    final doubleVal = double.tryParse(trimmed);
    if (doubleVal != null) return doubleVal;

    if ((trimmed.startsWith('{') && trimmed.endsWith('}')) ||
        (trimmed.startsWith('[') && trimmed.endsWith(']'))) {
      try {
        return jsonDecode(trimmed);
      } catch (_) {}
    }

    return value;
  }
}

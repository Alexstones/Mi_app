import 'package:flutter_test/flutter_test.dart';
import 'package:mi_app/csv_converter.dart';

void main() {
  group('CsvConverter', () {
    test('convierte un mapa simple a CSV (1 fila)', () {
      final json = {'nombre': 'Ana', 'activo': true};
      final csv = CsvConverter.convertJsonToCsv(json);
      expect(csv, 'nombre,activo\r\nAna,true');
    });

    test('convierte una lista de mapas a CSV con cabeceras y múltiples filas', () {
      final json = [
        {'id': 1, 'nombre': 'Ana', 'activo': true},
        {'id': 2, 'nombre': 'Carlos', 'activo': false},
      ];
      final csv = CsvConverter.convertJsonToCsv(json);
      expect(csv, 'id,nombre,activo\r\n1,Ana,true\r\n2,Carlos,false');
    });

    test('maneja mapas con claves disjuntas en una lista', () {
      final json = [
        {'id': 1, 'nombre': 'Ana'},
        {'id': 2, 'ciudad': 'Bogotá'},
      ];
      final csv = CsvConverter.convertJsonToCsv(json);
      expect(csv, 'id,nombre,ciudad\r\n1,Ana,\r\n2,,Bogotá');
    });

    test('escapa caracteres especiales como comas, comillas y saltos de línea', () {
      final json = {
        'comentario': 'Hola, "mundo"\nsegunda línea',
      };
      final csv = CsvConverter.convertJsonToCsv(json);
      expect(
        csv,
        'comentario\r\n"Hola, ""mundo""\nsegunda línea"',
      );
    });

    test('convierte un mapa de mapas con clave identificadora', () {
      final json = {
        'usr1': {'nombre': 'Ana', 'edad': 25},
        'usr2': {'nombre': 'Luis', 'edad': 30},
      };
      final csv = CsvConverter.convertJsonToCsv(json);
      expect(csv, 'clave,nombre,edad\r\nusr1,Ana,25\r\nusr2,Luis,30');
    });

    test('extrae automáticamente una lista envuelta en un mapa', () {
      final json = {
        'usuarios': [
          {'nombre': 'Ana'},
          {'nombre': 'Pedro'},
        ]
      };
      final csv = CsvConverter.convertJsonToCsv(json);
      expect(csv, 'nombre\r\nAna\r\nPedro');
    });

    test('convierte una lista de primitivos con cabecera valor', () {
      final json = ['Manzana', 'Pera', 'Plátano'];
      final csv = CsvConverter.convertJsonToCsv(json);
      expect(csv, 'valor\r\nManzana\r\nPera\r\nPlátano');
    });

    test('lanza FormatException si no es ni lista ni mapa', () {
      expect(
        () => CsvConverter.convertJsonToCsv('un string'),
        throwsA(isA<FormatException>()),
      );
    });

    test('convierte CSV simple a un objeto JSON (1 registro)', () {
      const csv = 'nombre,activo\r\nAna,true';
      final json = CsvConverter.convertCsvToJson(csv);
      expect(json, {'nombre': 'Ana', 'activo': true});
    });

    test('convierte CSV con múltiples filas a una lista JSON con tipos inferidos', () {
      const csv = 'id,nombre,edad,activo\r\n1,Ana,25,true\r\n2,Carlos,30,false';
      final json = CsvConverter.convertCsvToJson(csv);
      expect(json, [
        {'id': 1, 'nombre': 'Ana', 'edad': 25, 'activo': true},
        {'id': 2, 'nombre': 'Carlos', 'edad': 30, 'activo': false},
      ]);
    });

    test('maneja valores con comillas y comas escapadas al importar', () {
      const csv = 'comentario\r\n"Hola, ""mundo""\nsegunda línea"';
      final json = CsvConverter.convertCsvToJson(csv);
      expect(json, {
        'comentario': 'Hola, "mundo"\nsegunda línea',
      });
    });
  });
}

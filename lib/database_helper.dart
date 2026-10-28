import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Modelo de Nodo IoT (Entidad 1 en relación 1:N)
class NodoIoT {
  final String id; // ej. 'ESP32_01'
  final String nombre;
  final String ubicacion;

  NodoIoT({
    required this.id,
    required this.nombre,
    required this.ubicacion,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'ubicacion': ubicacion,
    };
  }

  factory NodoIoT.fromMap(Map<String, dynamic> map) {
    return NodoIoT(
      id: map['id'] as String,
      nombre: map['nombre'] as String,
      ubicacion: map['ubicacion'] as String,
    );
  }
}

/// Modelo de Alerta disparada por umbral (Entidad N en relación 1:N)
class AlertaNodo {
  final int? id;
  final String nodoId;
  final String tipo; // 'temperature', 'humidity'
  final double valor;
  final String timestamp;
  final double? umbral;
  final int? lecturaId;

  AlertaNodo({
    this.id,
    required this.nodoId,
    required this.tipo,
    required this.valor,
    required this.timestamp,
    this.umbral,
    this.lecturaId,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'nodoId': nodoId,
      'tipo': tipo,
      'valor': valor,
      'timestamp': timestamp,
      if (umbral != null) 'umbral': umbral,
      if (lecturaId != null) 'lectura_id': lecturaId,
    };
  }

  factory AlertaNodo.fromMap(Map<String, dynamic> map) {
    return AlertaNodo(
      id: map['id'] as int?,
      nodoId: map['nodoId'] as String,
      tipo: map['tipo'] as String,
      valor: (map['valor'] as num).toDouble(),
      timestamp: map['timestamp'] as String,
      umbral: (map['umbral'] as num?)?.toDouble(),
      lecturaId: map['lectura_id'] as int?,
    );
  }
}

/// Modelo SensorReading con migración V2 (columna ubicacion_nodo)
class SensorReading {
  final int? id;
  final String sensorType; // 'temperature', 'humidity'
  final double value;
  final String timestamp;
  final String? ubicacionNodo;
  final String? nodoId;
  final double? umbral;

  SensorReading({
    this.id,
    required this.sensorType,
    required this.value,
    required this.timestamp,
    this.ubicacionNodo,
    this.nodoId,
    this.umbral,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'sensorType': sensorType,
      'value': value,
      'timestamp': timestamp,
      if (ubicacionNodo != null) 'ubicacion_nodo': ubicacionNodo,
      if (nodoId != null) 'nodo_id': nodoId,
      if (umbral != null) 'umbral': umbral,
    };
  }

  factory SensorReading.fromMap(Map<String, dynamic> map) {
    return SensorReading(
      id: map['id'] as int?,
      sensorType: map['sensorType'] as String,
      value: (map['value'] as num).toDouble(),
      timestamp: map['timestamp'] as String,
      ubicacionNodo: map['ubicacion_nodo'] as String?,
      nodoId: map['nodo_id'] as String?,
      umbral: (map['umbral'] as num?)?.toDouble(),
    );
  }
}

/// Helper Singleton para SQLite (sqflite) con relación 1:N y Migración V1 -> V2
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  // Memoria sólo para web/tests. En dispositivos nativos el fallo SQLite se propaga.
  final List<NodoIoT> _memoryNodes = [
    NodoIoT(id: 'ESP32_01', nombre: 'Sensor Invernadero', ubicacion: 'Zona Norte'),
    NodoIoT(id: 'ESP32_02', nombre: 'Sensor Almacén', ubicacion: 'Zona Central'),
  ];
  final List<AlertaNodo> _memoryAlerts = [
    AlertaNodo(id: 1, nodoId: 'ESP32_01', tipo: 'temperature', valor: 38.4, timestamp: '2026-10-01 10:15:00'),
    AlertaNodo(id: 2, nodoId: 'ESP32_02', tipo: 'temperature', valor: 33.1, timestamp: '2026-10-01 10:30:00'),
    AlertaNodo(id: 3, nodoId: 'ESP32_01', tipo: 'temperature', valor: 41.2, timestamp: '2026-10-01 11:00:00'),
  ];
  final List<SensorReading> _memoryReadings = [
    SensorReading(id: 1, sensorType: 'temperature', value: 24.5, timestamp: '2026-10-07 10:00:00', ubicacionNodo: 'Invernadero A'),
    SensorReading(id: 2, sensorType: 'humidity', value: 65.0, timestamp: '2026-10-07 10:05:00', ubicacionNodo: 'Invernadero A'),
    SensorReading(id: 3, sensorType: 'temperature', value: 28.2, timestamp: '2026-10-07 11:30:00', ubicacionNodo: 'Almacén Central'),
    SensorReading(id: 4, sensorType: 'humidity', value: 72.4, timestamp: '2026-10-07 11:35:00', ubicacionNodo: 'Almacén Central'),
  ];

  DatabaseHelper._init();

  Future<Database?> get database async {
    if (kIsWeb) return null;
    if (_database != null) return _database!;
    try {
      _database = await _initDB('iot_local.db');
      return _database!;
    } catch (e) {
      if (kDebugMode && !kIsWeb) rethrow;
      rethrow;
    }
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 3, // Migración no destructiva para registros de hardware
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
      onConfigure: (db) async {
        // Habilitar integridad referencial (Claves Foráneas)
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Tabla 1 de la relación 1:N: Nodos IoT
    await db.execute('''
      CREATE TABLE nodos (
        id TEXT PRIMARY KEY,
        nombre TEXT NOT NULL,
        ubicacion TEXT NOT NULL
      )
    ''');

    // Tabla N de la relación 1:N: Alertas con Clave Foránea
    await db.execute('''
      CREATE TABLE alertas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nodoId TEXT NOT NULL,
        tipo TEXT NOT NULL,
        valor REAL NOT NULL,
        timestamp TEXT NOT NULL,
        umbral REAL,
        lectura_id INTEGER,
        FOREIGN KEY (nodoId) REFERENCES nodos (id) ON DELETE CASCADE
      )
    ''');

    // Tabla de lecturas (Versión 1)
    await db.execute('''
      CREATE TABLE readings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sensorType TEXT NOT NULL,
        value REAL NOT NULL,
        timestamp TEXT NOT NULL,
        ubicacion_nodo TEXT,
        nodo_id TEXT,
        umbral REAL
      )
    ''');

    // Nodos por defecto
    await db.insert('nodos', {'id': 'ESP32_01', 'nombre': 'Sensor Invernadero', 'ubicacion': 'Zona Norte'});
    await db.insert('nodos', {'id': 'ESP32_02', 'nombre': 'Sensor Almacén', 'ubicacion': 'Zona Central'});

    // Lecturas por defecto (Temperatura y Humedad)
    await db.insert('readings', {'sensorType': 'temperature', 'value': 24.5, 'timestamp': '2026-10-07 10:00:00', 'ubicacion_nodo': 'Invernadero A'});
    await db.insert('readings', {'sensorType': 'humidity', 'value': 65.0, 'timestamp': '2026-10-07 10:05:00', 'ubicacion_nodo': 'Invernadero A'});
    await db.insert('readings', {'sensorType': 'temperature', 'value': 28.2, 'timestamp': '2026-10-07 11:30:00', 'ubicacion_nodo': 'Almacén Central'});
    await db.insert('readings', {'sensorType': 'humidity', 'value': 72.4, 'timestamp': '2026-10-07 11:35:00', 'ubicacion_nodo': 'Almacén Central'});
  }

  // Migración onUpgrade de V1 a V2 (Ejercicio 2 de Evaluación)
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Agrega la nueva columna sin perder los registros previos
      await db.execute('ALTER TABLE readings ADD COLUMN ubicacion_nodo TEXT;');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE readings ADD COLUMN nodo_id TEXT');
      await db.execute('ALTER TABLE readings ADD COLUMN umbral REAL');
      await db.execute('ALTER TABLE alertas ADD COLUMN umbral REAL');
      await db.execute('ALTER TABLE alertas ADD COLUMN lectura_id INTEGER');
    }
  }

  // Inserción de Nodo IoT
  Future<void> insertNodo(NodoIoT nodo) async {
    final db = await database;
    if (db == null) {
      _memoryNodes.removeWhere((n) => n.id == nodo.id);
      _memoryNodes.add(nodo);
      return;
    }
    await db.insert('nodos', nodo.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Inserción de Alerta
  Future<int> insertAlerta(AlertaNodo alerta) async {
    final db = await database;
    if (db == null) {
      final newId = _memoryAlerts.isEmpty ? 1 : (_memoryAlerts.last.id ?? 0) + 1;
      final saved = AlertaNodo(
        id: newId,
        nodoId: alerta.nodoId,
        tipo: alerta.tipo,
        valor: alerta.valor,
        timestamp: alerta.timestamp,
        umbral: alerta.umbral,
        lecturaId: alerta.lecturaId,
      );
      _memoryAlerts.add(saved);
      return newId;
    }
    return await db.insert('alertas', alerta.toMap());
  }

  // Consulta de Alertas por tipo (Parametrizada y segura)
  Future<List<AlertaNodo>> getAlertasPorTipo(String tipo) async {
    final db = await database;
    if (db == null) {
      final filtered = _memoryAlerts.where((a) => a.tipo == tipo).toList();
      filtered.sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0));
      return filtered;
    }
    final result = await db.query(
      'alertas',
      where: 'tipo = ?',
      whereArgs: [tipo],
      orderBy: 'id DESC',
    );
    return result.map((json) => AlertaNodo.fromMap(json)).toList();
  }

  Future<List<AlertaNodo>> getAllAlerts() async {
    final db = await database;
    if (db == null) {
      final items = List<AlertaNodo>.from(_memoryAlerts);
      items.sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0));
      return items;
    }
    final rows = await db.query('alertas', orderBy: 'id DESC');
    return rows.map(AlertaNodo.fromMap).toList();
  }

  /// Guarda una muestra y sus alertas en una sola transacción SQLite.
  Future<IoTInsertSummary> saveIotTelemetry({
    required String nodeId,
    required String location,
    double? temperature,
    double? humidity,
    required double temperatureThreshold,
    required String timestamp,
  }) async {
    if (temperature == null && humidity == null) {
      throw const FormatException('La muestra no contiene sensores.');
    }
    if (!temperatureThreshold.isFinite ||
        (temperature != null && !temperature.isFinite) ||
        (humidity != null && !humidity.isFinite)) {
      throw const FormatException('Se requieren valores finitos.');
    }
    final triggered = temperature != null && temperature > temperatureThreshold;
    final db = await database;
    if (db == null) {
      await insertNodo(NodoIoT(id: nodeId, nombre: nodeId, ubicacion: location));
      var count = 0;
      int? temperatureId;
      if (temperature != null) {
        temperatureId = await insertReading(SensorReading(
          sensorType: 'temperature', value: temperature, timestamp: timestamp,
          ubicacionNodo: location, nodoId: nodeId, umbral: temperatureThreshold,
        ));
        count++;
      }
      if (humidity != null) {
        await insertReading(SensorReading(
          sensorType: 'humidity', value: humidity, timestamp: timestamp,
          ubicacionNodo: location, nodoId: nodeId,
        ));
        count++;
      }
      if (triggered) {
        await insertAlerta(AlertaNodo(
          nodoId: nodeId, tipo: 'temperature', valor: temperature,
          timestamp: timestamp, umbral: temperatureThreshold,
          lecturaId: temperatureId,
        ));
      }
      return IoTInsertSummary(count, triggered ? 1 : 0);
    }
    return db.transaction((txn) async {
      await txn.insert('nodos', {
        'id': nodeId, 'nombre': nodeId, 'ubicacion': location,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
      var count = 0;
      int? temperatureId;
      if (temperature != null) {
        temperatureId = await txn.insert('readings', SensorReading(
          sensorType: 'temperature', value: temperature,
          timestamp: timestamp, ubicacionNodo: location,
          nodoId: nodeId, umbral: temperatureThreshold,
        ).toMap());
        count++;
      }
      if (humidity != null) {
        await txn.insert('readings', SensorReading(
          sensorType: 'humidity', value: humidity,
          timestamp: timestamp, ubicacionNodo: location, nodoId: nodeId,
        ).toMap());
        count++;
      }
      if (triggered) {
        await txn.insert('alertas', AlertaNodo(
          nodoId: nodeId, tipo: 'temperature',
          valor: temperature, timestamp: timestamp,
          umbral: temperatureThreshold, lecturaId: temperatureId,
        ).toMap());
      }
      return IoTInsertSummary(count, triggered ? 1 : 0);
    });
  }

  // Inserción parametrizada para PREVENIR SQL Injection
  Future<int> insertReading(SensorReading reading) async {
    final db = await database;
    if (db == null) {
      final newId = _memoryReadings.isEmpty ? 1 : (_memoryReadings.last.id ?? 0) + 1;
      final saved = SensorReading(
        id: newId,
        sensorType: reading.sensorType,
        value: reading.value,
        timestamp: reading.timestamp,
        ubicacionNodo: reading.ubicacionNodo,
        nodoId: reading.nodoId,
        umbral: reading.umbral,
      );
      _memoryReadings.add(saved);
      return newId;
    }
    return await db.insert('readings', reading.toMap());
  }

  // Insertar lote en Transacción ACID
  Future<void> insertBatchReadings(List<SensorReading> readings) async {
    final db = await database;
    if (db == null) {
      for (var r in readings) {
        await insertReading(r);
      }
      return;
    }
    await db.transaction((txn) async {
      var batch = txn.batch();
      for (var reading in readings) {
        batch.insert('readings', reading.toMap());
      }
      await batch.commit(noResult: true);
    });
  }

  // Consulta parametrizada de lecturas
  Future<List<SensorReading>> getReadingsByType(String type) async {
    final db = await database;
    if (db == null) {
      final filtered = _memoryReadings.where((r) => r.sensorType == type).toList();
      filtered.sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0));
      return filtered;
    }
    final result = await db.query(
      'readings',
      where: 'sensorType = ?',
      whereArgs: [type],
      orderBy: 'id DESC',
    );
    return result.map((json) => SensorReading.fromMap(json)).toList();
  }

  // Obtener todas las lecturas (Temperatura y Humedad)
  Future<List<SensorReading>> getAllReadings() async {
    final db = await database;
    if (db == null) {
      final list = List<SensorReading>.from(_memoryReadings);
      list.sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0));
      return list;
    }
    final result = await db.query('readings', orderBy: 'id DESC');
    return result.map((json) => SensorReading.fromMap(json)).toList();
  }

  // Actualización parametrizada (Edición manual)
  Future<int> updateReading(SensorReading reading) async {
    final db = await database;
    if (db == null) {
      final index = _memoryReadings.indexWhere((r) => r.id == reading.id);
      if (index != -1) {
        _memoryReadings[index] = reading;
        return 1;
      }
      return 0;
    }
    return await db.update(
      'readings',
      reading.toMap(),
      where: 'id = ?',
      whereArgs: [reading.id],
    );
  }

  // Eliminación parametrizada
  Future<int> deleteReading(int id) async {
    final db = await database;
    if (db == null) {
      _memoryReadings.removeWhere((r) => r.id == id);
      return 1;
    }
    return await db.delete(
      'readings',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}


class IoTInsertSummary {
  final int readings;
  final int alerts;
  const IoTInsertSummary(this.readings, this.alerts);
}

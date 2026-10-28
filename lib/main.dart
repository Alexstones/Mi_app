import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';

import 'csv_converter.dart';
import 'csv_file_picker.dart';
import 'csv_node_manager.dart';
import 'csv_nodes_dialog.dart';
import 'encrypted_json_storage.dart';
import 'historical_alerts_screen.dart';
import 'sensor_log_screen.dart';
import 'user_preferences_dialog.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mi App',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static const _filename = 'datos_seguros.json';
  final _storage = EncryptedJsonStorage();
  final _jsonController = TextEditingController(
    text: '{\n  "nombre": "Ana",\n  "activo": true\n}',
  );
  String _status = 'Listo para guardar datos localmente.';
  bool _isBusy = false;

  @override
  void dispose() {
    _jsonController.dispose();
    super.dispose();
  }

  Future<void> _saveJson() async {
    try {
      final decoded = jsonDecode(_jsonController.text);
      if (decoded is! Map && decoded is! List) {
        throw const FormatException(
          'El contenido debe ser un objeto ({...}) o lista ([...]) JSON.',
        );
      }
      setState(() => _isBusy = true);
      final path = await _storage.saveEncryptedJson(_filename, decoded);
      if (!mounted) return;
      setState(() {
        _isBusy = false;
        _status = 'Guardado cifrado en $path';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.lock, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('¡Datos cifrados con AES-256 y guardados con éxito!'),
            ],
          ),
          backgroundColor: Colors.teal.shade800,
          duration: const Duration(seconds: 3),
        ),
      );
    } on FormatException catch (error) {
      setState(() {
        _isBusy = false;
        _status = error.message;
      });
    } catch (error) {
      setState(() {
        _isBusy = false;
        _status = 'No se pudo guardar: $error';
      });
    }
  }

  Future<void> _readJson() async {
    setState(() => _isBusy = true);
    final data = await _storage.readEncryptedJson(_filename);
    if (!mounted) return;
    setState(() {
      _isBusy = false;
      if (data == null) {
        _status = 'No hay datos guardados o el archivo no es válido.';
      } else {
        _jsonController.text = const JsonEncoder.withIndent('  ').convert(data);
        _status = 'Datos leídos y descifrados correctamente.';
      }
    });

    if (data != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.lock_open, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('¡Datos leídos y descifrados correctamente desde el almacenamiento!'),
            ],
          ),
          backgroundColor: Colors.teal.shade700,
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay datos guardados previamente para descifrar.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _importCsvDialog() async {
    final csvInputController = TextEditingController(
      text: 'nombre,edad,activo\nAna,25,true\nCarlos,30,false',
    );

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.file_upload, color: Colors.teal),
                  SizedBox(width: 8),
                  Text('Importar CSV a JSON'),
                ],
              ),
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600, maxHeight: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Pega o escribe tu texto en formato CSV para convertirlo a JSON en el editor:',
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: TextField(
                        controller: csvInputController,
                        expands: true,
                        maxLines: null,
                        minLines: null,
                        textAlignVertical: TextAlignVertical.top,
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                        decoration: const InputDecoration(
                          hintText: 'columna1,columna2\nvalor1,valor2',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton.tonalIcon(
                          icon: const Icon(Icons.file_open, size: 18),
                          label: const Text('Subir archivo desde mi PC (.csv)'),
                          onPressed: () {
                            getCsvFilePicker().pickAndReadFile((content, fileName) {
                              setDialogState(() {
                                csvInputController.text = content;
                              });
                              if (content.contains('CHECKSUM:')) {
                                final verification = CsvNodeManager().verifyCsvContent(content);
                                if (!verification.isValid) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('🚨 ${verification.message}'),
                                      backgroundColor: Colors.red.shade800,
                                      duration: const Duration(seconds: 4),
                                    ),
                                  );
                                }
                              }
                            });
                          },
                        ),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.folder_open, size: 18),
                          label: const Text('Cargar datos.csv guardado'),
                          onPressed: () async {
                            final savedCsv = await _storage.readCsv('datos.csv');
                            if (savedCsv != null && savedCsv.isNotEmpty) {
                              setDialogState(() {
                                csvInputController.text = savedCsv;
                              });
                            } else {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('No se encontró un archivo datos.csv guardado.'),
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                FilledButton.icon(
                  icon: const Icon(Icons.check),
                  label: const Text('Importar al editor'),
                  onPressed: () {
                    final rawCsv = csvInputController.text.trim();
                    if (rawCsv.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Ingresa contenido CSV para importar.')),
                      );
                      return;
                    }

                    // Verificación de integridad Checksum SHA-256 contra modificaciones manuales
                    if (rawCsv.contains('CHECKSUM:')) {
                      final verification = CsvNodeManager().verifyCsvContent(rawCsv);
                      if (!verification.isValid) {
                        showDialog<void>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            icon: const Icon(Icons.warning, color: Colors.red, size: 48),
                            title: const Text(
                              '🚨 ALERTA DE SEGURIDAD',
                              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                            ),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'El archivo CSV ha sido alterado o corrupto. '
                                  'Se detectó que el archivo fue modificado manualmente en Excel después de ser exportado.',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 12),
                                if (verification.originalChecksum != null) ...[
                                  SelectableText(
                                    'Checksum original:    ${verification.originalChecksum}',
                                    style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                                  ),
                                  SelectableText(
                                    'Checksum recalculado: ${verification.recalculatedChecksum}',
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            actions: [
                              FilledButton(
                                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                                onPressed: () => Navigator.of(ctx).pop(),
                                child: const Text('Entendido'),
                              ),
                            ],
                          ),
                        );
                        return;
                      }
                    }

                    try {
                      // Si contiene cabecera de Checksum, removerla para la conversión a JSON
                      String csvToConvert = rawCsv;
                      if (csvToConvert.contains('CHECKSUM:')) {
                        final lines = csvToConvert.split('\n');
                        final headerIndex = lines.indexWhere((l) => l.contains('CHECKSUM:'));
                        csvToConvert = lines.sublist(headerIndex + 1).join('\n').trim();
                      }

                      final decodedJson = CsvConverter.convertCsvToJson(csvToConvert);
                      final prettyJson = const JsonEncoder.withIndent('  ').convert(decodedJson);
                      setState(() {
                        _jsonController.text = prettyJson;
                        _status = 'CSV importado exitosamente al editor como JSON.';
                      });
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('CSV importado y verificado con éxito.'),
                          backgroundColor: Colors.teal,
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error al procesar CSV: $e')),
                      );
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _exportCsvDialog() async {
    try {
      final text = _jsonController.text.trim();
      if (text.isEmpty) {
        throw const FormatException('No hay contenido JSON para exportar.');
      }
      final decoded = jsonDecode(text);
      if (decoded is! Map && decoded is! List) {
        throw const FormatException(
          'El contenido debe ser un objeto JSON ({...}) o una lista ([...]).',
        );
      }

      final csvContent = CsvConverter.convertJsonToCsv(decoded);
      if (csvContent.isEmpty) {
        throw const FormatException('No se encontraron datos para generar el CSV.');
      }

      final filenameController = TextEditingController(text: 'datos.csv');

      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.file_download, color: Colors.teal),
                SizedBox(width: 8),
                Text('Exportar CSV'),
              ],
            ),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Especifica el nombre del archivo para exportar:'),
                  const SizedBox(height: 12),
                  TextField(
                    controller: filenameController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del archivo',
                      hintText: 'datos.csv',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Formato: CSV (RFC 4180, codificación UTF-8)',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
              FilledButton.icon(
                icon: const Icon(Icons.download),
                label: const Text('Exportar ahora'),
                onPressed: () async {
                  var filename = filenameController.text.trim();
                  if (filename.isEmpty) {
                    filename = 'datos.csv';
                  }
                  if (!filename.toLowerCase().endsWith('.csv')) {
                    filename = '$filename.csv';
                  }
                  Navigator.of(context).pop();
                  await _performExport(filename, csvContent);
                },
              ),
            ],
          );
        },
      );
    } on FormatException catch (error) {
      setState(() {
        _status = error.message;
      });
    } catch (error) {
      setState(() {
        _status = 'Error al exportar CSV: $error';
      });
    }
  }

  Future<void> _performExport(String filename, String csvContent) async {
    setState(() => _isBusy = true);
    try {
      String contentToSave = csvContent;
      if (!contentToSave.startsWith('# CHECKSUM:')) {
        final hash = sha256.convert(utf8.encode(contentToSave.trim())).toString();
        contentToSave = '# CHECKSUM:$hash\n$contentToSave';
      }
      final path = await _storage.saveCsv(filename, contentToSave);
      if (!mounted) return;
      setState(() {
        _isBusy = false;
        _status = 'CSV exportado exitosamente como: $filename ($path)';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('CSV exportado exitosamente: $filename'),
          backgroundColor: Colors.teal.shade700,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (error) {
      setState(() {
        _isBusy = false;
        _status = 'Error al exportar el archivo: $error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Almacenamiento local seguro'),
        actions: [
          IconButton(
            tooltip: 'Práctica 1.2: Checksum SHA-256',
            icon: const Icon(Icons.verified_user),
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => const CsvNodesDialog(),
              );
            },
          ),
          IconButton(
            key: const Key('goto-sqlite-button'),
            tooltip: 'Módulo 2: SQLite IoT',
            icon: const Icon(Icons.sensors),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const HistoricalAlertsScreen(),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'JSON cifrado para Windows',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 4),
                const Text(
                  'Edita un objeto JSON. Se guarda en la carpeta de documentos de la aplicación usando AES-256.',
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ActionChip(
                      avatar: const Icon(Icons.verified_user, color: Colors.amber, size: 18),
                      label: const Text('Práctica 1.2: Nodos CSV (Checksum SHA-256)'),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => const CsvNodesDialog(),
                        );
                      },
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.sensors, color: Colors.teal, size: 18),
                      label: const Text('Módulo 2: SQLite Relacional IoT'),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const HistoricalAlertsScreen(),
                          ),
                        );
                      },
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.description_outlined, color: Colors.blueGrey, size: 18),
                      label: const Text('Preferencias JSON'),
                      onPressed: () {
                        showDialog<void>(
                          context: context,
                          builder: (_) => const UserPreferencesDialog(),
                        );
                      },
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.monitor_heart_outlined, color: Colors.deepOrange, size: 18),
                      label: const Text('Log de sensores CSV'),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const SensorLogScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: TextField(
                    controller: _jsonController,
                    expands: true,
                    maxLines: null,
                    minLines: null,
                    textAlignVertical: TextAlignVertical.top,
                    style: const TextStyle(fontFamily: 'monospace'),
                    decoration: const InputDecoration(
                      labelText: 'Contenido JSON',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _isBusy ? null : _saveJson,
                            icon: const Icon(Icons.lock_outline),
                            label: const FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text('Guardar cifrado'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isBusy ? null : _readJson,
                            icon: const Icon(Icons.lock_open_outlined),
                            label: const FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text('Leer y descifrar'),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.tonalIcon(
                            key: const Key('import-csv-button'),
                            onPressed: _isBusy ? null : _importCsvDialog,
                            icon: const Icon(Icons.file_upload_outlined),
                            label: const FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text('Importar CSV'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            key: const Key('export-csv-button'),
                            onPressed: _isBusy ? null : _exportCsvDialog,
                            icon: const Icon(Icons.file_download_outlined),
                            label: const FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text('Exportar CSV'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(_status, key: const Key('storage-status')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

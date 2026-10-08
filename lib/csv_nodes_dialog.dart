import 'package:flutter/material.dart';
import 'csv_file_picker.dart';
import 'csv_node_manager.dart';

class CsvNodesDialog extends StatefulWidget {
  const CsvNodesDialog({super.key});

  @override
  State<CsvNodesDialog> createState() => _CsvNodesDialogState();
}

class _CsvNodesDialogState extends State<CsvNodesDialog> {
  final CsvNodeManager _manager = CsvNodeManager();
  final CsvFilePicker _picker = getCsvFilePicker();
  late TextEditingController _csvContentController;
  CsvVerificationResult? _lastResult;
  String? _exportedPath;

  @override
  void initState() {
    super.initState();
    final defaultRows = CsvNodeManager.getDefaultNodes();
    final initialCsv = _manager.generateCsvWithChecksum(defaultRows);
    _csvContentController = TextEditingController(text: initialCsv);
  }

  @override
  void dispose() {
    _csvContentController.dispose();
    super.dispose();
  }

  Future<void> _exportCsv() async {
    final defaultRows = CsvNodeManager.getDefaultNodes();
    final path = await _manager.exportNodesToCsv(defaultRows);
    final text = _manager.generateCsvWithChecksum(defaultRows);

    setState(() {
      _exportedPath = path;
      _csvContentController.text = text;
      _lastResult = null;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.download_done, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text('✓ Archivo iot_nodes_config.csv exportado y descargado con Checksum SHA-256.'),
              ),
            ],
          ),
          backgroundColor: Colors.teal.shade800,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _verifyContent() {
    final result = _manager.verifyCsvContent(_csvContentController.text);
    setState(() {
      _lastResult = result;
    });
  }

  void _pickAndLoadFile() {
    _picker.pickAndReadFile((content, fileName) {
      setState(() {
        _csvContentController.text = content;
        _lastResult = null;
      });
      _verifyContent();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ Archivo cargado desde PC: $fileName'),
            backgroundColor: Colors.teal.shade800,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    });
  }

  void _onCsvEdited(String content) {
    final result = _manager.verifyCsvContent(content);
    setState(() {
      _lastResult = result;
    });
  }

  void _resetToOriginal() {
    final defaultRows = CsvNodeManager.getDefaultNodes();
    final text = _manager.generateCsvWithChecksum(defaultRows);
    setState(() {
      _csvContentController.text = text;
      _lastResult = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 780, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.verified_user, color: Colors.teal, size: 28),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Práctica 1.2: Configuración de Nodos IoT en CSV',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Verificación de integridad criptográfica con Checksum SHA-256',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(height: 20),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  FilledButton.icon(
                    icon: const Icon(Icons.file_download),
                    label: const Text('1. Exportar CSV'),
                    onPressed: _exportCsv,
                  ),
                  FilledButton.tonalIcon(
                    icon: const Icon(Icons.file_open),
                    label: const Text('2. Subir archivo editado de mi PC (.csv)'),
                    onPressed: _pickAndLoadFile,
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.rule),
                    label: const Text('Verificar Integridad'),
                    onPressed: _verifyContent,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_exportedPath != null)
                Text(
                  'Descargado como: iot_nodes_config.csv (en tu carpeta de Descargas)',
                  style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.teal),
                ),
              const SizedBox(height: 8),
              // Banner de resultado de verificación
              if (_lastResult != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _lastResult!.isValid ? Colors.green.shade50 : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _lastResult!.isValid ? Colors.green.shade600 : Colors.red.shade600,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _lastResult!.isValid ? Icons.check_circle : Icons.warning_amber_rounded,
                            color: _lastResult!.isValid ? Colors.green.shade800 : Colors.red.shade800,
                            size: 26,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _lastResult!.isValid
                                  ? '✓ VERIFICACIÓN DE INTEGRIDAD EXITOSA'
                                  : '🚨 ALERTA DE SEGURIDAD: ARCHIVO ALTERADO O CORRUPTO',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: _lastResult!.isValid ? Colors.green.shade900 : Colors.red.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _lastResult!.message,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _lastResult!.isValid ? Colors.green.shade900 : Colors.red.shade900,
                        ),
                      ),
                      if (_lastResult!.originalChecksum != null && _lastResult!.recalculatedChecksum != null) ...[
                        const SizedBox(height: 6),
                        SelectableText(
                          'Checksum original:     ${_lastResult!.originalChecksum}',
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 10),
                        ),
                        SelectableText(
                          'Checksum recalculado:  ${_lastResult!.recalculatedChecksum}',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _lastResult!.isValid ? Colors.green.shade900 : Colors.red.shade900,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
              const Text(
                'Contenido CSV actual (puedes editarlo manualmente aquí o subir el archivo de Excel):',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: TextField(
                  key: const Key('csv-content-editor'),
                  controller: _csvContentController,
                  onChanged: _onCsvEdited,
                  expands: true,
                  maxLines: null,
                  minLines: null,
                  textAlignVertical: TextAlignVertical.top,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    hintText: '# CHECKSUM:<sha256>\nid,nombre,ubicacion...',
                    fillColor: Colors.grey.shade50,
                    filled: true,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.restart_alt),
                    label: const Text('Restablecer valores originales'),
                    onPressed: _resetToOriginal,
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cerrar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

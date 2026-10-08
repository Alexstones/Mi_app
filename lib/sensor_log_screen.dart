import 'package:flutter/material.dart';

import 'csv_node_manager.dart';
import 'sensor_log_manager.dart';

class SensorLogScreen extends StatefulWidget {
  const SensorLogScreen({super.key});

  @override
  State<SensorLogScreen> createState() => _SensorLogScreenState();
}

class _SensorLogScreenState extends State<SensorLogScreen> {
  final _manager = SensorLogManager();
  CsvVerificationResult? _verification;
  String? _status;
  bool _isBusy = false;

  Future<void> _generateLog() async {
    setState(() {
      _isBusy = true;
      _verification = null;
    });
    try {
      final filePath = await _manager.generateAndSave();
      if (!mounted) return;
      setState(() {
        _isBusy = false;
        _status = 'Log de 100 lecturas guardado en $filePath';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Log CSV de sensores generado correctamente.')),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isBusy = false;
        _status = 'No se pudo generar el log: $error';
      });
    }
  }

  Future<void> _verifyLog() async {
    setState(() => _isBusy = true);
    try {
      final result = await _manager.verifySavedLog();
      if (!mounted) return;
      setState(() {
        _isBusy = false;
        _verification = result;
        _status = result.message;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isBusy = false;
        _verification = const CsvVerificationResult(
          isValid: false,
          message: 'No se pudo validar el log.',
        );
        _status = 'Error al validar el log: $error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isValid = _verification?.isValid ?? false;
    return Scaffold(
      appBar: AppBar(title: const Text('Log de Sensores (CSV)')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton.icon(
                  key: const Key('generate-sensor-log'),
                  onPressed: _isBusy ? null : _generateLog,
                  icon: const Icon(Icons.sensors),
                  label: const Text('Generar Log de Sensores (CSV)'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  key: const Key('validate-sensor-log'),
                  onPressed: _isBusy ? null : _verifyLog,
                  icon: const Icon(Icons.verified_outlined),
                  label: const Text('Validar Integridad Log'),
                ),
                if (_isBusy) ...[
                  const SizedBox(height: 16),
                  const Center(child: CircularProgressIndicator()),
                ],
                if (_verification != null) ...[
                  const SizedBox(height: 20),
                  Icon(
                    isValid ? Icons.check_circle : Icons.cancel,
                    key: const Key('sensor-log-integrity-result'),
                    color: isValid ? Colors.green : Colors.red,
                    size: 56,
                  ),
                  Center(
                    child: Text(
                      isValid ? 'Válido' : 'Corrupto',
                      style: TextStyle(
                        color: isValid ? Colors.green.shade800 : Colors.red.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                if (_status != null) ...[
                  const SizedBox(height: 16),
                  Text(_status!, textAlign: TextAlign.center),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

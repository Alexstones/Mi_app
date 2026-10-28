import 'dart:async';

import 'package:flutter/material.dart';

import 'esp32_http_source.dart';
import 'iot_alert_service.dart';

/// Se ejecuta mientras esta pestaña está abierta. No simula la conexión.
class Esp32MonitorPanel extends StatefulWidget {
  const Esp32MonitorPanel({super.key, required this.onStored});

  final VoidCallback onStored;

  @override
  State<Esp32MonitorPanel> createState() => _Esp32MonitorPanelState();
}

class _Esp32MonitorPanelState extends State<Esp32MonitorPanel> {
  final _endpointController =
      TextEditingController(text: 'http://192.168.4.1/reading');
  final _thresholdController = TextEditingController(text: '35');
  final _source = Esp32HttpSource();
  final _service = IoTAlertService();

  Timer? _timer;
  bool _running = false;
  bool _busy = false;
  String _status = 'Introduce la URL del ESP32 y consulta sus sensores.';
  String? _error;
  int _totalReadings = 0;
  int _totalAlerts = 0;

  @override
  void dispose() {
    _timer?.cancel();
    _source.dispose();
    _endpointController.dispose();
    _thresholdController.dispose();
    super.dispose();
  }

  Future<void> _poll() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final telemetry = await _source.fetch(_endpointController.text);
      final threshold = double.parse(_thresholdController.text.trim());
      final saved = await _service.record(
        telemetry,
        temperatureThreshold: threshold,
      );
      if (!mounted) return;
      widget.onStored();
      setState(() {
        _totalReadings += saved.readings;
        _totalAlerts += saved.alerts;
        _status = 'Nodo ${telemetry.nodeId}: ${saved.readings} lectura(s) '
            'guardada(s), ${saved.alerts} alerta(s) nueva(s).';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudo leer el ESP32: $error';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _start() {
    try {
      Esp32HttpSource.parseEndpoint(_endpointController.text);
      final threshold = double.parse(_thresholdController.text.trim());
      if (!threshold.isFinite) {
        throw const FormatException('El umbral debe ser finito.');
      }
    } catch (error) {
      setState(() => _error = 'Revisa la configuración: $error');
      return;
    }
    setState(() {
      _running = true;
      _error = null;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _poll());
    _poll();
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
    setState(() {
      _running = false;
      _status = 'Monitoreo detenido. Los registros siguen en SQLite.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Lecturas reales del ESP32 por Wi-Fi',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Conecta el teléfono a la red del ESP32 (o a su misma Wi-Fi). '
          'El dispositivo debe publicar un GET que responda JSON con '
          'nodeId, location, temperature y/o humidity.',
        ),
        const SizedBox(height: 16),
        TextField(
          key: const Key('esp32-endpoint'),
          controller: _endpointController,
          enabled: !_running,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(
            labelText: 'URL HTTP del ESP32',
            hintText: 'http://192.168.4.1/reading',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.wifi),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('esp32-threshold'),
          controller: _thresholdController,
          enabled: !_running,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Umbral de temperatura (°C)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.thermostat),
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              key: const Key('esp32-monitor-toggle'),
              onPressed: _running ? _stop : _start,
              icon: Icon(_running ? Icons.stop : Icons.play_arrow),
              label: Text(_running ? 'Detener' : 'Monitorear cada 5 s'),
            ),
            OutlinedButton.icon(
              onPressed: _busy || _running ? null : _poll,
              icon: const Icon(Icons.refresh),
              label: const Text('Leer una vez'),
            ),
          ],
        ),
        if (_busy) ...[
          const SizedBox(height: 16),
          const LinearProgressIndicator(),
        ],
        const SizedBox(height: 18),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_status, key: const Key('esp32-status')),
                const SizedBox(height: 8),
                Text('Esta sesión: $_totalReadings lecturas, '
                    '$_totalAlerts alertas.'),
                const Text(
                  'Sólo se registra alerta cuando temperatura > umbral; '
                  '35.0 °C no genera alerta con un umbral de 35 °C.',
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    key: const Key('esp32-error'),
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        const SelectableText(
          'Ejemplo de respuesta JSON:\n'
          '{"nodeId":"ESP32_01","location":"Invernadero A",'
          '"temperature":36.8,"humidity":62.5}',
          style: TextStyle(fontFamily: 'monospace'),
        ),
        const Text(
          'Las lecturas y sus alertas se guardan en una transacción local. '
          'Consulta las pestañas Lecturas y Alertas para ver el historial.',
        ),
      ],
    );
  }
}

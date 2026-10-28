import 'dart:math';
import 'package:flutter/material.dart';
import 'csv_nodes_dialog.dart';
import 'database_helper.dart';
import 'esp32_monitor_panel.dart';

class HistoricalAlertsScreen extends StatefulWidget {
  const HistoricalAlertsScreen({super.key});

  @override
  State<HistoricalAlertsScreen> createState() => _HistoricalAlertsScreenState();
}

class _HistoricalAlertsScreenState extends State<HistoricalAlertsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<AlertaNodo>> _alertsFuture;
  late Future<List<SensorReading>> _readingsFuture;
  String _selectedFilter = 'all'; // 'all', 'temperature', 'humidity'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() { if (mounted) setState(() {}); });
    _refreshData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _refreshData() {
    setState(() {
      _alertsFuture = DatabaseHelper.instance.getAllAlerts();
      if (_selectedFilter == 'all') {
        _readingsFuture = DatabaseHelper.instance.getAllReadings();
      } else {
        _readingsFuture = DatabaseHelper.instance.getReadingsByType(_selectedFilter);
      }
    });
  }

  Future<void> _addSimulatedAlert() async {
    final random = Random();
    final temp = 28.0 + random.nextDouble() * 15.0; // Entre 28.0 y 43.0 °C
    final tempRounded = double.parse(temp.toStringAsFixed(1));
    final nodeId = random.nextBool() ? 'ESP32_01' : 'ESP32_02';
    final nowStr = DateTime.now().toIso8601String().substring(0, 19).replaceAll('T', ' ');

    await DatabaseHelper.instance.insertAlerta(
      AlertaNodo(
        nodoId: nodeId,
        tipo: 'temperature',
        valor: tempRounded,
        timestamp: nowStr,
      ),
    );

    _refreshData();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Alerta registrada: $tempRounded °C desde $nodeId',
          ),
          backgroundColor: tempRounded > 35.0 ? Colors.red.shade700 : Colors.orange.shade700,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Diálogo para agregar o editar manualmente una lectura (Temperatura o Humedad)
  Future<void> _showReadingDialog({SensorReading? reading}) async {
    final isEditing = reading != null;
    String selectedType = reading?.sensorType ?? 'temperature';
    final valueController = TextEditingController(
      text: reading != null ? reading.value.toString() : '25.0',
    );
    final locationController = TextEditingController(
      text: reading?.ubicacionNodo ?? 'Invernadero A',
    );

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(
                    isEditing ? Icons.edit_note : Icons.add_chart,
                    color: Colors.teal,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isEditing ? 'Editar Lectura Manualmente' : 'Nueva Lectura Manual',
                    style: const TextStyle(fontSize: 18),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Tipo de Sensor:', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'temperature',
                          label: Text('Temperatura'),
                          icon: Icon(Icons.thermostat, color: Colors.orange),
                        ),
                        ButtonSegment(
                          value: 'humidity',
                          label: Text('Humedad'),
                          icon: Icon(Icons.water_drop, color: Colors.blue),
                        ),
                      ],
                      selected: {selectedType},
                      onSelectionChanged: (newSelection) {
                        setDialogState(() {
                          selectedType = newSelection.first;
                          if (!isEditing) {
                            valueController.text = selectedType == 'temperature' ? '26.5' : '68.0';
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: valueController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Valor medido',
                        suffixText: selectedType == 'temperature' ? '°C' : '%',
                        border: const OutlineInputBorder(),
                        prefixIcon: Icon(
                          selectedType == 'temperature' ? Icons.thermostat : Icons.water_drop,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: locationController,
                      decoration: const InputDecoration(
                        labelText: 'Ubicación del nodo',
                        hintText: 'ej. Invernadero A, Almacén',
                        border: const OutlineInputBorder(),
                        prefixIcon: Icon(Icons.place),
                      ),
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
                  icon: const Icon(Icons.save),
                  label: Text(isEditing ? 'Guardar Cambios' : 'Guardar en SQLite'),
                  onPressed: () async {
                    final enteredVal = double.tryParse(valueController.text.trim());
                    if (enteredVal == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Por favor ingresa un número válido.')),
                      );
                      return;
                    }

                    final nowStr = DateTime.now().toIso8601String().substring(0, 19).replaceAll('T', ' ');

                    if (isEditing) {
                      // Editar manual
                      final updated = SensorReading(
                        id: reading.id,
                        sensorType: selectedType,
                        value: enteredVal,
                        timestamp: reading.timestamp, // Preserva fecha o actualiza
                        ubicacionNodo: locationController.text.trim(),
                      );
                      await DatabaseHelper.instance.updateReading(updated);
                      if (mounted) {
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '✓ Lectura #${reading.id} editada manualmente: $enteredVal ${selectedType == 'temperature' ? '°C' : '%'}',
                            ),
                            backgroundColor: Colors.teal.shade800,
                          ),
                        );
                      }
                    } else {
                      // Guardar nueva lectura manual
                      final newReading = SensorReading(
                        sensorType: selectedType,
                        value: enteredVal,
                        timestamp: nowStr,
                        ubicacionNodo: locationController.text.trim(),
                      );
                      await DatabaseHelper.instance.insertReading(newReading);
                      if (mounted) {
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '✓ Nueva lectura guardada en SQLite: $enteredVal ${selectedType == 'temperature' ? '°C' : '%'}',
                            ),
                            backgroundColor: Colors.teal.shade800,
                          ),
                        );
                      }
                    }

                    Navigator.of(context).pop();
                    _refreshData();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteReading(int id) async {
    await DatabaseHelper.instance.deleteReading(id);
    _refreshData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registro #$id eliminado de SQLite.'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart-Environment: Histórico IoT'),
        backgroundColor: Colors.teal.shade50,
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.verified_user, color: Colors.teal),
            label: const Text('Config CSV Nodos'),
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => const CsvNodesDialog(),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: 'Recargar datos',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.teal.shade900,
          indicatorColor: Colors.teal,
          tabs: const [
            Tab(
              icon: Icon(Icons.thermostat),
              text: 'Lecturas (Humedad / Temp)',
            ),
            Tab(
              icon: Icon(Icons.warning_amber),
              text: 'Alertas',
            ),
            Tab(icon: Icon(Icons.wifi), text: 'ESP32'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // PESTAÑA 1: LECTURAS (Temperatura y Humedad - Guardar y Editar Manual)
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Text('Filtrar: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Todos'),
                      selected: _selectedFilter == 'all',
                      onSelected: (val) {
                        setState(() {
                          _selectedFilter = 'all';
                          _refreshData();
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      avatar: const Icon(Icons.thermostat, size: 16, color: Colors.orange),
                      label: const Text('Temperatura'),
                      selected: _selectedFilter == 'temperature',
                      onSelected: (val) {
                        setState(() {
                          _selectedFilter = 'temperature';
                          _refreshData();
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      avatar: const Icon(Icons.water_drop, size: 16, color: Colors.blue),
                      label: const Text('Humedad'),
                      selected: _selectedFilter == 'humidity',
                      onSelected: (val) {
                        setState(() {
                          _selectedFilter = 'humidity';
                          _refreshData();
                        });
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: FutureBuilder<List<SensorReading>>(
                  future: _readingsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error: ${snapshot.error}',
                          style: const TextStyle(color: Colors.red),
                        ),
                      );
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(
                        child: Text(
                          'No hay lecturas registradas. Usa el botón "+" para agregar una.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      );
                    }

                    final readings = snapshot.data!;
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: readings.length,
                      itemBuilder: (context, index) {
                        final item = readings[index];
                        final isTemp = item.sensorType == 'temperature';
                        final isCritical = isTemp && item.value > (item.umbral ?? 35.0);

                        return Card(
                          elevation: 1.5,
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(
                            side: BorderSide(
                              color: isCritical ? Colors.red : (isTemp ? Colors.orange.shade200 : Colors.blue.shade200),
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isTemp ? Colors.orange.shade100 : Colors.blue.shade100,
                              child: Icon(
                                isTemp ? Icons.thermostat : Icons.water_drop,
                                color: isCritical ? Colors.red : (isTemp ? Colors.orange.shade800 : Colors.blue.shade800),
                              ),
                            ),
                            title: Text(
                              isTemp
                                  ? 'Temperatura: ${item.value} °C'
                                  : 'Humedad: ${item.value} %',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              'Nodo: ${item.nodoId ?? 'manual'} | Ubicación: ${item.ubicacionNodo ?? 'N/A'} | Fecha: ${item.timestamp}${isCritical ? ' | ALERTA' : ''}',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.teal),
                                  tooltip: 'Editar lectura manualmente',
                                  onPressed: () => _showReadingDialog(reading: item),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                  tooltip: 'Eliminar de SQLite',
                                  onPressed: () => _deleteReading(item.id!),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),

          // PESTAÑA 2: ALERTAS IoT 1:N
          FutureBuilder<List<AlertaNodo>>(
            future: _alertsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error al cargar alertas: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                  child: Text(
                    'No hay alertas registradas en SQLite.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                );
              }

              final alerts = snapshot.data!;
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: alerts.length,
                itemBuilder: (context, index) {
                  final item = alerts[index];
                  final isCritical = item.valor > (item.umbral ?? 35.0);

                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                        color: isCritical ? Colors.red.shade300 : Colors.orange.shade300,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isCritical ? Colors.red.shade100 : Colors.orange.shade100,
                        child: Icon(
                          Icons.warning,
                          color: isCritical ? Colors.red.shade800 : Colors.orange.shade800,
                        ),
                      ),
                      title: Text(
                        '${item.tipo.toUpperCase()}: ${item.valor} °C',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('Nodo: ${item.nodoId} | Umbral: ${item.umbral ?? 35.0} °C | Fecha: ${item.timestamp}'),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isCritical ? Colors.red.shade50 : Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isCritical ? Colors.red : Colors.orange,
                          ),
                        ),
                        child: Text(
                          isCritical ? 'CRÍTICO' : 'AVISO',
                          style: TextStyle(
                            color: isCritical ? Colors.red.shade800 : Colors.orange.shade800,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
          Esp32MonitorPanel(onStored: _refreshData),
        ],
      ),
      floatingActionButton: _tabController.index == 2 ? null : FloatingActionButton.extended(
        onPressed: () {
          if (_tabController.index == 0) {
            _showReadingDialog(); // Agregar lectura manual
          } else {
            _showReadingDialog(); // Registro manual sin fingir hardware
          }
        },
        icon: const Icon(Icons.add),
        label: Text(_tabController.index == 0 ? 'Nueva Lectura Manual' : 'Nueva Lectura Manual'),
      ),
    );
  }
}

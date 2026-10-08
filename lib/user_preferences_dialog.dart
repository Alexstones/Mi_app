import 'package:flutter/material.dart';

import 'local_user_preferences_storage.dart';

class UserPreferencesDialog extends StatefulWidget {
  const UserPreferencesDialog({super.key});

  @override
  State<UserPreferencesDialog> createState() => _UserPreferencesDialogState();
}

class _UserPreferencesDialogState extends State<UserPreferencesDialog> {
  final _samplingIntervalController = TextEditingController(text: '10');
  final _storage = createLocalUserPreferencesStorage();
  bool _darkTheme = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _samplingIntervalController.dispose();
    super.dispose();
  }

  Future<void> _savePreferences() async {
    final interval = int.tryParse(_samplingIntervalController.text.trim());
    if (interval == null || interval <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El intervalo debe ser un número de segundos mayor que cero.'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final filePath = await _storage.save(
        LocalUserPreferences(
          darkTheme: _darkTheme,
          samplingIntervalSeconds: interval,
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Preferencias guardadas en $filePath')),
      );
    } on LocalPreferencesWriteException catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudieron guardar las preferencias: ${error.message}'),
          backgroundColor: Colors.red.shade800,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar las preferencias: $error'),
          backgroundColor: Colors.red.shade800,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Preferencias locales'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Tema oscuro'),
            value: _darkTheme,
            onChanged: _isSaving ? null : (value) => setState(() => _darkTheme = value),
          ),
          TextField(
            controller: _samplingIntervalController,
            enabled: !_isSaving,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Intervalo de muestreo IoT (segundos)',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _savePreferences,
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Guardar JSON'),
        ),
      ],
    );
  }
}

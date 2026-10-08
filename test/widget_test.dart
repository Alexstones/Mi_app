import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mi_app/main.dart';

void main() {
  testWidgets('muestra el editor y las acciones de almacenamiento',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('JSON cifrado para Windows'), findsOneWidget);
    expect(find.text('Guardar cifrado'), findsOneWidget);
    expect(find.text('Leer y descifrar'), findsOneWidget);
    expect(find.text('Importar CSV'), findsOneWidget);
    expect(find.text('Exportar CSV'), findsOneWidget);
    expect(find.byKey(const Key('storage-status')), findsOneWidget);
  });

  testWidgets('abre el generador CSV de sensores con sus dos acciones',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.text('Log de sensores CSV'));
    await tester.pumpAndSettle();

    expect(find.text('Generar Log de Sensores (CSV)'), findsOneWidget);
    expect(find.text('Validar Integridad Log'), findsOneWidget);
  });

  testWidgets('muestra las preferencias de tema e intervalo de muestreo',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.text('Preferencias JSON'));
    await tester.pumpAndSettle();

    expect(find.text('Tema oscuro'), findsOneWidget);
    expect(find.text('Intervalo de muestreo IoT (segundos)'), findsOneWidget);
    expect(find.text('Guardar JSON'), findsOneWidget);
  });
}

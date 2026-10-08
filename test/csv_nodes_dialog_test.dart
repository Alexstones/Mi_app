import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_app/csv_nodes_dialog.dart';
import 'package:mi_app/csv_node_manager.dart';

void main() {
  testWidgets('solo muestra alerta después de editar un CSV con checksum',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: CsvNodesDialog()),
      ),
    );

    expect(find.text('🚨 ALERTA DE SEGURIDAD: ARCHIVO ALTERADO O CORRUPTO'),
        findsNothing);

    final original = CsvNodeManager().generateCsvWithChecksum(
      CsvNodeManager.getDefaultNodes(),
    );
    await tester.enterText(
      find.byKey(const Key('csv-content-editor')),
      original.replaceFirst('Zona Norte', 'Zona Editada'),
    );
    await tester.pump();

    expect(find.text('🚨 ALERTA DE SEGURIDAD: ARCHIVO ALTERADO O CORRUPTO'),
        findsOneWidget);

    await tester.tap(find.text('Restablecer valores originales'));
    await tester.pump();

    expect(find.text('🚨 ALERTA DE SEGURIDAD: ARCHIVO ALTERADO O CORRUPTO'),
        findsNothing);
  });
}

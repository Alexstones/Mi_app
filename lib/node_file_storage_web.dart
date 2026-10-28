import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'node_file_storage_stub.dart';

class WebNodeFileStorage implements NodeFileStorage {
  @override
  Future<String> writeConfig(String fileContent) async {
    web.window.localStorage.setItem('iot_nodes_config.csv', fileContent);
    final blob = web.Blob(
      [fileContent.toJS].toJS,
      web.BlobPropertyBag(type: 'text/csv;charset=utf-8'),
    );
    final url = web.URL.createObjectURL(blob);
    try {
      (web.document.createElement('a') as web.HTMLAnchorElement)
        ..href = url
        ..download = 'iot_nodes_config.csv'
        ..click();
    } finally {
      web.URL.revokeObjectURL(url);
    }
    return 'Descargas (Navegador)';
  }

  @override
  Future<String?> readConfig(String filePath) async {
    return web.window.localStorage.getItem('iot_nodes_config.csv');
  }
}

NodeFileStorage createNodeFileStorage() => WebNodeFileStorage();

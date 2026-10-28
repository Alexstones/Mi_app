import 'dart:convert';
import 'dart:html' as html;
import 'node_file_storage_stub.dart';

class WebNodeFileStorage implements NodeFileStorage {
  @override
  Future<String> writeConfig(String fileContent) async {
    html.window.localStorage['iot_nodes_config.csv'] = fileContent;
    final bytes = utf8.encode(fileContent);
    final blob = html.Blob([bytes], 'text/csv;charset=utf-8');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', 'iot_nodes_config.csv')
      ..click();
    html.Url.revokeObjectUrl(url);
    return 'Descargas (Navegador)';
  }

  @override
  Future<String?> readConfig(String filePath) async {
    return html.window.localStorage['iot_nodes_config.csv'];
  }
}

NodeFileStorage createNodeFileStorage() => WebNodeFileStorage();

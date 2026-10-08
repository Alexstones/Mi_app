import 'dart:convert';
import 'dart:html' as html;

import 'storage_backend_stub.dart';

class WebStorageBackend implements StorageBackend {
  @override
  Future<String> write(String filename, String contents) async {
    html.window.localStorage[filename] = contents;
    if (filename.endsWith('.csv')) {
      final bytes = utf8.encode(contents);
      final blob = html.Blob([bytes], 'text/csv;charset=utf-8');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download', filename)
        ..click();
      html.Url.revokeObjectUrl(url);
      return 'Descargas (Navegador)';
    }
    return 'localStorage://$filename';
  }

  @override
  Future<String?> read(String filename) async {
    return html.window.localStorage[filename];
  }

  @override
  Future<String?> getPath(String filename) async {
    return 'localStorage://$filename';
  }
}

StorageBackend createStorageBackend() => WebStorageBackend();
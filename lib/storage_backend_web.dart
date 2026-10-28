import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'storage_backend_stub.dart';

class WebStorageBackend implements StorageBackend {
  @override
  Future<String> write(String filename, String contents) async {
    web.window.localStorage.setItem(filename, contents);
    if (filename.endsWith('.csv')) {
      final blob = web.Blob(
        [contents.toJS].toJS,
        web.BlobPropertyBag(type: 'text/csv;charset=utf-8'),
      );
      final url = web.URL.createObjectURL(blob);
      try {
        (web.document.createElement('a') as web.HTMLAnchorElement)
          ..href = url
          ..download = filename
          ..click();
      } finally {
        web.URL.revokeObjectURL(url);
      }
      return 'Descargas (Navegador)';
    }
    return 'localStorage://$filename';
  }

  @override
  Future<String?> read(String filename) async {
    return web.window.localStorage.getItem(filename);
  }

  @override
  Future<String?> getPath(String filename) async {
    return 'localStorage://$filename';
  }
}

StorageBackend createStorageBackend() => WebStorageBackend();

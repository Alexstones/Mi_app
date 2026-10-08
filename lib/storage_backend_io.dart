import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'storage_backend_stub.dart';

class IoStorageBackend implements StorageBackend {
  Future<File> _getLocalFile(String filename) async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}${Platform.pathSeparator}$filename');
  }

  @override
  Future<String> write(String filename, String contents) async {
    final file = await _getLocalFile(filename);
    final temporaryFile = File('${file.path}.tmp');
    await temporaryFile.writeAsString(contents, flush: true);
    if (await file.exists()) {
      await file.delete();
    }
    await temporaryFile.rename(file.path);
    return file.path;
  }

  @override
  Future<String?> read(String filename) async {
    final file = await _getLocalFile(filename);
    if (!await file.exists()) {
      return null;
    }
    return file.readAsString();
  }

  @override
  Future<String?> getPath(String filename) async {
    final file = await _getLocalFile(filename);
    return file.path;
  }
}

StorageBackend createStorageBackend() => IoStorageBackend();
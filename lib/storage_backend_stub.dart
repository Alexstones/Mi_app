abstract class StorageBackend {
  Future<String> write(String filename, String contents);

  Future<String?> read(String filename);

  Future<String?> getPath(String filename);
}

StorageBackend createStorageBackend() => throw UnsupportedError(
      'Esta plataforma no tiene un backend de almacenamiento disponible.',
    );
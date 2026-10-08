abstract class NodeFileStorage {
  Future<String> writeConfig(String fileContent);
  Future<String?> readConfig(String filePath);
}

NodeFileStorage createNodeFileStorage() =>
    throw UnsupportedError('Plataforma no soportada');

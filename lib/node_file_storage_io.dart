import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'node_file_storage_stub.dart';

class IoNodeFileStorage implements NodeFileStorage {
  @override
  Future<String> writeConfig(String fileContent) async {
    final dir = await getApplicationDocumentsDirectory();
    final filePath = '${dir.path}/iot_nodes_config.csv';
    final file = File(filePath);
    await file.writeAsString(fileContent);
    return filePath;
  }

  @override
  Future<String?> readConfig(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) return null;
    return await file.readAsString();
  }
}

NodeFileStorage createNodeFileStorage() => IoNodeFileStorage();

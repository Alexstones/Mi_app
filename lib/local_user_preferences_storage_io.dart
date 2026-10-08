import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import 'local_user_preferences_storage_stub.dart';

class IoLocalUserPreferencesStorage implements LocalUserPreferencesStorage {
  @override
  Future<String> save(LocalUserPreferences preferences) async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = path.join(directory.path, 'user_preferences.json');
    final data = preferences.toJson();
    final contents = await Isolate.run(() => jsonEncode(data));

    try {
      return await Isolate.run(() async {
        await File(filePath).writeAsString(contents, flush: true);
        return filePath;
      });
    } on FileSystemException catch (error) {
      throw LocalPreferencesWriteException(error.message);
    }
  }
}

LocalUserPreferencesStorage createLocalUserPreferencesStorageImpl() =>
    IoLocalUserPreferencesStorage();

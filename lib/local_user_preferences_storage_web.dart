import 'dart:convert';

import 'storage_backend_stub.dart' show StorageBackend;
import 'storage_backend_io.dart'
    if (dart.library.html) 'storage_backend_web.dart';
import 'local_user_preferences_storage_stub.dart';

class WebLocalUserPreferencesStorage implements LocalUserPreferencesStorage {
  @override
  Future<String> save(LocalUserPreferences preferences) async {
    final StorageBackend backend = createStorageBackend();
    return backend.write(
      'user_preferences.json',
      jsonEncode(preferences.toJson()),
    );
  }
}

LocalUserPreferencesStorage createLocalUserPreferencesStorageImpl() =>
    WebLocalUserPreferencesStorage();

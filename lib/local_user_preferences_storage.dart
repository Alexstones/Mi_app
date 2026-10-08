import 'local_user_preferences_storage_stub.dart' as stub;
import 'local_user_preferences_storage_io.dart'
    if (dart.library.html) 'local_user_preferences_storage_web.dart';

export 'local_user_preferences_storage_stub.dart'
    show LocalPreferencesWriteException, LocalUserPreferences;

stub.LocalUserPreferencesStorage createLocalUserPreferencesStorage() =>
    createLocalUserPreferencesStorageImpl();

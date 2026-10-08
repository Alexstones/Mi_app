class LocalUserPreferences {
  final bool darkTheme;
  final int samplingIntervalSeconds;

  const LocalUserPreferences({
    required this.darkTheme,
    required this.samplingIntervalSeconds,
  });

  Map<String, dynamic> toJson() => {
        'darkTheme': darkTheme,
        'samplingIntervalSeconds': samplingIntervalSeconds,
      };
}

class LocalPreferencesWriteException implements Exception {
  final String message;

  const LocalPreferencesWriteException(this.message);

  @override
  String toString() => message;
}

abstract class LocalUserPreferencesStorage {
  Future<String> save(LocalUserPreferences preferences);
}

LocalUserPreferencesStorage createLocalUserPreferencesStorage() =>
    throw UnsupportedError('Plataforma no soportada');

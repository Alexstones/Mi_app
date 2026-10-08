typedef FileLoadedCallback = void Function(String content, String fileName);

abstract class CsvFilePicker {
  void pickAndReadFile(FileLoadedCallback onLoaded);
}

CsvFilePicker createCsvFilePicker() =>
    throw UnsupportedError('Plataforma no soportada');


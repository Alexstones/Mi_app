import 'csv_file_picker_stub.dart';

class IoCsvFilePicker implements CsvFilePicker {
  @override
  void pickAndReadFile(FileLoadedCallback onLoaded) {
    // Para plataformas móviles/desktop sin paquete file_picker externo
    // Se puede implementar con file_picker o entrada manual
  }
}

CsvFilePicker createCsvFilePicker() => IoCsvFilePicker();


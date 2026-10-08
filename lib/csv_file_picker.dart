import 'csv_file_picker_stub.dart' as stub;
import 'csv_file_picker_io.dart'
    if (dart.library.html) 'csv_file_picker_web.dart';

export 'csv_file_picker_stub.dart' show CsvFilePicker, FileLoadedCallback;

stub.CsvFilePicker getCsvFilePicker() => createCsvFilePicker();


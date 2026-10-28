import 'dart:html' as html;
import 'csv_file_picker_stub.dart';

class WebCsvFilePicker implements CsvFilePicker {
  @override
  void pickAndReadFile(FileLoadedCallback onLoaded) {
    final uploadInput = html.FileUploadInputElement()..accept = '.csv,text/csv,text/plain';
    uploadInput.click();
    uploadInput.onChange.listen((event) {
      final files = uploadInput.files;
      if (files != null && files.isNotEmpty) {
        final file = files[0];
        final reader = html.FileReader();
        reader.onLoadEnd.listen((e) {
          final content = reader.result;
          if (content is String) {
            onLoaded(content, file.name);
          }
        });
        reader.readAsText(file);
      }
    });
  }
}

CsvFilePicker createCsvFilePicker() => WebCsvFilePicker();


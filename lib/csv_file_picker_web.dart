import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'csv_file_picker_stub.dart';

class WebCsvFilePicker implements CsvFilePicker {
  @override
  void pickAndReadFile(FileLoadedCallback onLoaded) {
    final input = web.HTMLInputElement()
      ..type = 'file'
      ..accept = '.csv,text/csv,text/plain';

    input.addEventListener('change', ((web.Event event) {
      final file = input.files?.item(0);
      if (file == null) return;

      final reader = web.FileReader();
      reader.addEventListener('load', ((web.Event event) {
        final content = reader.result?.dartify();
        if (content is String) {
          onLoaded(content, file.name);
        }
      }).toJS);
      reader.readAsText(file);
    }).toJS);
    input.click();
  }
}

CsvFilePicker createCsvFilePicker() => WebCsvFilePicker();

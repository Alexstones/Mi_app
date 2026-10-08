import 'dart:convert';

import 'package:encrypt/encrypt.dart' as encrypt;

import 'storage_backend_stub.dart' as storage_backend;
import 'storage_backend_io.dart'
    if (dart.library.html) 'storage_backend_web.dart';

class EncryptedJsonStorage {
  EncryptedJsonStorage()
      : _key = encrypt.Key.fromUtf8('my32lengthsupersecretkey12345678'),
        _iv = encrypt.IV.fromUtf8('1234567890123456'),
        _backend = createStorageBackend();

  final encrypt.Key _key;
  final encrypt.IV _iv;
  final storage_backend.StorageBackend _backend;

  Future<String> saveEncryptedJson(
    String filename,
    dynamic data,
  ) async {
    final encrypter = encrypt.Encrypter(encrypt.AES(_key));
    final encryptedData = encrypter.encrypt(jsonEncode(data), iv: _iv);

    return _backend.write(filename, encryptedData.base64);
  }

  Future<dynamic> readEncryptedJson(String filename) async {
    try {
      final encryptedText = await _backend.read(filename);
      if (encryptedText == null) {
        return null;
      }

      final encrypter = encrypt.Encrypter(encrypt.AES(_key));
      final decryptedText = encrypter.decrypt64(encryptedText, iv: _iv);
      final decoded = jsonDecode(decryptedText);

      if (decoded is! Map && decoded is! List) {
        throw const FormatException('El archivo no contiene un objeto o lista JSON.');
      }
      return decoded;
    } catch (_) {
      return null;
    }
  }

  Future<String> saveCsv(String filename, String csvContent) async {
    return _backend.write(filename, csvContent);
  }

  Future<String?> readCsv(String filename) async {
    return _backend.read(filename);
  }

  Future<String?> getFilePath(String filename) async {
    return _backend.getPath(filename);
  }
}
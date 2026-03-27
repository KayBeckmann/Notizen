import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

class StorageService {
  static Future<String> getAppDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  static Future<String> saveImage(File file) async {
    final appDir = await getAppDirectory();
    final imagesDir = Directory(p.join(appDir, 'images'));
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }
    final fileName = '${const Uuid().v4()}${p.extension(file.path)}';
    final newFile = await file.copy(p.join(imagesDir.path, fileName));
    return newFile.path;
  }

  static Future<String> getAudioPath() async {
    final appDir = await getAppDirectory();
    final audioDir = Directory(p.join(appDir, 'audio'));
    if (!await audioDir.exists()) {
      await audioDir.create(recursive: true);
    }
    return p.join(audioDir.path, '${const Uuid().v4()}.m4a');
  }
}

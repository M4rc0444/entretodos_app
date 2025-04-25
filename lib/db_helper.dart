import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:io';
import 'dart:typed_data';


class DBHelper {
  static Future<Database> openDB() async {
    var databasesPath = await getDatabasesPath();
    var path = join(databasesPath, "entretodos.db");

    // Copiar desde assets si no existe
    var exists = await databaseExists(path);
    if (!exists) {
      ByteData data = await rootBundle.load("assets/entretodos.db");
      List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      await File(path).writeAsBytes(bytes, flush: true);
    }

    return await openDatabase(path);
  }
}

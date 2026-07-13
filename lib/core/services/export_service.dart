import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'database_service.dart';

class ExportService {
  final DatabaseService _db;

  ExportService(this._db);

  Future<void> exportToJson() async {
    try {
      final json = await _db.exportToJson();
      final result = await FilePicker.saveFile(
        dialogTitle: 'Save backup',
        fileName: 'stashreader_backup.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result != null) {
        await File(result).writeAsString(json);
      }
    } catch (e) {
      throw Exception('Export failed: $e');
    }
  }

  Future<String> importFromJson() async {
    try {
      final result = await FilePicker.pickFiles(
        dialogTitle: 'Select backup file',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result == null || result.files.isEmpty) {
        return 'Import cancelled';
      }
      final file = File(result.files.single.path!);
      final json = await file.readAsString();
      await _db.importFromJson(json);
      return 'Import successful';
    } catch (e) {
      throw Exception('Import failed: $e');
    }
  }
}

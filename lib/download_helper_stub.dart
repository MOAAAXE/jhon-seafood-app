import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';

Future<String?> saveExcelBytes(List<int> bytes, String fileName) async {
  final path = await FilePicker.platform.saveFile(
    fileName: fileName,
    bytes: Uint8List.fromList(bytes),
    type: FileType.custom,
    allowedExtensions: ['xlsx'],
  );
  return path;
}
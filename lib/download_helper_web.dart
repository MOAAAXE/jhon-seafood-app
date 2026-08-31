import 'dart:typed_data';
import 'package:file_saver/file_saver.dart';

Future<String> saveExcelBytes(List<int> bytes, String fileName) async {
  final path = await FileSaver.instance.saveFile(
    name: fileName.replaceAll('.xlsx', ''),
    bytes: Uint8List.fromList(bytes),
    ext: 'xlsx',
    mimeType: MimeType.microsoftExcel,
  );
  return 'File "$fileName" berhasil disimpan di $path';
}
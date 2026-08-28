import 'dart:io';
import 'package:path_provider/path_provider.dart';

Future<String> saveExcelBytes(List<int> bytes, String fileName) async {
  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/$fileName');
  await file.writeAsBytes(bytes);
  return file.path;
}
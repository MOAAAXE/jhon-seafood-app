import 'package:excel/excel.dart';
import 'main.dart';
import 'download_helper.dart';

const List<String> _monthNamesId = [
  '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
  'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
];

/// Membuat file Excel berisi rekap omzet & jumlah transaksi PER BULAN
/// untuk satu tahun tertentu (1 baris = 1 bulan), lalu
/// menyimpan/mengunduhnya. Mengembalikan lokasi file, atau null
/// kalau pengguna membatalkan penyimpanan.
Future<String?> exportYearlyMonthlyRecapToExcel(int year) async {
  final excelFile = Excel.createExcel();
  const sheetName = 'Rekap Bulanan';
  final Sheet sheet = excelFile[sheetName];
  if (excelFile.sheets.containsKey('Sheet1')) {
    excelFile.delete('Sheet1');
  }

  // Header kolom
  sheet.appendRow([
    TextCellValue('Bulan'),
    TextCellValue('Jumlah Transaksi'),
    TextCellValue('Total Omzet (Rp)'),
  ]);

  // Siapkan akumulator per bulan (1-12)
  final Map<int, int> omzetPerBulan = {for (var m = 1; m <= 12; m++) m: 0};
  final Map<int, int> transaksiPerBulan = {for (var m = 1; m <= 12; m++) m: 0};

  for (final order in dailyOrders) {
    if (order.dateTime.year == year) {
      omzetPerBulan[order.dateTime.month] =
          (omzetPerBulan[order.dateTime.month] ?? 0) + order.totalAmount;
      transaksiPerBulan[order.dateTime.month] =
          (transaksiPerBulan[order.dateTime.month] ?? 0) + 1;
    }
  }

  int totalOmzetTahun = 0;
  int totalTransaksiTahun = 0;

  for (var month = 1; month <= 12; month++) {
    final omzet = omzetPerBulan[month] ?? 0;
    final jumlah = transaksiPerBulan[month] ?? 0;
    totalOmzetTahun += omzet;
    totalTransaksiTahun += jumlah;

    sheet.appendRow([
      TextCellValue(_monthNamesId[month]),
      IntCellValue(jumlah),
      IntCellValue(omzet),
    ]);
  }

  // Baris ringkasan total tahunan
  sheet.appendRow([]);
  sheet.appendRow([
    TextCellValue('TOTAL TAHUN $year'),
    IntCellValue(totalTransaksiTahun),
    IntCellValue(totalOmzetTahun),
  ]);

  final bytes = excelFile.save();
  if (bytes == null) {
    throw Exception('Gagal membuat file Excel');
  }

  final fileName = 'Rekap_Bulanan_JhonSeafood_$year.xlsx';
  return saveExcelBytes(bytes, fileName); // sekarang cocok: Future<String?>
}
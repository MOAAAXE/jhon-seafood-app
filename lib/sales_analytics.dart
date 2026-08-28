import 'main.dart';

// ==========================================
// ANALITIK PENJUALAN
// Dipakai oleh SalesChartScreen untuk membuat
// grafik omzet harian & daftar menu terlaris.
// ==========================================

/// Menghitung total omzet per bulan (1-12) untuk tahun tertentu.
Map<int, int> monthlyRevenue(int year) {
  final Map<int, int> result = {for (var m = 1; m <= 12; m++) m: 0};
  for (final order in dailyOrders) {
    if (order.dateTime.year == year) {
      result[order.dateTime.month] = (result[order.dateTime.month] ?? 0) + order.totalAmount;
    }
  }
  return result;
}

/// Menghitung jumlah transaksi per bulan (1-12) untuk tahun tertentu.
Map<int, int> monthlyTransactionCount(int year) {
  final Map<int, int> result = {for (var m = 1; m <= 12; m++) m: 0};
  for (final order in dailyOrders) {
    if (order.dateTime.year == year) {
      result[order.dateTime.month] = (result[order.dateTime.month] ?? 0) + 1;
    }
  }
  return result;
}

/// Menghitung total omzet per tanggal (1-31) untuk bulan & tahun tertentu.
Map<int, int> dailyRevenue(int year, int month) {
  final daysInMonth = DateTime(year, month + 1, 0).day;
  final Map<int, int> result = {for (var d = 1; d <= daysInMonth; d++) d: 0};
  for (final order in dailyOrders) {
    if (order.dateTime.year == year && order.dateTime.month == month) {
      result[order.dateTime.day] = (result[order.dateTime.day] ?? 0) + order.totalAmount;
    }
  }
  return result;
}

/// Menghitung jumlah transaksi per tanggal (1-31) untuk bulan & tahun tertentu.
Map<int, int> dailyTransactionCount(int year, int month) {
  final daysInMonth = DateTime(year, month + 1, 0).day;
  final Map<int, int> result = {for (var d = 1; d <= daysInMonth; d++) d: 0};
  for (final order in dailyOrders) {
    if (order.dateTime.year == year && order.dateTime.month == month) {
      result[order.dateTime.day] = (result[order.dateTime.day] ?? 0) + 1;
    }
  }
  return result;
}

/// Menghitung menu terlaris (berdasarkan jumlah terjual).
/// Bisa difilter berdasarkan tahun dan/atau bulan tertentu.
List<MapEntry<String, int>> topSellingMenu({int? year, int? month, int topN = 5}) {
  final Map<String, int> qtyMap = {};
  for (final order in dailyOrders) {
    if (year != null && order.dateTime.year != year) continue;
    if (month != null && order.dateTime.month != month) continue;
    for (final item in order.items) {
      qtyMap[item.menu.name] = (qtyMap[item.menu.name] ?? 0) + item.quantity;
    }
  }
  final sorted = qtyMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  return sorted.take(topN).toList();
}

/// Daftar tahun yang punya data transaksi (untuk dropdown pilihan tahun).
List<int> availableYears() {
  final years = dailyOrders.map((o) => o.dateTime.year).toSet().toList()..sort();
  if (years.isEmpty) years.add(DateTime.now().year);
  return years;
}
// Helper lintas platform untuk menyimpan/mengunduh file Excel.
// Otomatis memakai implementasi Web (unduh langsung lewat browser)
// saat dibuild untuk web, atau implementasi IO (Android/iOS/Desktop,
// simpan ke folder dokumen aplikasi) saat dibuild untuk platform lain.
export 'download_helper_stub.dart' if (dart.library.html) 'download_helper_web.dart';
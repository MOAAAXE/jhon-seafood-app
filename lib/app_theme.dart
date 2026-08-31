import 'package:flutter/material.dart';

// ==========================================
// PUSAT STYLING APLIKASI JHON SEAFOOD 68
// Semua warna, TextStyle, dan dekorasi
// dikumpulkan di sini supaya mudah diubah
// tanpa menyentuh logic di main.dart
// ==========================================

class AppColors {
  // --- Warna utama: TIDAK diubah ---
  static const Color primary = Colors.deepOrange;

  // Varian dari warna utama, untuk kedalaman (gradient, tekan/hover, shadow)
  static final Color primaryDark = Colors.deepOrange.shade800;
  static final Color primaryMid = Colors.deepOrange.shade600;
  static Color primaryLight = Colors.deepOrange.shade50;
  static final Color primarySoftBorder = Colors.deepOrange.shade100;

  // Aksen kedua bernuansa laut — dipakai secukupnya untuk elemen
  // yang butuh pembeda dari oranye (mis. badge info, ikon sekunder),
  // bukan untuk elemen aksi utama.
  static const Color ocean = Color(0xFF0E7C7B);
  static final Color oceanLight = const Color(0xFF0E7C7B).withOpacity(0.10);

  static Color borderGrey = Colors.grey.shade300;

  // Warna semantik, dibuat sedikit lebih kaya dari warna Material default
  // supaya konsisten dengan palet hangat, tapi tetap terbaca sesuai maknanya.
  static const Color success = Color(0xFF2E9E44);
  static const Color danger = Color(0xFFD64545);
  static const Color info = Color(0xFF2F80C9);
  static final Color infoDark = Colors.blue.shade700;

  static const Color white = Colors.white;
  static const Color grey = Colors.grey;

  // Latar & permukaan hangat (bukan putih/abu polos)
  static const Color background = Color(0xFFFFF8F3);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFFBF1E8);

  // Teks dengan sedikit kehangatan, bukan hitam pekat
  static const Color textPrimary = Color(0xFF2B211B);
  static const Color textSecondary = Color(0xFF8A7A6D);
}


class AppShadows {
  static List<BoxShadow> card = [
    BoxShadow(
      color: AppColors.primary.withOpacity(0.06),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];

  static List<BoxShadow> button = [
    BoxShadow(
      color: AppColors.primaryDark.withOpacity(0.28),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> subtle = [
    BoxShadow(
      color: AppColors.textPrimary.withOpacity(0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];
}


class AppGradients {
  static LinearGradient primary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.primaryMid, AppColors.primaryDark],
  );

  static LinearGradient primarySubtle = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.primaryLight, AppColors.background],
  );
}

class AppTextStyles {
  static const TextStyle appTitle = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
    color: AppColors.primary,
  );

  static const TextStyle appBarTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
    color: AppColors.white,
  );

  static const TextStyle menuName = TextStyle(
    fontWeight: FontWeight.w700,
    fontSize: 15,
    color: AppColors.textPrimary,
  );

  static const TextStyle cartQuantity = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const TextStyle totalLabel = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle totalValue = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.3,
    color: AppColors.primary,
  );

  static const TextStyle reportDateLabel = TextStyle(fontSize: 14, color: AppColors.textSecondary);

  static const TextStyle reportOmzetValue = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.4,
    color: AppColors.primary,
  );

  static const TextStyle reportTransactionCount = TextStyle(
    fontSize: 12,
    color: AppColors.success,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle orderItemPrice = TextStyle(
    fontWeight: FontWeight.bold,
    color: AppColors.primary,
  );

  static const TextStyle orderNotes = TextStyle(
    color: Colors.redAccent,
    fontStyle: FontStyle.italic,
  );

  static const TextStyle cashierInfo = TextStyle(fontSize: 11, color: AppColors.textSecondary);

  static const TextStyle qrisSectionLabel = TextStyle(
    fontWeight: FontWeight.w700,
    fontSize: 12,
    color: AppColors.textSecondary,
  );

  static const TextStyle qrisPlaceholder = TextStyle(fontSize: 10, color: AppColors.textSecondary);

  static const TextStyle proofSuccess = TextStyle(
    color: AppColors.success,
    fontWeight: FontWeight.bold,
    fontSize: 13,
  );
}

class AppDecorations {
  static InputDecoration searchField({
    required String labelText,
    required bool showClear,
    required VoidCallback onClear,
  }) {
    return InputDecoration(
      labelText: labelText,
      filled: true,
      fillColor: AppColors.surface,
      prefixIcon: const Icon(Icons.search, color: AppColors.primary),
      suffixIcon: showClear ? IconButton(icon: const Icon(Icons.clear), onPressed: onClear) : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.borderGrey),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.borderGrey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
      ),
    );
  }

  static BoxDecoration reportSummaryCard = BoxDecoration(
    gradient: AppGradients.primarySubtle,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: AppColors.primarySoftBorder),
    boxShadow: AppShadows.card,
  );

  static BoxDecoration qrisImageBox = BoxDecoration(
    color: AppColors.white,
    border: Border.all(color: AppColors.borderGrey),
    borderRadius: BorderRadius.circular(12),
    boxShadow: AppShadows.subtle,
  );

  // Dekorasi kartu umum baru, siap dipakai untuk Container pengganti
  // Card() polos kalau ingin tampilan lebih premium (bayangan hangat,
  // sudut lebih membulat).
  static BoxDecoration elevatedCard = BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(16),
    boxShadow: AppShadows.card,
  );
}

class AppButtonStyles {
  static ButtonStyle primary = ElevatedButton.styleFrom(
    backgroundColor: AppColors.primary,
    foregroundColor: AppColors.white,
    elevation: 3,
    shadowColor: AppColors.primaryDark.withOpacity(0.4),
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    textStyle: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.2),
  );

  static ButtonStyle infoDark = ElevatedButton.styleFrom(
    backgroundColor: AppColors.infoDark,
    foregroundColor: AppColors.white,
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  );

  static ButtonStyle qrisTextButton = TextButton.styleFrom(
    padding: EdgeInsets.zero,
    minimumSize: const Size(50, 30),
    foregroundColor: AppColors.primary,
  );

  static ButtonStyle proofLinkButton = TextButton.styleFrom(foregroundColor: AppColors.infoDark);

  // Varian aksen laut, opsional dipakai untuk aksi sekunder yang ingin
  // dibedakan dari aksi utama (oranye) tanpa memakai warna semantik lain.
  static ButtonStyle oceanOutline = OutlinedButton.styleFrom(
    foregroundColor: AppColors.ocean,
    side: const BorderSide(color: AppColors.ocean, width: 1.4),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
  );
}

class AppTheme {
  static ThemeData get themeData {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
        secondary: AppColors.ocean,
        surface: AppColors.surface,
      ),
      scaffoldBackgroundColor: AppColors.background,
    );

    return base.copyWith(
      primaryColor: AppColors.primary,
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextStyles.appBarTitle,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(18)),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.borderGrey.withOpacity(0.5)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(style: AppButtonStyles.primary),
      outlinedButtonTheme: OutlinedButtonThemeData(style: AppButtonStyles.oceanOutline),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.borderGrey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.borderGrey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: AppColors.surfaceMuted,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary),
        shape: StadiumBorder(side: BorderSide(color: AppColors.primarySoftBorder)),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: const TextStyle(color: AppColors.white),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.borderGrey.withOpacity(0.7),
        thickness: 1,
        space: 24,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: AppColors.primary,
        titleTextStyle: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      ),
    );
  }
}
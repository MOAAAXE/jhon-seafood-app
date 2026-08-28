import 'package:flutter/material.dart';

// ==========================================
// PUSAT STYLING APLIKASI JHON SEAFOOD 68
// Semua warna, TextStyle, dan dekorasi
// dikumpulkan di sini supaya mudah diubah
// tanpa menyentuh logic di main.dart
// ==========================================
class AppColors {
  static const Color primary = Colors.deepOrange;
  static Color primaryLight = Colors.deepOrange.shade50;
  static Color borderGrey = Colors.grey.shade300;
  static const Color success = Colors.green;
  static const Color danger = Colors.red;
  static const Color info = Colors.blue;
  static Color infoDark = Colors.blue.shade700;
  static const Color white = Colors.white;
  static const Color grey = Colors.grey;
}

class AppTextStyles {
  static const TextStyle appTitle = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.primary,
  );

  static const TextStyle appBarTitle = TextStyle(
    fontWeight: FontWeight.bold,
    color: AppColors.white,
  );

  static const TextStyle menuName = TextStyle(fontWeight: FontWeight.bold);

  static const TextStyle cartQuantity = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle totalLabel = TextStyle(color: AppColors.grey, fontSize: 12);

  static const TextStyle totalValue = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.primary,
  );

  static const TextStyle reportDateLabel = TextStyle(fontSize: 14, color: AppColors.grey);

  static const TextStyle reportOmzetValue = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.bold,
    color: AppColors.primary,
  );

  static const TextStyle reportTransactionCount = TextStyle(
    fontSize: 12,
    color: AppColors.success,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle orderItemPrice = TextStyle(
    fontWeight: FontWeight.bold,
    color: AppColors.primary,
  );

  static const TextStyle orderNotes = TextStyle(
    color: Colors.redAccent,
    fontStyle: FontStyle.italic,
  );

  static const TextStyle cashierInfo = TextStyle(fontSize: 11, color: AppColors.grey);

  static const TextStyle qrisSectionLabel = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 12,
    color: AppColors.grey,
  );

  static const TextStyle qrisPlaceholder = TextStyle(fontSize: 10, color: AppColors.grey);

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
      prefixIcon: const Icon(Icons.search, color: AppColors.primary),
      suffixIcon: showClear ? IconButton(icon: const Icon(Icons.clear), onPressed: onClear) : null,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  static BoxDecoration reportSummaryCard = BoxDecoration(
    color: AppColors.primaryLight,
    borderRadius: BorderRadius.circular(12),
  );

  static BoxDecoration qrisImageBox = BoxDecoration(
    color: AppColors.white,
    border: Border.all(color: AppColors.borderGrey),
    borderRadius: BorderRadius.circular(8),
  );
}

class AppButtonStyles {
  static ButtonStyle primary = ElevatedButton.styleFrom(
    backgroundColor: AppColors.primary,
    foregroundColor: AppColors.white,
  );

  static ButtonStyle infoDark = ElevatedButton.styleFrom(
    backgroundColor: AppColors.infoDark,
    foregroundColor: AppColors.white,
  );

  static ButtonStyle qrisTextButton = TextButton.styleFrom(
    padding: EdgeInsets.zero,
    minimumSize: const Size(50, 30),
  );

  static ButtonStyle proofLinkButton = TextButton.styleFrom(foregroundColor: AppColors.infoDark);
}

class AppTheme {
  static ThemeData get themeData => ThemeData(
        primarySwatch: Colors.deepOrange,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        useMaterial3: true,
      );
}
// Smoke test untuk aplikasi Jhon Seafood 68.
// Memastikan aplikasi bisa dijalankan dan menampilkan LoginScreen
// tanpa error saat pertama kali dibuka.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jhon_seafood_app/main.dart';

void main() {
  testWidgets('Aplikasi menampilkan halaman Login', (WidgetTester tester) async {
    // Bangun aplikasi dan trigger frame pertama.
    await tester.pumpWidget(const JhonSeafoodApp());

    // Pastikan judul aplikasi muncul di LoginScreen.
    expect(find.text('Jhon Seafood 68'), findsOneWidget);

    // Pastikan field Username dan Password ada.
    expect(find.widgetWithText(TextField, 'Username'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));

    // Pastikan tombol LOGIN ada.
    expect(find.widgetWithText(ElevatedButton, 'LOGIN'), findsOneWidget);
  });

  testWidgets('Login gagal menampilkan snackbar saat salah input', (WidgetTester tester) async {
    await tester.pumpWidget(const JhonSeafoodApp());

    // Tekan tombol LOGIN tanpa mengisi apa pun.
    await tester.tap(find.widgetWithText(ElevatedButton, 'LOGIN'));
    await tester.pump(); // proses SnackBar

    expect(find.text('Username/Password salah!'), findsOneWidget);
  });
}
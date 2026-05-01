import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // ── Palet Warna Utama ──
  static const Color primaryColor = Color(0xFF1A73E8); // Biru Google-ish
  static const Color secondaryColor = Color(0xFF34A853); // Hijau aksen

  // Warna Status (sesuai PRD 8.1)
  static const Color statusPending = Color(0xFFF57C00); // Oranye
  static const Color statusPublished = Color(0xFF388E3C); // Hijau tua
  static const Color statusClaimed = Color(0xFF1565C0); // Biru tua
  static const Color statusCompleted = Color(0xFF757575); // Abu-abu
  static const Color statusRejected = Color(0xFFD32F2F); // Merah

  // ── Light Theme ──
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 1,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
  );

  // ── Warna Status Helper ──
  static Color statusColor(String status) {
    return switch (status) {
      'pending' => statusPending,
      'published' => statusPublished,
      'claimed' => statusClaimed,
      'completed' => statusCompleted,
      'rejected' => statusRejected,
      _ => Colors.grey,
    };
  }

  static String statusLabel(String status) {
    return switch (status) {
      'pending' => 'Menunggu Verifikasi',
      'published' => 'Dipublikasi',
      'claimed' => 'Sedang Diklaim',
      'completed' => 'Selesai',
      'rejected' => 'Ditolak',
      _ => status,
    };
  }
}

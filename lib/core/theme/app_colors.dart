import 'package:flutter/material.dart';

class AppColors {
  // --- Warna Utama (Purple Palette) ---
  static const Color wrnLightPurple = Color(0xFFBB86FC);
  static const Color wrnDeepPurple = Color(0xFF6200EE);
  static const Color wrnDarkestPurple = Color(0xFF3700B3);
  static const Color wrnBtsPurple = Color(
    0xFF6C63FF,
  ); // Ungu cerah untuk tombol utama

  // --- Warna Baru untuk Dark Theme & Glassmorphism ---
  static const Color wrnDarkBg = Color(0xFF13131D); // Background utama gelap
  static const Color wrnDarkInput = Color(
    0xFF1E1E2C,
  ); // Background field input (sedikit lebih terang)

  // Warna untuk Bentuk Organik (Lingkaran) di Latar Belakang
  static const Color wrnShapePurple = Color(0xFF4B3C99);
  static const Color wrnShapeRose = Color(0xFFA17281);

  // --- Warna Netral & Status ---
  static const Color background =
      Colors.white; // Tetap simpan jika butuh Light Mode
  static const Color surface = Colors.white;
  static const Color error = Color(0xFFB00020);

  // --- Warna Teks ---
  static const Color textPrimary = Colors.black;
  static const Color textWhite =
      Colors.white; // Tambahan untuk teks di layar gelap
  static const Color textSecondary = Color(0xFF757575);
  static const Color textGrey =
      Colors.white54; // Untuk hint text atau deskripsi kecil

  // --- Gradient Definisi ---
  // Gradient lama (opsional tetap disimpan)
  static const LinearGradient wrnGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [wrnLightPurple, wrnDeepPurple],
    stops: [0.0, 1.0],
  );

  // Gradient baru jika ingin dipakai di tombol agar lebih 'glow'
  static const LinearGradient wrnButtonGradient = LinearGradient(
    colors: [wrnBtsPurple, wrnDeepPurple],
  );
}

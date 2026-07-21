import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class AppColors {
  static const Color primary = Color(0xFF4ECDC4);
  static const Color secondary = Color(0xFFFF6B6B);
  static const Color accent = Color(0xFF45B7D1);
  static const Color success = Color(0xFF96CEB4);
  static const Color warning = Color(0xFFFFEAA7);
  static const Color danger = Color(0xFFFF6B6B);
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Colors.white;
  static const Color border = Color(0xFFE2E8F0);
  static const Color text = Color(0xFF2D3748);
  static const Color textLight = Color(0xFF718096);
}

class AppTextStyles {
  static final TextStyle display = GoogleFonts.poppins(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.text,
  );

  static final TextStyle heading = GoogleFonts.poppins(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: AppColors.text,
  );

  static final TextStyle subheading = GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.text,
  );

  static final TextStyle body = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.text,
  );

  static final TextStyle bodyBold = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.text,
  );

  static final TextStyle caption = GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textLight,
  );

  static final TextStyle button = GoogleFonts.poppins(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
}

String formatRupiah(int harga) => NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(harga);

import 'package:flutter/material.dart';

class AppTheme {
  // Felt table colors
  static const Color feltGreen = Color(0xFF064E3B);
  static const Color feltDarkGreen = Color(0xFF032C21);
  static const Color feltDeepGreen = Color(0xFF021E17);
  static const Color modalBg = Color(0xFF062D24);

  // Gold luxury accents
  static const Color goldLight = Color(0xFFFDE047);
  static const Color gold = Color(0xFFFACC15);
  static const Color goldDark = Color(0xFFEAB308);
  static const Color goldBorder = Color(0xFFCA8A04);

  // Suits
  static const Color suitRed = Color(0xFFDC2626);
  static const Color suitBlack = Color(0xFF111827);

  // Gradients
  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFFDE047), Color(0xFFFACC15), Color(0xFFEAB308)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardBackGradient = LinearGradient(
    colors: [Color(0xFF1E1B4B), Color(0xFF311042), Color(0xFF450A0A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient modalHeaderGradient = LinearGradient(
    colors: [Color(0xEE065F46), Colors.transparent],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Box shadows
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.35),
      blurRadius: 8,
      offset: const Offset(0, 3),
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.2),
      blurRadius: 2,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> get playableGlow => [
    const BoxShadow(
      color: Color(0xFFFACC15),
      blurRadius: 16,
      spreadRadius: 2,
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.4),
      blurRadius: 10,
      offset: const Offset(0, 8),
    ),
  ];
}

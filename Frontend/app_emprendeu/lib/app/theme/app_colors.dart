import 'package:flutter/painting.dart';

/// Tokens de color del diseño (ver `design.md` §3.1).
/// Ningún widget debe declarar colores sueltos: todo sale de aquí o del tema.
abstract final class AppColors {
  // Marca
  static const navy950 = Color(0xFF021F50);
  static const navy900 = Color(0xFF0A1A44);
  static const primary = Color(0xFF1F4FD6);
  static const blue50 = Color(0xFFEAF0FF);
  static const blue100 = Color(0xFFDCE6FF);
  static const blue800 = Color(0xFF12308A);
  static const blueRing = Color(0xFF7FA6FF);
  static const blueTrack = Color(0xFF9DB7F5);

  // Texto sobre fondos navy
  static const onNavy = Color(0xFFFFFFFF);
  static const onNavyLabel = Color(0xFFE3EAFB);
  static const onNavyMuted = Color(0xFFC9D6F5);
  static const onNavyHint = Color(0xFF9FB4EE);

  // Acento
  static const accent = Color(0xFFD61F3A);
  static const accentBright = Color(0xFFFF5468);
  static const accentSoft = Color(0xFFFF8A9A);
  static const accentTint = Color(0xFFFFE3E8);
  static const accentOn = Color(0xFF8F0F25);
  static const error = Color(0xFFB3122D);

  // Estados
  static const success = Color(0xFF0E7A4F);
  static const successDark = Color(0xFF0A5C39);
  static const successTint = Color(0xFFDDF3E7);
  static const warning = Color(0xFFB26A00);
  static const warningTint = Color(0xFFFFF0CC);
  static const warningOn = Color(0xFF5E3F00);

  // Neutros
  static const ink = Color(0xFF0E1730);
  static const ink2 = Color(0xFF2B3552);
  static const muted = Color(0xFF4A5675);
  static const background = Color(0xFFF3F6FD);
  static const surface = Color(0xFFFFFFFF);
  static const border = Color(0xFFE1E6F0);
  static const borderStrong = Color(0xFFCBD3E6);

  /// Borde de un control sin marcar (casilla, interruptor apagado).
  static const outlineOff = Color(0xFF9AA6C4);
  static const divider = Color(0xFFEEF2FA);
  static const neutralFill = Color(0xFFE7ECF6);
}

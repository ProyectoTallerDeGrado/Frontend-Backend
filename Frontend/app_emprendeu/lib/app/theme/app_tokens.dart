import 'package:flutter/animation.dart';

/// Espaciado (ver `design.md` §3.3). Múltiplos de 4; las pantallas usan [screen] a los lados.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;

  /// Margen lateral de toda pantalla.
  static const double screen = 20;
}

/// Radios por jerarquía (ver `design.md` §3.3): cuanto más grande la superficie, más radio.
abstract final class AppRadii {
  static const double checkbox = 9;
  static const double buttonSmall = 12;

  /// Botones e inputs.
  static const double control = 14;
  static const double card = 18;
  static const double cardLarge = 24;
  static const double sheet = 26;
  static const double pill = 999;
}

/// Movimiento (ver `design.md` §3.4): lo que entra desacelera, lo que sale dura menos, y el
/// rebote se reserva para confirmar una acción o celebrar.
abstract final class AppMotion {
  /// Respuesta al toque.
  static const tap = Duration(milliseconds: 120);

  /// Controles: chips, casillas, la píldora de la barra inferior.
  static const control = Duration(milliseconds: 200);

  /// Tarjetas, banners y hojas que entran.
  static const panel = Duration(milliseconds: 320);

  /// Entradas con énfasis.
  static const emphasis = Duration(milliseconds: 500);

  /// Acentos celebratorios (anillo de XP, trazado del camino).
  static const celebrate = Duration(milliseconds: 1400);

  static const Curve enter = Curves.easeOutCubic;
  static const Curve exit = Curves.easeInCubic;
  static const Curve spring = Curves.easeOutBack;
}

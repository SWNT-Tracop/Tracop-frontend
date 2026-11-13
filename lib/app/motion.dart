import 'package:flutter/widgets.dart';

// Tiempos de animacion y avisos; respeta "reducir movimiento" del sistema.
abstract final class AppMotion {
  static const Duration fast = Duration(milliseconds: 240);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration snackBar = Duration(seconds: 4);

  static Duration of(BuildContext context, Duration value) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : value;
}

import 'package:flutter/material.dart';

import 'motion.dart';

// Permite mostrar avisos desde fuera de una pantalla (ej. sesion vencida).
final appMessengerKey = GlobalKey<ScaffoldMessengerState>();

void showAppNotice(String message, {IconData? icon}) {
  final messenger = appMessengerKey.currentState;
  if (messenger == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      duration: AppMotion.snackBar,
      content: Row(children: [
        if (icon != null) ...[
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 12),
        ],
        Expanded(child: Text(message)),
      ]),
    ));
}

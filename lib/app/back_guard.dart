import 'package:flutter/foundation.dart';

// Una pantalla puede pedir confirmar antes de que el shell la cierre.
// Devuelve true si se puede salir.
final backGuard = ValueNotifier<Future<bool> Function()?>(null);

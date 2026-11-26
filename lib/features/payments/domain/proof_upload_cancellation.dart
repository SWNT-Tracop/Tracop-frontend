import 'dart:async';

/// Permite cancelar una carga de comprobante en curso sin que el dominio
/// dependa de Dio. La capa de datos la traduce a un `CancelToken`.
class ProofUploadCancellation {
  final _completer = Completer<void>();

  bool get isCancelled => _completer.isCompleted;

  /// Se completa al cancelar (una sola vez).
  Future<void> get whenCancelled => _completer.future;

  void cancel() {
    if (!_completer.isCompleted) _completer.complete();
  }
}

/// Código del resultado de una carga cancelada por el usuario. No es un
/// error: la interfaz lo muestra como "Carga cancelada".
const proofUploadCancelledCode = 'proof_upload_cancelled';

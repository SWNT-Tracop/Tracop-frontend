import '../../../core/config/payment_config.dart';
import '../../../core/result/result.dart';

/// Único lugar donde los errores de pagos se traducen a español. Nunca
/// muestra el mensaje técnico ni URLs: solo textos propios.
String paymentErrorText(DomainFailure failure) => switch (failure.code) {
      'offline' ||
      'network_error' =>
        'Sin conexión. Conéctate a internet e intenta de nuevo.',
      'unauthorized' ||
      'invalid_session' ||
      'session_expired' ||
      'session_invalid' =>
        'Tu sesión venció. Inicia sesión de nuevo para continuar.',
      'forbidden' ||
      'access_denied' ||
      'invalid_role' =>
        'Tu cuenta no tiene permiso para esta acción de pago.',
      'not_found' =>
        'No encontramos el pago. Puede que no exista o que no tengas acceso.',
      'reservation_expired' =>
        'La reserva del pedido venció; el pedido ya no se puede pagar.',
      'version_conflict' =>
        'El pago cambió mientras lo revisabas. Carga la última versión e intenta de nuevo.',
      'invalid_transition' =>
        'El estado actual del pago ya no permite esta acción.',
      'settlement_issued' =>
        'Ya se emitieron liquidaciones para este pago; no se puede abrir una disputa. Escríbenos por soporte.',
      'dispute_not_releasable' =>
        'El pedido no se ha entregado, así que la disputa no se puede liberar. Usa el reembolso.',
      'proof_upload_missing' =>
        'No encontramos el comprobante cargado. Súbelo de nuevo.',
      'proof_expired' =>
        'La autorización para subir el comprobante venció. Intenta de nuevo.',
      'proof_size_invalid' ||
      'proof_too_large' =>
        'El comprobante pesa más de ${_megabytes(PaymentConfig.proofMaxBytes)} MB. Usa una imagen más liviana.',
      'proof_empty' => 'El archivo está vacío. Elige otra imagen.',
      'proof_image_invalid' ||
      'proof_format_invalid' =>
        'El comprobante debe ser una imagen JPEG, PNG o WebP.',
      'proof_file_unreadable' =>
        'No pudimos leer el archivo. Verifica que exista y elige otra imagen.',
      'storage_upload_failed' =>
        'No pudimos subir la imagen. Tu pago no cambió; intenta de nuevo.',
      'idempotency_conflict' ||
      'invalid_payment_id' =>
        'No pudimos registrar el pago con ese identificador. Intenta de nuevo.',
      'rate_limited' =>
        'Has hecho muchas solicitudes. Espera un momento e intenta de nuevo.',
      'rejection_reason_required' ||
      'dispute_reason_required' ||
      'resolution_note_required' =>
        'Escribe el motivo (máximo 500 caracteres).',
      'invalid_response' =>
        'Recibimos una respuesta inesperada del servidor. Intenta de nuevo.',
      _ => switch (failure.statusCode) {
          401 => 'Tu sesión venció. Inicia sesión de nuevo para continuar.',
          403 => 'Tu cuenta no tiene permiso para esta acción de pago.',
          404 => 'No encontramos el pago.',
          409 => 'El pago cambió de estado. Actualiza e intenta de nuevo.',
          410 => 'La autorización venció. Intenta de nuevo.',
          422 => 'El comprobante no es válido. Revisa la imagen.',
          429 =>
            'Has hecho muchas solicitudes. Espera un momento e intenta de nuevo.',
          >= 500 =>
            'TRACOP no está disponible en este momento. Espera un momento e intenta de nuevo.',
          _ => 'No pudimos completar la acción del pago. Intenta de nuevo.',
        },
    };

/// Si el error requiere recargar el pago antes de reintentar.
bool isPaymentVersionConflict(DomainFailure failure) =>
    failure.code == 'version_conflict';

String _megabytes(int bytes) => '${bytes ~/ (1024 * 1024)}';

/// Errores de liquidaciones: algunos códigos significan otra cosa que en
/// pagos (`invalid_transition`, `not_found`); el resto se comparte.
String settlementErrorText(DomainFailure failure) => switch (failure.code) {
      'invalid_transition' =>
        'La liquidación ya fue pagada o su pago ya no está en liquidación. Actualiza la lista.',
      'invalid_reference' => 'La referencia supera 100 caracteres.',
      'not_found' => 'Liquidación no encontrada.',
      'version_conflict' =>
        'La liquidación cambió mientras la revisabas. Carga la última versión e intenta de nuevo.',
      _ when failure.statusCode == 404 => 'Liquidación no encontrada.',
      _ => paymentErrorText(failure),
    };

import '../../../../core/result/result.dart';

/// Traduce los errores del API de lotes a mensajes accionables en español.
String lotErrorText(DomainFailure failure) => switch (failure.code) {
      'invalid_quantity' =>
        'La cantidad debe ser mayor que cero y tener máximo 3 decimales.',
      'invalid_price' => 'El precio debe ser un entero positivo en pesos.',
      'unit_mismatch' => 'La unidad debe coincidir con la del producto.',
      'invalid_availability' =>
        'La fecha final debe ser igual o posterior a la inicial.',
      'availability_horizon' =>
        'La disponibilidad no puede superar los 90 días desde hoy.',
      'invalid_coordinates' =>
        'Las coordenadas deben estar dentro de Colombia.',
      'invalid_quality' => 'La calidad no puede superar 100 caracteres.',
      'invalid_product' => 'Selecciona un producto válido.',
      'profile_required' =>
        'Completa tu perfil de proveedor antes de publicar el lote.',
      'invalid_transition' =>
        'El estado actual del lote no permite esa acción.',
      'version_conflict' =>
        'El lote cambió en otro dispositivo. Actualiza e intenta de nuevo.',
      'not_found' =>
        'No encontramos tu perfil de proveedor o el producto seleccionado.',
      'forbidden' => 'No tienes permisos para realizar esta acción.',
      'rate_limited' => 'Demasiadas solicitudes. Intenta nuevamente más tarde.',
      'unauthorized' ||
      'invalid_session' =>
        'Tu sesión ya no es válida. Inicia sesión nuevamente.',
      'server_error' =>
        'El servidor no pudo procesar el lote. Intenta nuevamente.',
      'network_error' =>
        'No hay conexión con el servicio. Intenta cuando tengas señal.',
      _ => 'Error ${failure.statusCode} (${failure.code}): ${failure.message}',
    };

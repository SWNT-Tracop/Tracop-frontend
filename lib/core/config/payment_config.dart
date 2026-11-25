/// Datos de pago que el API no expone (ver docs/payments-decisions.md).
///
/// TODO(pagos): reemplazar los valores de ejemplo por los datos reales de la
/// cuenta de TRACOP antes del piloto. Se inyectan en compilación con
/// `--dart-define=PAYMENT_BANK_NAME=...` etc.; nunca se escriben a mano en el
/// código ni se guardan en el dispositivo.
abstract final class PaymentConfig {
  /// Marca usada para detectar que la app sigue con datos de ejemplo.
  static const placeholderMarker = 'PENDIENTE';

  static const bankName = String.fromEnvironment(
    'PAYMENT_BANK_NAME',
    defaultValue: 'PENDIENTE: banco',
  );
  static const bankAccountType = String.fromEnvironment(
    'PAYMENT_BANK_ACCOUNT_TYPE',
    defaultValue: 'PENDIENTE: tipo de cuenta',
  );
  static const bankAccountNumber = String.fromEnvironment(
    'PAYMENT_BANK_ACCOUNT_NUMBER',
    defaultValue: 'PENDIENTE: número de cuenta',
  );
  static const accountHolder = String.fromEnvironment(
    'PAYMENT_ACCOUNT_HOLDER',
    defaultValue: 'PENDIENTE: titular',
  );
  static const accountHolderId = String.fromEnvironment(
    'PAYMENT_ACCOUNT_HOLDER_ID',
    defaultValue: 'PENDIENTE: NIT',
  );
  static const nequiNumber = String.fromEnvironment(
    'PAYMENT_NEQUI_NUMBER',
    defaultValue: 'PENDIENTE: número Nequi',
  );

  /// Tamaño máximo del comprobante. Debe coincidir con
  /// `PAYMENT_PROOF_MAX_BYTES` del backend (5 MB por defecto).
  static const proofMaxBytes = int.fromEnvironment(
    'PAYMENT_PROOF_MAX_BYTES',
    defaultValue: 5 * 1024 * 1024,
  );

  /// Horas tras las cuales un comprobante o disputa se marca como atrasado en
  /// la bandeja de revisión (indicador visual, no regla del servidor).
  static const reviewOverdueHours = int.fromEnvironment(
    'PAYMENT_REVIEW_OVERDUE_HOURS',
    defaultValue: 24,
  );

  /// Cantidad máxima que permite `GET /payments/review` (1..100).
  static const reviewQueueLimit = 100;

  /// Frecuencia de actualización automática de la bandeja de revisión.
  static const reviewAutoRefresh = Duration(seconds: 60);

  /// Activa el botón de pago local de la demo de logística con
  /// `--dart-define=ENABLE_LOCAL_PAYMENT_DEMO=true` (apagado por defecto).
  static const canUseLocalPaymentDemo = bool.fromEnvironment(
    'ENABLE_LOCAL_PAYMENT_DEMO',
    defaultValue: false,
  );

  static bool get hasPlaceholderAccountData => [
        bankName,
        bankAccountType,
        bankAccountNumber,
        accountHolder,
        accountHolderId,
        nequiNumber,
      ].any((value) => value.startsWith(placeholderMarker));
}

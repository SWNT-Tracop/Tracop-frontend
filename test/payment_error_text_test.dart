import 'package:flutter_test/flutter_test.dart';
import 'package:tracop_mobile/core/result/result.dart';
import 'package:tracop_mobile/features/payments/presentation/payment_error_text.dart';

DomainFailure _failure(int status, String code,
        [String message = 'https://storage.example/secret']) =>
    DomainFailure(statusCode: status, code: code, message: message);

void main() {
  test('maps API and client error codes to Spanish messages', () {
    final cases = {
      _failure(503, 'offline'): contains('Sin conexión'),
      _failure(401, 'unauthorized'): contains('sesión venció'),
      _failure(403, 'forbidden'): contains('permiso'),
      _failure(404, 'not_found'): contains('No encontramos el pago'),
      _failure(409, 'version_conflict'): contains('última versión'),
      _failure(409, 'settlement_issued'): contains('liquidaciones'),
      _failure(409, 'reservation_expired'):
          contains('La reserva del pedido venció'),
      _failure(409, 'invalid_transition'): contains('estado actual'),
      _failure(409, 'dispute_not_releasable'): contains('reembolso'),
      _failure(410, 'proof_expired'): contains('venció'),
      _failure(422, 'proof_size_invalid'): contains('5 MB'),
      _failure(422, 'proof_image_invalid'): contains('JPEG, PNG o WebP'),
      _failure(0, 'proof_too_large'): contains('5 MB'),
      _failure(0, 'proof_format_invalid'): contains('JPEG, PNG o WebP'),
      _failure(0, 'proof_file_unreadable'): contains('No pudimos leer'),
      _failure(502, 'storage_upload_failed'): contains('subir la imagen'),
      _failure(503, 'lock_timeout'): contains('no está disponible'),
      _failure(503, 'statement_timeout'): contains('otra operación'),
      _failure(409, 'ledger_already_posted'): contains('libro contable'),
      _failure(400, 'unbalanced_ledger'): contains('no cuadran'),
      _failure(400, 'invalid_ledger_line'): contains('no cuadran'),
      _failure(409, 'carrier_unknown'): contains('transportista'),
      _failure(409, 'something_new'): contains('cambió de estado'),
      _failure(400, 'bad_request'): contains('No pudimos completar'),
    };
    cases.forEach((failure, matcher) {
      expect(paymentErrorText(failure), matcher, reason: failure.code);
    });
  });

  test('never echoes the technical message or URLs', () {
    for (final code in ['unknown', 'http_error', 'storage_upload_failed']) {
      expect(paymentErrorText(_failure(500, code)),
          isNot(contains('storage.example')));
    }
  });

  test('detects version conflicts', () {
    expect(isPaymentVersionConflict(_failure(409, 'version_conflict')), isTrue);
    expect(
        isPaymentVersionConflict(_failure(409, 'settlement_issued')), isFalse);
  });
}

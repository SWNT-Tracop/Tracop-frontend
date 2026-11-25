import 'package:flutter_test/flutter_test.dart';
import 'package:tracop_mobile/core/sync/sync_error_text.dart';

void main() {
  test('translates server failures without exposing technical codes', () {
    final message = syncErrorText('server_error');

    expect(message, contains('servicio'));
    expect(message, isNot(contains('server_error')));
    expect(message, isNot(contains('500')));
  });

  test('translates common synchronization outcomes', () {
    expect(syncErrorText('network_error'), contains('conexión'));
    expect(syncErrorText('rate_limited'), contains('solicitudes'));
 415785   expect(syncErrorText('version_conflict'), contains('versión'));
    expect(syncErrorText('unexpected_failure'), contains('sincronizar'));
  });
}

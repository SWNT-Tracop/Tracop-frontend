import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracop_mobile/core/network/dio_client.dart';
import 'package:tracop_mobile/core/result/result.dart';
import 'package:tracop_mobile/features/payments/data/remote/payment_remote.dart';
import 'package:tracop_mobile/features/payments/data/repository/payment_repository_impl.dart';
import 'package:tracop_mobile/features/payments/domain/entities/payment.dart';

import 'support/payment_fixtures.dart';

const _proof = ProofFile(
  bytes: [0xFF, 0xD8, 0xFF, 0xE0],
  filename: 'comprobante.jpg',
  format: ProofImageFormat.jpeg,
);

DioException _apiError(int status, String code) => DioException(
      requestOptions: RequestOptions(path: '/payments'),
      response: Response(
        requestOptions: RequestOptions(path: '/payments'),
        statusCode: status,
        data: {'statusCode': status, 'code': code, 'message': 'x'},
      ),
      error: DomainFailure(statusCode: status, code: code, message: 'x'),
    );

DioException _storageError(int status, String body) => DioException(
      requestOptions: RequestOptions(
          path: 'https://storage.example/bucket?X-Amz-Signature=secret'),
      response: Response(
        requestOptions: RequestOptions(path: 'https://storage.example/bucket'),
        statusCode: status,
        data: body,
      ),
      message: 'failed https://storage.example/bucket?X-Amz-Signature=secret',
    );

void main() {
  test('initiate sends the client UUID and method wire value', () async {
    final remote = _FakeRemote();
    final repository = PaymentRepositoryImpl(remote: remote);
    final result = await repository.initiate(
        orderId: orderIdFixture,
        paymentId: paymentId,
        method: PaymentMethod.nequi);
    expect(result, isA<Ok<Payment, DomainFailure>>());
    expect(remote.calls, ['initiate']);
    expect(remote.lastBody, {'id': paymentId, 'method': 'nequi'});
  });

  test('getForOrder maps 404 to "no payment yet"', () async {
    final remote = _FakeRemote()
      ..getForOrderError = _apiError(404, 'not_found');
    final result =
        await PaymentRepositoryImpl(remote: remote).getForOrder(orderIdFixture);
    expect((result as Ok<Payment?, DomainFailure>).value, isNull);
  });

  test('staff commands send expectedVersion and trimmed reasons', () async {
    final remote = _FakeRemote();
    final repository = PaymentRepositoryImpl(remote: remote);
    await repository.verify(paymentId, 3);
    expect(remote.lastBody, {'expectedVersion': 3});
    await repository.reject(paymentId, 3, '  Ilegible  ');
    expect(remote.lastBody, {'expectedVersion': 3, 'reason': 'Ilegible'});
    await repository.resolveDispute(
        paymentId, 6, DisputeOutcome.refund, ' Nota ');
    expect(remote.lastBody,
        {'expectedVersion': 6, 'outcome': 'refund', 'note': 'Nota'});
    await repository.dispute(paymentId, 5, ' Llegó incompleto ');
    expect(
        remote.lastBody, {'expectedVersion': 5, 'reason': 'Llegó incompleto'});
  });

  test('version conflicts surface as DomainFailure', () async {
    final remote = _FakeRemote()
      ..commandError = _apiError(409, 'version_conflict');
    final result =
        await PaymentRepositoryImpl(remote: remote).verify(paymentId, 2);
    expect(
        (result as Err<Payment, DomainFailure>).error.code, 'version_conflict');
  });

  group('uploadProof', () {
    test('requests policy, uploads to storage and confirms', () async {
      final remote = _FakeRemote();
      final result = await PaymentRepositoryImpl(remote: remote)
          .uploadProof(paymentId, _proof);
      expect(result, isA<Ok<Payment, DomainFailure>>());
      expect(remote.calls, ['requestProofUpload', 'upload', 'confirmProof']);
      expect(remote.uploadedFields, {'key': 'payment-incoming/1'});
    });

    test('does not pre-check expiresAt with the device clock', () async {
      final remote = _FakeRemote()
        ..policyExpiries = ['2000-01-01T00:00:00.000Z'];
      final result = await PaymentRepositoryImpl(remote: remote)
          .uploadProof(paymentId, _proof);
      expect(result, isA<Ok<Payment, DomainFailure>>());
      expect(remote.calls, ['requestProofUpload', 'upload', 'confirmProof']);
    });

    test('a storage 403 that is not an expiry is a storage failure', () async {
      final remote = _FakeRemote()
        ..uploadErrors = [
          _storageError(403,
              '<Code>AccessDenied</Code><Message>Invalid according to Policy</Message>')
        ];
      final result = await PaymentRepositoryImpl(remote: remote)
          .uploadProof(paymentId, _proof);
      expect((result as Err<Payment, DomainFailure>).error.code,
          'storage_upload_failed');
      expect(remote.calls.where((call) => call == 'requestProofUpload'),
          hasLength(1));
    });

    test('renews once when storage rejects an expired policy (403)', () async {
      final remote = _FakeRemote()
        ..uploadErrors = [
          _storageError(403,
              '<Code>AccessDenied</Code><Message>Request has expired</Message>')
        ];
      final result = await PaymentRepositoryImpl(remote: remote)
          .uploadProof(paymentId, _proof);
      expect(result, isA<Ok<Payment, DomainFailure>>());
      expect(remote.calls.where((call) => call == 'requestProofUpload'),
          hasLength(2));
    });

    test('renews once on 410 proof_expired and gives up the second time',
        () async {
      final remote = _FakeRemote()
        ..confirmErrors = [
          _apiError(410, 'proof_expired'),
          _apiError(410, 'proof_expired'),
        ];
      final result = await PaymentRepositoryImpl(remote: remote)
          .uploadProof(paymentId, _proof);
      expect(
          (result as Err<Payment, DomainFailure>).error.code, 'proof_expired');
      expect(remote.calls, [
        'requestProofUpload',
        'upload',
        'confirmProof',
        'requestProofUpload',
        'upload',
        'confirmProof',
      ]);
    });

    test('storage failures never leak the signed URL', () async {
      final remote = _FakeRemote()
        ..uploadErrors = [_storageError(500, 'InternalError')];
      final result = await PaymentRepositoryImpl(remote: remote)
          .uploadProof(paymentId, _proof);
      final failure = (result as Err<Payment, DomainFailure>).error;
      expect(failure.code, 'storage_upload_failed');
      expect(failure.toString(), isNot(contains('storage.example')));
      expect(failure.toString(), isNot(contains('Signature')));
      expect(remote.calls, isNot(contains('confirmProof')));
    });

    test('a retry after a lost confirm response is treated as success',
        () async {
      // La confirmación anterior llegó al servidor pero su respuesta se
      // perdió: ahora pedir otra política responde 409 invalid_transition.
      final remote = _FakeRemote()
        ..policyErrors = [_apiError(409, 'invalid_transition')]
        ..byIdStatus = 'proof_uploaded';
      final result = await PaymentRepositoryImpl(remote: remote)
          .uploadProof(paymentId, _proof);
      expect((result as Ok<Payment, DomainFailure>).value.status,
          PaymentStatus.proofUploaded);
      expect(remote.calls, ['requestProofUpload', 'getById']);
    });

    for (final status in ['rejected', 'refunded', 'something_new']) {
      test('a 409 then $status is not taken as a registered proof', () async {
        final remote = _FakeRemote()
          ..policyErrors = [_apiError(409, 'invalid_transition')]
          ..byIdStatus = status;
        final result = await PaymentRepositoryImpl(remote: remote)
            .uploadProof(paymentId, _proof);
        expect((result as Err<Payment, DomainFailure>).error.code,
            'invalid_transition');
        expect(remote.calls, ['requestProofUpload', 'getById']);
      });
    }

    test('a 409 on a still pending payment is reported', () async {
      final remote = _FakeRemote()
        ..policyErrors = [_apiError(409, 'invalid_transition')]
        ..byIdStatus = 'pending';
      final result = await PaymentRepositoryImpl(remote: remote)
          .uploadProof(paymentId, _proof);
      expect((result as Err<Payment, DomainFailure>).error.code,
          'invalid_transition');
    });
  });

  test('storage upload uses a client without Authorization, fields first',
      () async {
    final adapter = _RecordingAdapter();
    final api = DioClient(baseUrl: 'https://api.example');
    await api.setAuthToken('api-token');
    final remote = PaymentRemoteDataSourceImpl(api,
        storageClient: () => Dio()..httpClientAdapter = adapter);

    await remote.uploadProofObject(
      url: 'https://storage.example/bucket',
      fields: {
        'key': 'payment-incoming/1',
        'Policy': 'p',
        'X-Amz-Signature': 's'
      },
      filename: 'comprobante.jpg',
      bytes: const [0xFF, 0xD8, 0xFF],
    );

    final request = adapter.requests.single;
    expect(request.headers.keys.map((key) => key.toLowerCase()),
        isNot(contains('authorization')));
    final body = latin1.decode(adapter.bodies.single);
    final file = body.indexOf('name="file"');
    expect(file, greaterThan(body.indexOf('name="key"')));
    expect(file, greaterThan(body.indexOf('name="Policy"')));
    expect(file, greaterThan(body.indexOf('name="X-Amz-Signature"')));
  });
}

class _FakeRemote implements PaymentRemoteDataSource {
  final calls = <String>[];
  Map<String, dynamic>? lastBody;
  Map<String, String>? uploadedFields;
  List<String> policyExpiries = const [];
  List<DioException> uploadErrors = [];
  List<DioException> confirmErrors = [];
  List<DioException> policyErrors = [];
  DioException? getForOrderError;
  DioException? commandError;
  String byIdStatus = 'pending';
  int _policies = 0;

  Map<String, dynamic> _command(String name, Map<String, dynamic> body) {
    calls.add(name);
    lastBody = body;
    if (commandError != null) throw commandError!;
    return paymentJson();
  }

  @override
  Future<Map<String, dynamic>> initiate(
          String orderId, Map<String, dynamic> body) async =>
      _command('initiate', body);

  @override
  Future<Map<String, dynamic>> getForOrder(String orderId) async {
    calls.add('getForOrder');
    if (getForOrderError != null) throw getForOrderError!;
    return paymentJson();
  }

  @override
  Future<Map<String, dynamic>> getById(String paymentId) async {
    calls.add('getById');
    return paymentJson(status: byIdStatus);
  }

  @override
  Future<Map<String, dynamic>> requestProofUpload(String paymentId) async {
    calls.add('requestProofUpload');
    if (policyErrors.isNotEmpty) throw policyErrors.removeAt(0);
    final index = _policies++;
    return {
      'uploadPolicy': {
        'url': 'https://storage.example/bucket',
        'fields': {'key': 'payment-incoming/${index + 1}'},
        'expiresAt': index < policyExpiries.length
            ? policyExpiries[index]
            : '2026-11-24T15:15:00.000Z',
      }
    };
  }

  @override
  Future<void> uploadProofObject({
    required String url,
    required Map<String, String> fields,
    required String filename,
    required List<int> bytes,
  }) async {
    calls.add('upload');
    uploadedFields = fields;
    if (uploadErrors.isNotEmpty) throw uploadErrors.removeAt(0);
  }

  @override
  Future<Map<String, dynamic>> confirmProof(String paymentId) async {
    calls.add('confirmProof');
    if (confirmErrors.isNotEmpty) throw confirmErrors.removeAt(0);
    return paymentJson();
  }

  @override
  Future<Map<String, dynamic>> dispute(
          String paymentId, Map<String, dynamic> body) async =>
      _command('dispute', body);

  @override
  Future<Map<String, dynamic>> reviewQueue(int limit) async => {
        'items': [paymentJson()]
      };

  @override
  Future<Map<String, dynamic>> verify(
          String paymentId, Map<String, dynamic> body) async =>
      _command('verify', body);

  @override
  Future<Map<String, dynamic>> reject(
          String paymentId, Map<String, dynamic> body) async =>
      _command('reject', body);

  @override
  Future<Map<String, dynamic>> resolveDispute(
          String paymentId, Map<String, dynamic> body) async =>
      _command('resolve', body);
}

class _RecordingAdapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  final bodies = <List<int>>[];

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    requests.add(options);
    final bytes = <int>[];
    if (requestStream != null) {
      await for (final chunk in requestStream) {
        bytes.addAll(chunk);
      }
    }
    bodies.add(bytes);
    return ResponseBody.fromString('', 204);
  }

  @override
  void close({bool force = false}) {}
}

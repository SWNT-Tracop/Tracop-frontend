import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracop_mobile/core/i18n/strings.dart';
import 'package:tracop_mobile/core/network/dio_client.dart';
import 'package:tracop_mobile/features/backoffice/data/backoffice_remote.dart';
import 'package:tracop_mobile/features/backoffice/data/backoffice_repository.dart';
import 'package:tracop_mobile/features/backoffice/presentation/accounts_admin_screen.dart';
import 'package:tracop_mobile/features/backoffice/presentation/backoffice_provider.dart';

class _AccountsRemote extends BackofficeRemoteDataSource {
  _AccountsRemote() : super(DioClient(baseUrl: 'http://localhost'));

  Map<String, dynamic> account = {
    'id': '01900000-0000-7000-8000-000000000011',
    'role': 'buyer',
    'status': 'active',
    'fullName': 'Jurado de prueba',
    'phoneLast4': '0011',
  };
  final calls = <String>[];

  @override
  Future<Map<String, dynamic>> findAccount(String phone) async {
    calls.add('find $phone');
    if (phone != '+573000000011') {
      throw DioException(
        requestOptions: RequestOptions(path: '/staff/users'),
        response: Response(
          requestOptions: RequestOptions(path: '/staff/users'),
          statusCode: 404,
          data: {'code': 'not_found'},
        ),
      );
    }
    return account;
  }

  @override
  Future<Map<String, dynamic>> changeAccountRole(
      String userId, String role, String reason) async {
    calls.add('role $role $reason');
    return account = {...account, 'role': role};
  }

  @override
  Future<Map<String, dynamic>> suspendAccount(
      String userId, String reason) async {
    calls.add('suspend $reason');
    return account = {...account, 'status': 'suspended'};
  }
}

Future<_AccountsRemote> _pump(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(390, 1000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final remote = _AccountsRemote();
  await tester.pumpWidget(ProviderScope(
    overrides: [
      backofficeRepositoryProvider
          .overrideWithValue(BackofficeRepository(remote: remote)),
    ],
    child: const MaterialApp(home: Scaffold(body: AccountsAdminScreen())),
  ));
  return remote;
}

Future<void> _reasonAndConfirm(WidgetTester tester, String reason) async {
  await tester.enterText(
      find.widgetWithText(TextField, AccountAdminStrings.reasonLabel), reason);
  await tester.tap(find.text(AccountAdminStrings.confirm));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('finds an account by phone and changes it to producer',
      (tester) async {
    final remote = await _pump(tester);
    await tester.enterText(find.byType(TextField), '300 000 0011');
    await tester.tap(find.text(AccountAdminStrings.search));
    await tester.pumpAndSettle();
    expect(find.text('Jurado de prueba'), findsOneWidget);
    expect(
        find.text('${AccountAdminStrings.phoneEnding} 0011'), findsOneWidget);

    await tester.tap(find.text(AccountAdminStrings.changeRole));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Productor').last);
    await tester.pumpAndSettle();
    await _reasonAndConfirm(tester, 'Prueba del jurado');

    expect(remote.calls,
        ['find +573000000011', 'role producer Prueba del jurado']);
    expect(find.text('${AccountAdminStrings.role}: Productor'), findsOneWidget);
    expect(find.text(AccountAdminStrings.roleChanged), findsOneWidget);
  });

  testWidgets('asks for a reason and suspends the account', (tester) async {
    final remote = await _pump(tester);
    await tester.enterText(find.byType(TextField), '3000000011');
    await tester.tap(find.text(AccountAdminStrings.search));
    await tester.pumpAndSettle();

    await tester.tap(find.text(AccountAdminStrings.suspend));
    await tester.pumpAndSettle();
    await _reasonAndConfirm(tester, 'x');
    expect(find.text(AccountAdminStrings.reasonInvalid), findsOneWidget);
    await _reasonAndConfirm(tester, 'Fin de la prueba');

    expect(remote.calls.last, 'suspend Fin de la prueba');
    expect(
        find.text('${AccountAdminStrings.status}: Suspendida'), findsOneWidget);
    expect(find.text(AccountAdminStrings.reactivate), findsOneWidget);
  });

  testWidgets('says when no account has that phone', (tester) async {
    await _pump(tester);
    await tester.enterText(find.byType(TextField), '3009999999');
    await tester.tap(find.text(AccountAdminStrings.search));
    await tester.pumpAndSettle();
    expect(find.text(AccountAdminStrings.notFound), findsOneWidget);
  });
}

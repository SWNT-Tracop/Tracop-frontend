import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tracop_mobile/app/responsive_shell.dart';
import 'package:tracop_mobile/core/auth/role_access.dart';
import 'package:tracop_mobile/features/auth/domain/entities/user.dart';
import 'package:tracop_mobile/features/home/presentation/home_screen.dart';
import 'package:tracop_mobile/features/notifications/presentation/notifications_provider.dart';

User _user(String role) => User(
      id: 'user-$role',
      role: role,
      fullName: 'Persona $role',
      phone: '+573000000000',
      status: 'active',
      locale: 'es-CO',
    );

Future<void> _pumpShell(WidgetTester tester, String role) async {
  await tester.binding.setSurfaceSize(const Size(390, 844));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final router = GoRouter(initialLocation: '/perfil', routes: [
    ShellRoute(
      builder: (context, state, child) =>
          ResponsiveShell(currentLocation: state.uri.path, child: child),
      routes: [
        GoRoute(path: '/perfil', builder: (_, __) => const Text('perfil')),
      ],
    ),
  ]);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      homeUserProvider.overrideWith((ref) async => _user(role)),
      homeConnectivityProvider.overrideWith((ref) => Stream<bool>.value(true)),
      homeLotsProvider.overrideWith((ref) async => const []),
      notificationsProvider.overrideWith((ref) async => const []),
    ],
    child: MaterialApp.router(routerConfig: router),
  ));
  await tester.pumpAndSettle();
}

List<String> _tabLabels(WidgetTester tester) => tester
    .widgetList<NavigationDestination>(find.byType(NavigationDestination))
    .map((destination) => destination.label)
    .toList();

Future<List<String>> _staffTools(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Más herramientas'));
  await tester.pumpAndSettle();
  return tester
      .widgetList<ListTile>(find.byType(ListTile))
      .map((tile) => tile.title)
      .whereType<Text>()
      .map((text) => text.data ?? '')
      .where((label) => label != 'Más herramientas')
      .toList();
}

void main() {
  test('the staff table mirrors the backend authorization matrix', () {
    expect(RoleAccess.toolsFor('finance'),
        [StaffTool.operations, StaffTool.parameters]);
    expect(RoleAccess.toolsFor('operator'), [
      StaffTool.operations,
      StaffTool.trust,
      StaffTool.catalog,
      StaffTool.proposals,
      StaffTool.logistics,
      StaffTool.parameters,
      StaffTool.pricing,
    ]);
    expect(RoleAccess.toolsFor('admin'), [
      StaffTool.operations,
      StaffTool.trust,
      StaffTool.catalog,
      StaffTool.proposals,
      StaffTool.parameters,
      StaffTool.pricing,
      StaffTool.audit,
    ]);
    expect(RoleAccess.toolsFor('buyer'), isEmpty);
    expect(RoleAccess.canEditParameters('admin'), isTrue);
    expect(RoleAccess.canEditParameters('operator'), isFalse);
    expect(RoleAccess.canEditParameters('finance'), isFalse);
    expect(RoleAccess.hasOwnLots('producer'), isTrue);
    expect(RoleAccess.hasOwnLots('buyer'), isFalse);
  });

  testWidgets('a buyer has no "Mis lotes" tab', (tester) async {
    await _pumpShell(tester, 'buyer');
    expect(_tabLabels(tester), isNot(contains('Mis lotes')));
    expect(_tabLabels(tester), contains('Pedidos'));
  });

  testWidgets('a producer keeps its "Mis lotes" tab', (tester) async {
    await _pumpShell(tester, 'producer');
    expect(_tabLabels(tester), contains('Mis lotes'));
  });

  testWidgets('finance gets four short tabs and only its own tools',
      (tester) async {
    await _pumpShell(tester, 'finance');
    expect(_tabLabels(tester), hasLength(4));
    expect(await _staffTools(tester), ['Operación', 'Parámetros']);
  });

  testWidgets('the operator sees the tools the backend lets it use',
      (tester) async {
    await _pumpShell(tester, 'operator');
    expect(_tabLabels(tester), hasLength(4));
    expect(await _staffTools(tester), [
      'Operación',
      'Confianza',
      'Catálogo',
      'Propuestas',
      'Logística',
      'Parámetros',
      'Precios',
    ]);
  });

  testWidgets('the admin sees the audit but not the logistics desk',
      (tester) async {
    await _pumpShell(tester, 'admin');
    final adminTools = await _staffTools(tester);
    expect(adminTools, contains('Auditoría'));
    expect(adminTools, isNot(contains('Logística')));
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tracop_mobile/app/not_found_screen.dart';
import 'package:tracop_mobile/app/responsive_shell.dart';
import 'package:tracop_mobile/core/i18n/strings.dart';
import 'package:tracop_mobile/features/home/presentation/home_screen.dart';

void main() {
  testWidgets('ruta desconocida muestra pagina de no encontrado',
      (tester) async {
    final router = GoRouter(
      initialLocation: '/no-existe',
      errorBuilder: (context, state) => const NotFoundScreen(),
      routes: [
        GoRoute(path: '/', builder: (_, __) => const Text('inicio')),
      ],
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.text(NotFoundStrings.title), findsOneWidget);
    await tester.tap(find.text(NotFoundStrings.goHome));
    await tester.pumpAndSettle();
    expect(find.text('inicio'), findsOneWidget);
  });

  testWidgets('atras en una seccion vuelve al inicio sin cerrar la app',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final router = GoRouter(
      initialLocation: '/buscar',
      routes: [
        ShellRoute(
          builder: (context, state, child) => ResponsiveShell(
              currentLocation: state.uri.path, child: child),
          routes: [
            GoRoute(path: '/', builder: (_, __) => const Text('inicio')),
            GoRoute(path: '/buscar', builder: (_, __) => const Text('buscar')),
          ],
        ),
      ],
    );
    await tester.pumpWidget(ProviderScope(
      overrides: [
        homeUserProvider.overrideWith((ref) async => null),
        homeConnectivityProvider
            .overrideWith((ref) => Stream<bool>.value(true)),
        homeLotsProvider.overrideWith((ref) async => const []),
      ],
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pumpAndSettle();
    expect(find.text('buscar'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('inicio'), findsOneWidget);
  });
}

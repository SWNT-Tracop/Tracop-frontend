import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tracop_mobile/core/i18n/strings.dart';
import 'package:tracop_mobile/core/result/result.dart';
import 'package:tracop_mobile/features/auth/domain/entities/auth_session.dart';
import 'package:tracop_mobile/features/auth/domain/repository/auth_repository.dart';
import 'package:tracop_mobile/features/auth/presentation/auth_screens.dart';
import 'package:tracop_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:tracop_mobile/features/home/presentation/home_screen.dart'
    show homeConnectivityProvider;

const _botLink = 'https://t.me/tracop_test_bot?start=link';

class _TelegramAuthRepository implements AuthRepository {
  final registered = <RegisterRequest>[];
  final otpRequests = <String>[];

  @override
  Future<String> getDeviceId() async => '10000000-0000-7000-8000-000000000001';

  @override
  Future<Result<RequestOtpResponse, DomainFailure>> register(
      RegisterRequest request) async {
    registered.add(request);
    return const Ok(RequestOtpResponse(message: 'ok', botLink: _botLink));
  }

  @override
  Future<Result<RequestOtpResponse, DomainFailure>> requestOtp(
      RequestOtpRequest request) async {
    otpRequests.add(request.phone);
    return const Ok(RequestOtpResponse(message: 'ok', botLink: _botLink));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<List<Uri>> _pumpFlow(WidgetTester tester, String initialLocation,
    _TelegramAuthRepository repository) async {
  await tester.binding.setSurfaceSize(const Size(390, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final opened = <Uri>[];
  final router = GoRouter(initialLocation: initialLocation, routes: [
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
    GoRoute(
        path: '/otp-verify',
        builder: (_, state) {
          final args = state.extra as OtpRouteArgs;
          return OtpVerifyScreen(phone: args.phone, botLink: args.botLink);
        }),
  ]);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(repository),
      homeConnectivityProvider.overrideWith((ref) => Stream<bool>.value(true)),
      externalLinkOpenerProvider.overrideWithValue((uri) async {
        opened.add(uri);
        return true;
      }),
    ],
    child: MaterialApp.router(routerConfig: router),
  ));
  await tester.pumpAndSettle();
  return opened;
}

void main() {
  testWidgets(
      'registration says the code comes by Telegram and opens the bot from the code screen',
      (tester) async {
    final repository = _TelegramAuthRepository();
    final opened = await _pumpFlow(tester, '/register', repository);

    expect(find.text(TelegramStrings.privacyConsent), findsOneWidget);
    expect(find.textContaining('v0-draft'), findsNothing);

    await tester.enterText(
        find.widgetWithText(TextField, 'Nombre completo'), 'Productora Demo');
    await tester.enterText(
        find.widgetWithText(TextField, 'Celular'), '3001234567');
    await tester.tap(find.text(TelegramStrings.privacyConsent));
    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();

    expect(repository.registered.single.phone, '+573001234567');
    expect(find.text(TelegramStrings.title), findsOneWidget);
    await tester.tap(find.text(TelegramStrings.openBot));
    await tester.pumpAndSettle();
    expect(opened, [Uri.parse(_botLink)]);
  });

  testWidgets('login leads to the Telegram steps and can resend the code',
      (tester) async {
    final repository = _TelegramAuthRepository();
    await _pumpFlow(tester, '/login', repository);

    expect(find.text(TelegramStrings.codeByTelegram), findsOneWidget);
    expect(find.text('Vincular por Telegram'), findsNothing);
    await tester.enterText(find.byType(TextField), '3001234567');
    await tester.tap(find.text('Enviar código'));
    await tester.pumpAndSettle();
    expect(find.text(TelegramStrings.openBot), findsOneWidget);

    await tester.tap(find.text(TelegramStrings.resend));
    await tester.pumpAndSettle();
    expect(repository.otpRequests, ['+573001234567', '+573001234567']);
    expect(find.text(TelegramStrings.resent), findsOneWidget);
  });

  testWidgets('the code screen explains when Telegram cannot be opened',
      (tester) async {
    final repository = _TelegramAuthRepository();
    await tester.binding.setSurfaceSize(const Size(390, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(repository),
        homeConnectivityProvider
            .overrideWith((ref) => Stream<bool>.value(true)),
        externalLinkOpenerProvider.overrideWithValue((uri) async => false),
      ],
      child: const MaterialApp(
          home: OtpVerifyScreen(phone: '+573001234567', botLink: _botLink)),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text(TelegramStrings.openBot));
    await tester.pumpAndSettle();
    expect(find.text(TelegramStrings.cannotOpen), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/i18n/strings.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import './messenger.dart';
import './router.dart';
import './theme.dart';

class TracopApp extends ConsumerStatefulWidget {
  const TracopApp({super.key});

  @override
  ConsumerState<TracopApp> createState() => _TracopAppState();
}

class _TracopAppState extends ConsumerState<TracopApp> {
  @override
  void initState() {
    super.initState();
    authInvalidationSignal.addListener(_onSessionExpired);
  }

  @override
  void dispose() {
    authInvalidationSignal.removeListener(_onSessionExpired);
    super.dispose();
  }

  void _onSessionExpired() =>
      showAppNotice(SessionStrings.expired, icon: Icons.lock_clock_outlined);

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'TRACOP',
      scaffoldMessengerKey: appMessengerKey,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: router,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'CO'),
        Locale('en', 'US'),
      ],
      locale: const Locale('es', 'CO'),
      debugShowCheckedModeBanner: false,
    );
  }
}

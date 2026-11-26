import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/i18n/strings.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../core/sync/sync_provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../features/logistics/presentation/logistics_provider.dart';
import '../features/catalog/presentation/providers/catalog_provider.dart';
import '../features/home/presentation/home_screen.dart'
    show homeConnectivityProvider;
import './messenger.dart';
import './router.dart';
import './theme.dart';

class TracopApp extends ConsumerStatefulWidget {
  const TracopApp({super.key});

  @override
  ConsumerState<TracopApp> createState() => _TracopAppState();
}

class _TracopAppState extends ConsumerState<TracopApp> {
  late final StreamSubscription<List<ConnectivityResult>> _connectivity;
  @override
  void initState() {
    super.initState();
    authInvalidationSignal.addListener(_onSessionExpired);
    _connectivity = Connectivity().onConnectivityChanged.listen((results) {
      ref.invalidate(homeConnectivityProvider);
      if (results.any((result) => result != ConnectivityResult.none)) {
        _sync();
      }
    });
  }

  @override
  void dispose() {
    authInvalidationSignal.removeListener(_onSessionExpired);
    _connectivity.cancel();
    super.dispose();
  }

  void _onSessionExpired() =>
      showAppNotice(SessionStrings.expired, icon: Icons.lock_clock_outlined);

  Future<void> _sync() async {
    final session = ref.read(authProvider).valueOrNull;
    if (session?.accessToken.isEmpty != false) return;
    final userId = session!.user.id;
    try {
      final pushResult =
          await ref.read(syncServiceProvider).pushPending(userId: userId);
      await ref.read(catalogRepositoryProvider).syncPendingLotPhotos();
      final pullResult =
          await ref.read(syncServiceProvider).pullAll(userId: userId);
      await ref.read(logisticsRepositoryProvider).applyRemoteChanges(userId);
      if (pushResult.online && pullResult.online) {
        await ref.read(syncServiceProvider).recordSuccessfulSync(userId);
      }
      ref.read(syncRevisionProvider.notifier).state++;
    } catch (_) {
      // Cached data remains available; the next connectivity event retries.
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authProvider, (previous, next) {
      final wasAuthenticated =
          previous?.valueOrNull?.accessToken.isNotEmpty == true;
      final isAuthenticated = next.valueOrNull?.accessToken.isNotEmpty == true;
      if (!wasAuthenticated && isAuthenticated) _sync();
      final previousUserId = previous?.valueOrNull?.user.id;
      final nextUserId = next.valueOrNull?.user.id;
      if (wasAuthenticated &&
          isAuthenticated &&
          previousUserId != null &&
          nextUserId != null &&
          previousUserId != nextUserId) {
        // A local account switch keeps the app authenticated, so the normal
        // unauthenticated -> authenticated hook is not enough.
        ref.invalidate(homeConnectivityProvider);
        _sync();
      }
    });
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

import 'package:go_router/go_router.dart';
import '../features/home/presentation/home_screen.dart';
import 'package:flutter/material.dart';
import 'not_found_screen.dart';
import 'responsive_shell.dart';
import 'motion.dart';
import 'theme.dart';
import '../features/auth/presentation/auth_screens.dart';
import '../features/auth/presentation/profile_screen.dart';
import '../features/auth/presentation/provider_profile_screen.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../features/catalog/presentation/catalog_search_screen.dart';
import '../features/catalog/domain/entities/lot.dart' hide Category, Product;
import '../features/catalog/presentation/lot_detail_screen.dart';
import '../features/catalog/presentation/lot_form_screen.dart';
import '../features/catalog/presentation/my_lots_screen.dart';
import '../features/ordering/presentation/screens/order_screens.dart';
import '../core/config/env.dart';
import '../core/i18n/strings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/logistics/presentation/logistics_screen.dart';
import '../features/logistics/presentation/logistics_provider.dart'
    show logisticsUserProvider;
import '../features/catalog/presentation/product_proposals_screen.dart';
import '../features/sync_status/presentation/sync_status_screen.dart';

final router = GoRouter(
  initialLocation: '/splash',
  errorBuilder: (context, state) => const NotFoundScreen(),
  routes: [
    GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(
        path: '/register', builder: (context, state) => const RegisterScreen()),
    GoRoute(
        path: '/registro', builder: (context, state) => const RegisterScreen()),
    GoRoute(
        path: '/otp-verify',
        builder: (context, state) => OtpVerifyScreen(
              phone: state.extra as String? ?? '',
              providerSetup:
                  state.uri.queryParameters['providerSetup'] == 'true',
            )),
    ShellRoute(
      builder: (context, state, child) => AuthenticatedShell(
        currentLocation: state.uri.path,
        child: child,
      ),
      routes: [
        GoRoute(
          path: '/',
          pageBuilder: (context, state) => _routePage(
            context,
            state,
            const HomeScreen(),
          ),
        ),
        GoRoute(
          path: '/logistica',
          pageBuilder: (context, state) => _routePage(
            context,
            state,
            const CarrierRoleGate(child: LogisticsScreen()),
          ),
        ),
        GoRoute(
          path: '/sincronizacion',
          pageBuilder: (context, state) => _routePage(
            context,
            state,
            const SyncStatusScreen(),
          ),
        ),
        GoRoute(
          path: '/catalogo/propuestas',
          pageBuilder: (context, state) => _routePage(
            context,
            state,
            const ProductProposalsScreen(),
          ),
        ),
        GoRoute(
          path: '/logistica/viajes/:id',
          pageBuilder: (context, state) => _routePage(
            context,
            state,
            CarrierRoleGate(
              child: TripDetailScreen(tripId: state.pathParameters['id']!),
            ),
          ),
        ),
        GoRoute(
            path: '/buscar',
            pageBuilder: (context, state) => _routePage(
                  context,
                  state,
                  const CatalogSearchScreen(),
                )),
        GoRoute(
            path: '/lotes',
            pageBuilder: (context, state) => _routePage(
                  context,
                  state,
                  const MyLotsScreen(),
                )),
        GoRoute(
            path: '/lotes/nuevo',
            pageBuilder: (context, state) => _routePage(
                  context,
                  state,
                  const LotFormScreen(),
                )),
        GoRoute(
            path: '/lotes/:id/editar',
            pageBuilder: (context, state) => _routePage(
                  context,
                  state,
                  LotFormScreen(lotId: state.pathParameters['id']!),
                )),
        GoRoute(
            path: '/lots/:id',
            pageBuilder: (context, state) => _routePage(
                  context,
                  state,
                  LotDetailScreen(lotId: state.pathParameters['id']!),
                )),
        GoRoute(
            path: '/lotes/:id',
            pageBuilder: (context, state) => _routePage(
                  context,
                  state,
                  LotDetailScreen(lotId: state.pathParameters['id']!),
                )),
        GoRoute(
          path: '/pedidos/nuevo',
          pageBuilder: (context, state) => _orderRoutePage(
            context,
            state,
            OrderRoleGate(
              roles: const {'buyer'},
              child: OrderCheckoutScreen(
                initialLot: state.extra is Lot ? state.extra as Lot : null,
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/pedidos/mis-pedidos',
          pageBuilder: (context, state) => _orderRoutePage(
            context,
            state,
            const OrderRoleGate(roles: {'buyer'}, child: MyOrdersScreen()),
          ),
        ),
        GoRoute(
          path: '/pedidos/entrantes',
          pageBuilder: (context, state) => _orderRoutePage(
            context,
            state,
            const OrderRoleGate(
              roles: {'producer', 'supplier'},
              child: IncomingOrdersScreen(),
            ),
          ),
        ),
        GoRoute(
          path: '/pedidos/:id',
          pageBuilder: (context, state) => _orderRoutePage(
            context,
            state,
            OrderRoleGate(
              roles: const {'buyer', 'producer', 'supplier'},
              child: OrderDetailScreen(orderId: state.pathParameters['id']!),
            ),
          ),
        ),
        GoRoute(
            path: '/perfil',
            pageBuilder: (context, state) =>
                _routePage(context, state, const ProfileScreen())),
        GoRoute(
            path: '/perfil/proveedor',
            pageBuilder: (context, state) => _routePage(
                  context,
                  state,
                  ProviderProfileScreen(
                    onboarding:
                        state.uri.queryParameters['onboarding'] == 'true',
                  ),
                )),
      ],
    ),
  ],
);

class AuthenticatedShell extends ConsumerWidget {
  const AuthenticatedShell(
      {required this.currentLocation, required this.child, super.key});
  final String currentLocation;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final notifier = ref.read(authProvider.notifier);
    if (auth.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (auth.valueOrNull?.accessToken.isNotEmpty != true &&
        !notifier.offlineAuthenticated &&
        !AppConfig.canEnterWithoutSession) {
      return const LoginScreen();
    }
    final bypassSession = AppConfig.canEnterWithoutSession &&
        !notifier.offlineAuthenticated &&
        !notifier.isAuthenticated;
    return ResponsiveShell(
      currentLocation: currentLocation,
      child: bypassSession
          ? Column(
              children: [
                Container(
                  width: double.infinity,
                  color: AppTheme.warningSurface,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: const Text(
                    SessionStrings.testMode,
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(child: child),
              ],
            )
          : child,
    );
  }
}

class CarrierRoleGate extends ConsumerWidget {
  const CarrierRoleGate({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final user = ref.watch(logisticsUserProvider);
    if (auth.isLoading && user == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return user?.role == 'carrier' ? child : const NotFoundScreen();
  }
}

Page<void> _routePage(BuildContext context, GoRouterState state, Widget child) {
  if (MediaQuery.of(context).disableAnimations) {
    return NoTransitionPage<void>(key: state.pageKey, child: child);
  }

  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: AppMotion.fast,
    reverseTransitionDuration: AppMotion.fast,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return AnimatedBuilder(
        animation: Listenable.merge([animation, secondaryAnimation]),
        child: child,
        builder: (context, child) {
          final isPopping = animation.status == AnimationStatus.reverse;
          final isReturning =
              secondaryAnimation.status == AnimationStatus.reverse;

          late final double opacity;
          late final double verticalOffset;

          if (isPopping) {
            // On back navigation, clear the departing page before revealing
            // the page underneath it.
            final exitProgress = (1 - animation.value).clamp(0.0, 1.0);
            opacity = 1 - _transitionInterval(exitProgress, 0, 0.42);
            verticalOffset = 0;
          } else if (isReturning) {
            final enterProgress =
                (1 - secondaryAnimation.value).clamp(0.0, 1.0);
            final entrance = _transitionInterval(enterProgress, 0.42, 1);
            opacity = entrance;
            verticalOffset = 0.018 * (1 - entrance);
          } else if (secondaryAnimation.value > 0) {
            // When navigating forward, the old page fades first.
            final exitProgress =
                _transitionInterval(secondaryAnimation.value, 0, 0.42);
            opacity = 1 - exitProgress;
            verticalOffset = 0;
          } else {
            // Delay the new page until the outgoing page has cleared.
            final entrance = _transitionInterval(animation.value, 0.42, 1);
            opacity = entrance;
            verticalOffset = 0.018 * (1 - entrance);
          }

          return Opacity(
            opacity: opacity,
            child: FractionalTranslation(
              translation: Offset(0, verticalOffset),
              child: child,
            ),
          );
        },
      );
    },
  );
}

Page<void> _orderRoutePage(
    BuildContext context, GoRouterState state, Widget child) {
  if (MediaQuery.of(context).disableAnimations) {
    return NoTransitionPage<void>(key: state.pageKey, child: child);
  }
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: AppMotion.fast,
    reverseTransitionDuration: AppMotion.fast,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved =
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(.08, 0), end: Offset.zero)
              .animate(curved),
          child: child,
        ),
      );
    },
  );
}

double _transitionInterval(double value, double begin, double end) {
  final progress = ((value - begin) / (end - begin)).clamp(0.0, 1.0);
  return Curves.easeOutCubic.transform(progress);
}

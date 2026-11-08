import 'package:go_router/go_router.dart';
import '../features/home/presentation/home_screen.dart';
import 'package:flutter/material.dart';
import 'responsive_shell.dart';
import 'theme.dart';
import '../features/auth/presentation/auth_screens.dart';
import '../features/auth/presentation/profile_screen.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../core/config/env.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final router = GoRouter(
  initialLocation: '/splash',
  errorBuilder: (context, state) => const LoginScreen(),
  routes: [
    GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(
        path: '/register', builder: (context, state) => const RegisterScreen()),
    GoRoute(
        path: '/registro', builder: (context, state) => const RegisterScreen()),
    GoRoute(
        path: '/otp-verify',
        builder: (context, state) =>
            OtpVerifyScreen(phone: state.extra as String? ?? '')),
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
            path: '/buscar',
            pageBuilder: (context, state) => _routePage(
                  context,
                  state,
                  const RoutePlaceholder(title: 'Buscar productos'),
                )),
        GoRoute(
            path: '/lotes',
            pageBuilder: (context, state) => _routePage(
                  context,
                  state,
                  const RoutePlaceholder(title: 'Mis lotes'),
                )),
        GoRoute(
            path: '/lotes/:id',
            pageBuilder: (context, state) => _routePage(
                  context,
                  state,
                  RoutePlaceholder(title: 'Lote ${state.pathParameters['id']}'),
                )),
        GoRoute(
            path: '/perfil',
            pageBuilder: (context, state) =>
                _routePage(context, state, const ProfileScreen())),
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
                  color: const Color(0xFFFFF3CD),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: const Text(
                    'Modo de prueba: entraste sin sesión. Las funciones que requieren el servidor pueden fallar.',
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

Page<void> _routePage(BuildContext context, GoRouterState state, Widget child) {
  if (MediaQuery.of(context).disableAnimations) {
    return NoTransitionPage<void>(key: state.pageKey, child: child);
  }

  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 360),
    reverseTransitionDuration: const Duration(milliseconds: 360),
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

double _transitionInterval(double value, double begin, double end) {
  final progress = ((value - begin) / (end - begin)).clamp(0.0, 1.0);
  return Curves.easeOutCubic.transform(progress);
}

class RoutePlaceholder extends StatelessWidget {
  const RoutePlaceholder({required this.title, super.key});
  final String title;

  @override
  Widget build(BuildContext context) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.agriculture_outlined,
                    size: 48, color: AppTheme.primary),
                const SizedBox(height: 20),
                Text(title, style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 12),
                Text(
                  'Esta sección todavía no está disponible. Puedes volver al inicio.',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: () => context.go('/'),
                  icon: const Icon(Icons.home_outlined),
                  label: const Text('Volver al inicio'),
                ),
              ],
            ),
          ),
        ),
      );
}

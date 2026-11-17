import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/i18n/strings.dart';
import 'theme.dart';

// Pagina para rutas que no existen; antes se mostraba el login.
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.travel_explore_outlined,
                        size: 56, color: AppTheme.primary),
                    const SizedBox(height: 20),
                    Text(NotFoundStrings.title,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 12),
                    Text(NotFoundStrings.body,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge),
                    const SizedBox(height: 28),
                    FilledButton.icon(
                      onPressed: () => context.go('/'),
                      icon: const Icon(Icons.home_outlined),
                      label: const Text(NotFoundStrings.goHome),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

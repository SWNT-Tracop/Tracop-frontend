import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/i18n/strings.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../domain/notification.dart';
import 'notifications_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inbox = ref.watch(notificationsProvider);
    final userId = ref.watch(authProvider).valueOrNull?.user.id;
    return Scaffold(
      appBar: AppBar(title: const Text('Notificaciones')),
      body: inbox.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: FilledButton.icon(
            onPressed: () => ref.invalidate(notificationsProvider),
            icon: const Icon(Icons.refresh),
            label: const Text(CommonStrings.retry),
          ),
        ),
        data: (items) => items.isEmpty
            ? const Center(child: Text('No tienes notificaciones.'))
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(notificationsProvider),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  itemBuilder: (context, index) => _NotificationTile(
                    item: items[index],
                    onRead: () async {
                      if (userId == null) return;
                      await ref
                          .read(notificationsRepositoryProvider)
                          .markRead(userId, items[index]);
                      ref.invalidate(notificationsProvider);
                    },
                  ),
                ),
              ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item, required this.onRead});

  final NotificationEntry item;
  final VoidCallback onRead;

  @override
  Widget build(BuildContext context) => Card(
        color:
            item.readAt == null ? AppTheme.mint.withValues(alpha: .35) : null,
        child: ListTile(
          leading: Icon(item.readAt == null
              ? Icons.notifications_active_outlined
              : Icons.notifications_none_outlined),
          title: Text(item.title),
          subtitle: Text(item.body),
          trailing: item.readAt == null
              ? IconButton(
                  tooltip: 'Marcar como leída',
                  onPressed: onRead,
                  icon: const Icon(Icons.done),
                )
              : null,
        ),
      );
}

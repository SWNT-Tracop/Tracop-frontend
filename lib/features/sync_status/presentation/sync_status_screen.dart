import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/i18n/strings.dart';
import '../../../core/sync/sync_provider.dart';
import '../../../core/sync/sync_error_text.dart';
import '../../../core/sync/sync_service.dart';
import '../../home/presentation/home_screen.dart'
    show homeConnectivityProvider, homeUserProvider;
import '../../catalog/presentation/providers/catalog_provider.dart';
import '../../logistics/presentation/logistics_provider.dart';

final syncOperationsProvider =
    FutureProvider.family<List<SyncOperationInfo>, String>((ref, userId) {
  ref.watch(syncRevisionProvider);
  return ref.read(syncServiceProvider).operations(userId);
});

class SyncStatusScreen extends ConsumerStatefulWidget {
  const SyncStatusScreen({super.key});

  @override
  ConsumerState<SyncStatusScreen> createState() => _SyncStatusScreenState();
}

class _SyncStatusScreenState extends ConsumerState<SyncStatusScreen> {
  bool _syncing = false;

  Future<void> _syncNow(String userId) async {
    if (_syncing) return;
    setState(() => _syncing = true);
    try {
      final service = ref.read(syncServiceProvider);
      final pushResult = await service.pushPending(userId: userId);
      await ref.read(catalogRepositoryProvider).syncPendingLotPhotos();
      final pullResult = await service.pullAll(userId: userId);
      await ref.read(logisticsRepositoryProvider).applyRemoteChanges(userId);
      if (pushResult.online && pullResult.online) {
        await service.recordSuccessfulSync(userId);
      }
      ref.read(syncRevisionProvider.notifier).state++;
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
              SnackBar(content: Text(syncErrorFromException(error))));
      }
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  Future<void> _retry(String userId, String opId) async {
    await ref.read(syncServiceProvider).retryOperation(opId);
    ref.invalidate(syncOperationsProvider(userId));
  }

  Future<void> _discard(String userId, String opId) async {
    await ref.read(syncServiceProvider).discardOperation(opId);
    ref.invalidate(syncOperationsProvider(userId));
  }

  Future<void> _acceptServer(String userId, String opId) async {
    try {
      final service = ref.read(syncServiceProvider);
      await service.discardOperation(opId);
      await service.pullAll(userId: userId);
      await ref.read(logisticsRepositoryProvider).applyRemoteChanges(userId);
      ref.read(syncRevisionProvider.notifier).state++;
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
              SnackBar(content: Text(syncErrorFromException(error))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(homeUserProvider).valueOrNull;
    if (user == null) {
      return const Center(child: Text(SyncStrings.noActiveSession));
    }
    final online = ref.watch(homeConnectivityProvider).valueOrNull;
    final lastSync = ref.watch(lastSuccessfulSyncProvider(user.id)).valueOrNull;
    final catalogError = ref.watch(catalogReadErrorProvider);
    final operations = ref.watch(syncOperationsProvider(user.id));
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(SyncStrings.syncCenter),
        leading: IconButton(
          onPressed: () => context.go('/'),
          icon: const Icon(Icons.arrow_back),
          tooltip: CommonStrings.back,
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => _syncNow(user.id),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            _SyncSummary(
                online: online,
                lastSync: lastSync,
                catalogError: catalogError,
                operations: operations.valueOrNull),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed:
                  online == true && !_syncing ? () => _syncNow(user.id) : null,
              icon: _syncing
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sync),
              label:
                  Text(_syncing ? SyncStrings.syncingNow : SyncStrings.syncNow),
            ),
            const SizedBox(height: 24),
            Text(SyncStrings.operationsTitle,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            operations.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Text(SyncStrings.operationsLoadError),
              data: (items) => items.isEmpty
                  ? const _EmptySyncState()
                  : Column(
                      children: [
                        for (final item in items)
                          _OperationTile(
                            operation: item,
                            onRetry: item.status == 'rejected' ||
                                    item.status == 'conflict'
                                ? () => _retry(user.id, item.opId)
                                : null,
                            onDiscard: item.status == 'rejected' ||
                                    item.status == 'conflict'
                                ? () => _discard(user.id, item.opId)
                                : null,
                            onAcceptServer: item.status == 'conflict'
                                ? () => _acceptServer(user.id, item.opId)
                                : null,
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SyncSummary extends StatelessWidget {
  const _SyncSummary(
      {required this.online,
      required this.lastSync,
      required this.catalogError,
      required this.operations});

  final bool? online;
  final DateTime? lastSync;
  final String? catalogError;
  final List<SyncOperationInfo>? operations;

  @override
  Widget build(BuildContext context) {
    final items = operations ?? const <SyncOperationInfo>[];
    final pending = items.where((item) => item.status == 'pending').length;
    final failed = items
        .where((item) => item.status == 'rejected' || item.status == 'conflict')
        .length;
    final fullySynced = online == true &&
        lastSync != null &&
        pending == 0 &&
        failed == 0 &&
        catalogError == null;
    final color = online == true ? AppTheme.forest : AppTheme.earth;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(
                fullySynced
                    ? Icons.cloud_done_outlined
                    : online == true
                        ? Icons.cloud_queue_outlined
                        : Icons.cloud_off_outlined,
                color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                  fullySynced
                      ? SyncStrings.synced
                      : online == true
                          ? SyncStrings.connectedWithPending
                          : SyncStrings.noInternetConnection,
                  style: Theme.of(context).textTheme.titleMedium),
            ),
          ]),
          const SizedBox(height: 14),
          Text(SyncStrings.pendingSummary(pending)),
          Text(SyncStrings.failedSummary(failed)),
          const SizedBox(height: 8),
          Text(lastSync == null
              ? SyncStrings.neverSynced
              : SyncStrings.lastSynced(lastSync!)),
          if (catalogError != null)
            Text(
                '${SyncStrings.lotsUpdateFailed}: ${syncErrorText(catalogError)}'),
        ]),
      ),
    );
  }
}

class _OperationTile extends StatelessWidget {
  const _OperationTile({
    required this.operation,
    this.onRetry,
    this.onDiscard,
    this.onAcceptServer,
  });

  final SyncOperationInfo operation;
  final VoidCallback? onRetry;
  final VoidCallback? onDiscard;
  final VoidCallback? onAcceptServer;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: Icon(_iconFor(operation.status),
              color: _colorFor(operation.status)),
          title: Text('${operation.entity} · ${operation.type}'),
          subtitle: Text(
              '${_statusLabel(operation.status)}${operation.lastError == null ? '' : '\n${syncErrorText(operation.lastError)}'}'),
          isThreeLine: operation.lastError != null,
          trailing:
              onRetry == null && onDiscard == null && onAcceptServer == null
                  ? null
                  : PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'retry') onRetry?.call();
                        if (value == 'discard') onDiscard?.call();
                        if (value == 'server') onAcceptServer?.call();
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                            value: 'retry',
                            child: Text(SyncStrings.retryOperation)),
                        PopupMenuItem(
                            value: 'discard',
                            child: Text(SyncStrings.discardOperation)),
                        PopupMenuItem(
                            value: 'server',
                            child: Text(SyncStrings.acceptServerVersion)),
                      ],
                    ),
        ),
      );

  IconData _iconFor(String status) => switch (status) {
        'pending' => Icons.schedule,
        'conflict' => Icons.warning_amber_outlined,
        'rejected' => Icons.error_outline,
        _ => Icons.cloud_done_outlined,
      };

  Color _colorFor(String status) => switch (status) {
        'conflict' || 'rejected' => AppTheme.earth,
        'pending' => AppTheme.mutedText,
        _ => AppTheme.forest,
      };

  String _statusLabel(String status) => switch (status) {
        'pending' => SyncStrings.pendingStatus,
        'conflict' => SyncStrings.conflictStatus,
        'rejected' => SyncStrings.rejectedStatus,
        'applied' => SyncStrings.appliedStatus,
        _ => status,
      };
}

class _EmptySyncState extends StatelessWidget {
  const _EmptySyncState();

  @override
  Widget build(BuildContext context) => const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text(SyncStrings.noPendingOperations),
        ),
      );
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/i18n/strings.dart';
import '../../home/presentation/home_screen.dart' show homeConnectivityProvider;
import '../domain/logistics_models.dart';
import 'logistics_provider.dart';

class LogisticsScreen extends ConsumerStatefulWidget {
  const LogisticsScreen({super.key});

  @override
  ConsumerState<LogisticsScreen> createState() => _LogisticsScreenState();
}

class _LogisticsScreenState extends ConsumerState<LogisticsScreen> {
  int _section = 0;
  final Set<String> _selectedOrders = {};
  bool _saving = false;

  Future<void> _refresh() async {
    final userId = ref.read(logisticsUserProvider)?.id;
    if (userId == null) return;
    await ref.read(logisticsRepositoryProvider).syncPending(userId);
    ref.invalidate(logisticsCandidatesProvider(userId));
    ref.invalidate(carrierTripsProvider(userId));
    await Future.wait([
      ref
          .read(logisticsCandidatesProvider(userId).future)
          .then((_) {})
          .catchError((_) {}),
      ref
          .read(carrierTripsProvider(userId).future)
          .then((_) {})
          .catchError((_) {}),
    ]);
  }

  Future<void> _createTrip() async {
    if (_selectedOrders.isEmpty) {
      _notice(LogisticsStrings.selectOrders);
      return;
    }
    setState(() => _saving = true);
    try {
      final isLocal = await ref.read(logisticsRepositoryProvider).createTrip(
          ref.read(logisticsUserProvider)!.id, _selectedOrders.toList());
      if (!mounted) return;
      setState(() {
        _selectedOrders.clear();
        _section = 1;
      });
      final userId = ref.read(logisticsUserProvider)!.id;
      ref.invalidate(carrierTripsProvider(userId));
      ref.invalidate(logisticsCandidatesProvider(userId));
      ref.invalidate(pendingLogisticsOperationsProvider(userId));
      ref.invalidate(failedLogisticsOperationsProvider(userId));
      ref.invalidate(lastLogisticsSyncErrorProvider(userId));
      _notice(isLocal
          ? LogisticsStrings.localTripCreated
          : LogisticsStrings.tripCreated);
    } catch (_) {
      if (mounted) _notice(LogisticsStrings.saveTripError);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _notice(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _syncNow(String userId) async {
    await ref.read(logisticsRepositoryProvider).syncPending(userId);
    if (!mounted) return;
    ref.invalidate(pendingLogisticsOperationsProvider(userId));
    ref.invalidate(failedLogisticsOperationsProvider(userId));
    ref.invalidate(lastLogisticsSyncErrorProvider(userId));
    ref.invalidate(carrierTripsProvider(userId));
    ref.invalidate(logisticsCandidatesProvider(userId));
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(homeConnectivityProvider, (previous, next) {
      if (next.valueOrNull == true && previous?.valueOrNull != true) {
        final userId = ref.read(logisticsUserProvider)?.id;
        if (userId == null) return;
        ref.read(logisticsRepositoryProvider).syncPending(userId).then((_) {
          ref.invalidate(carrierTripsProvider(userId));
          ref.invalidate(logisticsCandidatesProvider(userId));
          ref.invalidate(pendingLogisticsOperationsProvider(userId));
          ref.invalidate(failedLogisticsOperationsProvider(userId));
          ref.invalidate(lastLogisticsSyncErrorProvider(userId));
          ref.invalidate(lastLogisticsSyncErrorProvider(userId));
        });
      }
    });
    final userId = ref.watch(logisticsUserProvider)?.id;
    if (userId == null) return const Center(child: CircularProgressIndicator());
    final candidates = ref.watch(logisticsCandidatesProvider(userId));
    final trips = ref.watch(carrierTripsProvider(userId));
    final pending =
        ref.watch(pendingLogisticsOperationsProvider(userId)).valueOrNull ?? 0;
    final failed =
        ref.watch(failedLogisticsOperationsProvider(userId)).valueOrNull ?? 0;
    final syncError =
        ref.watch(lastLogisticsSyncErrorProvider(userId)).valueOrNull;
    return ColoredBox(
      color: AppTheme.background,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(LogisticsStrings.intro,
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 14),
                _CarrierProfileCard(userId: userId),
                if (pending > 0 || failed > 0) ...[
                  const SizedBox(height: 12),
                  _PendingSyncBanner(
                    count: pending,
                    failed: failed,
                    errorCode: syncError,
                    onRetry: () => _syncNow(userId),
                  ),
                ],
                const SizedBox(height: 16),
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(
                      value: 0,
                      icon: Icon(Icons.inventory_2_outlined),
                      label: Text(LogisticsStrings.candidates),
                    ),
                    ButtonSegment(
                      value: 1,
                      icon: Icon(Icons.local_shipping_outlined),
                      label: Text(LogisticsStrings.trips),
                    ),
                  ],
                  selected: {_section},
                  onSelectionChanged: (selection) =>
                      setState(() => _section = selection.first),
                ),
              ],
            ),
          ),
          Expanded(
            child: _section == 0
                ? candidates.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (_, __) => _LoadState(
                      message: LogisticsStrings.candidatesLoadError,
                      onRetry: () =>
                          ref.invalidate(logisticsCandidatesProvider(userId)),
                    ),
                    data: (items) => _CandidateList(
                      candidates: items,
                      selected: _selectedOrders,
                      onRefresh: _refresh,
                      onToggle: (id, selected) => setState(() {
                        selected
                            ? _selectedOrders.add(id)
                            : _selectedOrders.remove(id);
                      }),
                    ),
                  )
                : trips.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (_, __) => _LoadState(
                      message: LogisticsStrings.tripsLoadError,
                      onRetry: () =>
                          ref.invalidate(carrierTripsProvider(userId)),
                    ),
                    data: (items) =>
                        _TripList(trips: items, onRefresh: _refresh),
                  ),
          ),
          if (_section == 0)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _createTrip,
                    icon: _saving
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.route_outlined),
                    label: Text(_selectedOrders.isEmpty
                        ? LogisticsStrings.createTrip
                        : '${LogisticsStrings.createTrip} · ${_selectedOrders.length}'),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CarrierProfileCard extends ConsumerWidget {
  const _CarrierProfileCard({required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(carrierProfileProvider(userId)).valueOrNull;
    return Card(
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: AppTheme.mint,
          foregroundColor: AppTheme.forest,
          child: Icon(Icons.directions_car_outlined),
        ),
        title: Text(
            profile == null
                ? LogisticsStrings.vehicleSetup
                : profile.vehicleType,
            style: Theme.of(context).textTheme.titleMedium),
        subtitle: Text(profile == null
            ? LogisticsStrings.vehicleSetupHint
            : '${profile.capacityKg} kg · ${profile.plate}'),
        trailing: TextButton(
          onPressed: () => _editProfile(context, ref, profile),
          child: Text(
              profile == null ? LogisticsStrings.complete : CommonStrings.edit),
        ),
      ),
    );
  }

  Future<void> _editProfile(
      BuildContext context, WidgetRef ref, CarrierProfile? current) async {
    // PROVISIONAL list (§23): a free text let people save things like "Aa", which the
    // operator cannot use to plan trips. A saved value outside the list must be picked again.
    var vehicle = LogisticsStrings.vehicleTypes.contains(current?.vehicleType)
        ? current?.vehicleType
        : null;
    final capacity =
        TextEditingController(text: current?.capacityKg.toString() ?? '');
    final plate = TextEditingController(text: current?.plate ?? '');
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(LogisticsStrings.vehicleData),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          StatefulBuilder(
            builder: (context, setDialogState) =>
                DropdownButtonFormField<String>(
              initialValue: vehicle,
              decoration: const InputDecoration(
                  labelText: LogisticsStrings.vehicleType),
              items: [
                for (final type in LogisticsStrings.vehicleTypes)
                  DropdownMenuItem(value: type, child: Text(type)),
              ],
              onChanged: (value) => setDialogState(() => vehicle = value),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: capacity,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
                labelText: LogisticsStrings.vehicleCapacity),
          ),
          TextField(
            controller: plate,
            textCapitalization: TextCapitalization.characters,
            maxLength: 12,
            decoration:
                const InputDecoration(labelText: LogisticsStrings.plate),
          ),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text(CommonStrings.cancel)),
          FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text(CommonStrings.save)),
        ],
      ),
    );
    if (saved == true && context.mounted) {
      final kg = int.tryParse(capacity.text.trim());
      final vehicleType = vehicle;
      if (vehicleType != null &&
          kg != null &&
          kg > 0 &&
          plate.text.trim().length >= 3) {
        try {
          await ref.read(logisticsRepositoryProvider).saveCarrierProfile(
                userId: userId,
                profile: CarrierProfile(
                  vehicleType: vehicleType,
                  capacityKg: kg,
                  plate: plate.text.trim().toUpperCase(),
                ),
              );
          ref.invalidate(carrierProfileProvider(userId));
          ref.invalidate(pendingLogisticsOperationsProvider(userId));
          ref.invalidate(failedLogisticsOperationsProvider(userId));
          ref.invalidate(lastLogisticsSyncErrorProvider(userId));
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text(LogisticsStrings.profileSaved)));
          }
        } catch (_) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text(LogisticsStrings.profileSaveError)));
          }
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text(LogisticsStrings.vehicleValidation)));
        }
      }
    }
    capacity.dispose();
    plate.dispose();
  }
}

class _CandidateList extends StatelessWidget {
  const _CandidateList({
    required this.candidates,
    required this.selected,
    required this.onToggle,
    required this.onRefresh,
  });

  final List<OrderCandidate> candidates;
  final Set<String> selected;
  final void Function(String id, bool value) onToggle;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    if (candidates.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          children: [
            const _EmptyState(
              icon: Icons.inbox_outlined,
              title: LogisticsStrings.noCandidates,
              body: LogisticsStrings.candidatesEmptyHint,
            ),
            Center(
              child: TextButton.icon(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh),
                label: const Text(LogisticsStrings.refreshCandidates),
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: candidates.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final order = candidates[index];
          final isSelected = selected.contains(order.orderId);
          final lineSummary = order.lines
              .map((line) => '${_formatMilli(line.quantityMilli)} ${line.unit}')
              .join(' · ');
          return Card(
            color: isSelected ? AppTheme.mint : AppTheme.white,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppTheme.radiusSurface),
              onTap: () => onToggle(order.orderId, !isSelected),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: isSelected,
                      onChanged: (value) =>
                          onToggle(order.orderId, value ?? false),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              LogisticsStrings.orderShort(
                                  _shortId(order.orderId)),
                              style: Theme.of(context).textTheme.titleMedium),
                          if (order.isLocalPayment)
                            const Text(LogisticsStrings.locallyPaidStatus),
                          const SizedBox(height: 8),
                          _LocationLine(
                            icon: Icons.trip_origin,
                            label:
                                '${LogisticsStrings.pickupAt} ${order.pickupZones.join(', ')}',
                          ),
                          const SizedBox(height: 4),
                          _LocationLine(
                            icon: Icons.place_outlined,
                            label:
                                '${LogisticsStrings.deliveryAt} ${order.deliveryZone}',
                          ),
                          if (lineSummary.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(lineSummary,
                                style: Theme.of(context).textTheme.bodySmall),
                          ],
                          if (order.deliveryWindow != null) ...[
                            const SizedBox(height: 4),
                            Text(
                                LogisticsStrings.deliveryWindow(
                                    _dateLabel(order.deliveryWindow!)),
                                style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TripList extends StatelessWidget {
  const _TripList({required this.trips, required this.onRefresh});
  final List<CarrierTrip> trips;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    if (trips.isEmpty) {
      return const _EmptyState(
        icon: Icons.local_shipping_outlined,
        title: LogisticsStrings.noTrips,
        body: LogisticsStrings.tripsEmptyHint,
      );
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: trips.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final trip = trips[index];
          return Card(
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              leading: const CircleAvatar(
                backgroundColor: AppTheme.mint,
                foregroundColor: AppTheme.forest,
                child: Icon(Icons.local_shipping_outlined),
              ),
              title: Text(LogisticsStrings.tripShort(_shortId(trip.id)),
                  style: Theme.of(context).textTheme.titleMedium),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                    '${LogisticsStrings.tripStatus(trip.status)} · ${_dateLabel(trip.plannedAt)}'),
              ),
              trailing: trip.status == 'sync_pending'
                  ? const Icon(Icons.cloud_upload_outlined)
                  : const Icon(Icons.chevron_right),
              onTap: trip.status == 'sync_pending'
                  ? null
                  : () => context.go('/logistica/viajes/${trip.id}'),
            ),
          );
        },
      ),
    );
  }
}

class TripDetailScreen extends ConsumerWidget {
  const TripDetailScreen({required this.tripId, super.key});
  final String tripId;

  Future<void> _perform(
    BuildContext context,
    WidgetRef ref,
    Future<void> Function() action,
    String success,
  ) async {
    try {
      final userId = ref.read(logisticsUserProvider)?.id;
      if (userId == null) return;
      await action();
      ref.invalidate(carrierTripsProvider(userId));
      ref.invalidate(tripStopsProvider((userId, tripId)));
      ref.invalidate(pendingLogisticsOperationsProvider(userId));
      ref.invalidate(failedLogisticsOperationsProvider(userId));
      ref.invalidate(lastLogisticsSyncErrorProvider(userId));
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(success)));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(LogisticsStrings.saveActionError)));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(logisticsUserProvider)?.id;
    if (userId == null) return const Center(child: CircularProgressIndicator());
    final tripAsync = ref.watch(carrierTripsProvider(userId));
    final stopsAsync = ref.watch(tripStopsProvider((userId, tripId)));
    return tripAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) =>
          const _LoadState(message: LogisticsStrings.tripsLoadError),
      data: (trips) {
        final trip = trips.where((item) => item.id == tripId).firstOrNull;
        if (trip == null) {
          return const _EmptyState(
            icon: Icons.route_outlined,
            title: LogisticsStrings.tripUnavailable,
            body: LogisticsStrings.refreshTripsHint,
          );
        }
        return ColoredBox(
          color: AppTheme.background,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: LogisticsStrings.backToLogistics,
                      onPressed: () => context.go('/logistica'),
                      icon: const Icon(Icons.arrow_back),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(LogisticsStrings.tripShort(_shortId(trip.id)),
                              style: Theme.of(context).textTheme.titleLarge),
                          Text(LogisticsStrings.tripStatus(trip.status)),
                          if (trip.isLocalOnly)
                            const Text(LogisticsStrings.localTripNotice),
                        ],
                      ),
                    ),
                    if (trip.status == 'assigned')
                      FilledButton(
                        onPressed: () => _perform(
                          context,
                          ref,
                          () => ref
                              .read(logisticsRepositoryProvider)
                              .startTrip(userId, trip),
                          trip.isLocalOnly
                              ? LogisticsStrings.localActionSaved
                              : LogisticsStrings.tripStartSaved,
                        ),
                        child: const Text(LogisticsStrings.startTrip),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: stopsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const _LoadState(
                      message: LogisticsStrings.stopsLoadError),
                  data: (stops) => _StopsList(
                    stops: stops,
                    trip: trip,
                    onCheckIn: (stop) => _perform(
                      context,
                      ref,
                      () => ref.read(logisticsRepositoryProvider).checkIn(
                            userId: userId,
                            stop: stop,
                            kind: stop.kind,
                            baseVersion: trip.version,
                          ),
                      trip.isLocalOnly
                          ? LogisticsStrings.localActionSaved
                          : LogisticsStrings.checkinSaved,
                    ),
                    onIncident: (stop) =>
                        _showIncidentDialog(context, ref, userId, stop),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showIncidentDialog(
      BuildContext context, WidgetRef ref, String userId, TripStop stop) async {
    final description = TextEditingController();
    String type = 'retraso';
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text(LogisticsStrings.reportIncident),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: type,
                decoration: const InputDecoration(
                    labelText: LogisticsStrings.incidentType),
                items: const [
                  DropdownMenuItem(
                      value: 'retraso', child: Text(LogisticsStrings.delay)),
                  DropdownMenuItem(
                      value: 'producto',
                      child: Text(LogisticsStrings.cargoIssue)),
                  DropdownMenuItem(
                      value: 'otro', child: Text(LogisticsStrings.other)),
                ],
                onChanged: (value) => setState(() => type = value ?? 'otro'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: description,
                minLines: 2,
                maxLines: 4,
                maxLength: 1000,
                decoration: const InputDecoration(
                    labelText: LogisticsStrings.incidentDescription),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text(CommonStrings.cancel)),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text(CommonStrings.save),
            ),
          ],
        ),
      ),
    );
    if (saved != true || description.text.trim().isEmpty || !context.mounted) {
      return;
    }
    final isLocalTrip =
        (await ref.read(logisticsRepositoryProvider).getTrips(userId))
            .any((trip) => trip.isLocalOnly && trip.id == tripId);
    try {
      await ref.read(logisticsRepositoryProvider).openIncident(
            userId: userId,
            tripId: tripId,
            orderId: stop.orderId,
            type: type,
            description: description.text.trim(),
          );
      ref.invalidate(pendingLogisticsOperationsProvider(userId));
      ref.invalidate(failedLogisticsOperationsProvider(userId));
      ref.invalidate(lastLogisticsSyncErrorProvider(userId));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(isLocalTrip
                ? LogisticsStrings.localActionSaved
                : LogisticsStrings.incidentSaved)));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(LogisticsStrings.incidentSaveError)));
      }
    } finally {
      description.dispose();
    }
  }
}

class _StopsList extends StatelessWidget {
  const _StopsList({
    required this.stops,
    required this.trip,
    required this.onCheckIn,
    required this.onIncident,
  });
  final List<TripStop> stops;
  final CarrierTrip trip;
  final ValueChanged<TripStop> onCheckIn;
  final ValueChanged<TripStop> onIncident;

  @override
  Widget build(BuildContext context) {
    if (stops.isEmpty) {
      return const _EmptyState(
          icon: Icons.route_outlined,
          title: LogisticsStrings.noStops,
          body: LogisticsStrings.noStopsHint);
    }
    final pickedUpOrders = stops
        .where((stop) => stop.kind == 'pickup' && stop.completedAt != null)
        .map((stop) => stop.orderId)
        .toSet();
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      itemCount: stops.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final stop = stops[index];
        final done = stop.completedAt != null;
        final canCheckIn =
            stop.kind == 'pickup' || pickedUpOrders.contains(stop.orderId);
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  CircleAvatar(
                    backgroundColor:
                        done ? AppTheme.mint : AppTheme.neutralSurface,
                    foregroundColor:
                        done ? AppTheme.forest : AppTheme.mutedText,
                    child: Text('${stop.sequence}'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            stop.kind == 'pickup'
                                ? LogisticsStrings.pickup
                                : LogisticsStrings.delivery,
                            style: Theme.of(context).textTheme.titleMedium),
                        Text(stop.zone),
                      ],
                    ),
                  ),
                  if (done)
                    const Icon(Icons.check_circle, color: AppTheme.forest),
                ]),
                const SizedBox(height: 8),
                Text('${LogisticsStrings.order} ${_shortId(stop.orderId)}'),
                if (!done && trip.status == 'in_progress' && canCheckIn) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.tonalIcon(
                        onPressed: () => onCheckIn(stop),
                        icon: const Icon(Icons.check, size: 18),
                        label: Text(stop.kind == 'pickup'
                            ? LogisticsStrings.checkinPickup
                            : LogisticsStrings.checkinDelivery),
                      ),
                      TextButton.icon(
                        onPressed: () => onIncident(stop),
                        icon: const Icon(Icons.flag_outlined, size: 18),
                        label: const Text(LogisticsStrings.reportIncident),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PendingSyncBanner extends StatelessWidget {
  const _PendingSyncBanner({
    required this.count,
    required this.failed,
    required this.errorCode,
    required this.onRetry,
  });
  final int count;
  final int failed;
  final String? errorCode;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: AppTheme.warningSurface,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          const Icon(Icons.cloud_upload_outlined, color: AppTheme.warningIcon),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(failed > 0
                    ? '$failed ${LogisticsStrings.failedOperations}'
                    : LogisticsStrings.pendingSyncCount(count)),
                if (errorCode != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    failed > 0
                        ? LogisticsStrings.syncNotAccepted
                        : LogisticsStrings.syncCouldNotSend,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ] else if (count > 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    LogisticsStrings.pendingSavedLocally,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
          if (count > 0)
            IconButton(
              tooltip: LogisticsStrings.retrySync,
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              visualDensity: VisualDensity.compact,
            ),
        ]),
      );
}

class _LocationLine extends StatelessWidget {
  const _LocationLine({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, size: 16, color: AppTheme.carrierAccent),
        const SizedBox(width: 6),
        Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
      ]);
}

class _EmptyState extends StatelessWidget {
  const _EmptyState(
      {required this.icon, required this.title, required this.body});
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 42, color: AppTheme.carrierAccent),
            const SizedBox(height: 16),
            Text(title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(body, textAlign: TextAlign.center),
          ]),
        ),
      );
}

class _LoadState extends StatelessWidget {
  const _LoadState({required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(message),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text(CommonStrings.retry),
            ),
          ],
        ]),
      );
}

String _shortId(String id) =>
    id.length > 8 ? id.substring(0, 8).toUpperCase() : id;

String _formatMilli(String value) {
  final amount = int.tryParse(value) ?? 0;
  final whole = amount ~/ 1000;
  final fraction = amount % 1000;
  if (fraction == 0) return '$whole';
  final decimals =
      fraction.toString().padLeft(3, '0').replaceFirst(RegExp(r'0+$'), '');
  return '$whole,$decimals';
}

String _dateLabel(DateTime date) {
  final local = date.toLocal();
  final d = local.day.toString().padLeft(2, '0');
  final m = local.month.toString().padLeft(2, '0');
  return '$d/$m/${local.year}';
}

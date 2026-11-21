import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/domain/entities/user.dart';
import '../../home/presentation/home_screen.dart' show homeUserProvider;
import '../data/logistics_repository.dart';
import '../domain/logistics_models.dart';

final logisticsRepositoryProvider = Provider<LogisticsRepository>((ref) {
  throw UnimplementedError('LogisticsRepository requires app database setup.');
});

final logisticsUserProvider =
    Provider<User?>((ref) => ref.watch(homeUserProvider).valueOrNull);

final logisticsCandidatesProvider =
    FutureProvider.family<List<OrderCandidate>, String>((ref, userId) =>
        ref.read(logisticsRepositoryProvider).getCandidates(userId));

final carrierProfileProvider = FutureProvider.family<CarrierProfile?, String>(
    (ref, userId) =>
        ref.read(logisticsRepositoryProvider).getCarrierProfile(userId));

final carrierTripsProvider = FutureProvider.family<List<CarrierTrip>, String>(
    (ref, userId) => ref.read(logisticsRepositoryProvider).getTrips(userId));

final tripStopsProvider =
    FutureProvider.family<List<TripStop>, (String, String)>((ref, params) =>
        ref.read(logisticsRepositoryProvider).getStops(params.$1, params.$2));

final pendingLogisticsOperationsProvider = FutureProvider.family<int, String>(
    (ref, userId) =>
        ref.read(logisticsRepositoryProvider).pendingCount(userId));

final failedLogisticsOperationsProvider = FutureProvider.family<int, String>(
    (ref, userId) => ref.read(logisticsRepositoryProvider).failedCount(userId));

final lastLogisticsSyncErrorProvider = FutureProvider.family<String?, String>(
    (ref, userId) =>
        ref.read(logisticsRepositoryProvider).lastSyncError(userId));

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/providers/auth_provider.dart';
import '../data/recommendations_repository.dart';

final recommendationsRepositoryProvider = Provider<RecommendationsRepository>(
    (ref) => throw UnimplementedError('Recommendations requires app setup.'));

final recommendedLotsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  ref.watch(authProvider);
  final repository = ref.read(recommendationsRepositoryProvider);
  final result = await repository.guard(repository.remote.recommendedLots);
  return result.map(
      ok: (value) => value.value, err: (failure) => throw failure.error);
});

final priceAlertsProvider =
    FutureProvider.autoDispose<List<dynamic>>((ref) async {
  ref.watch(authProvider);
  final repository = ref.read(recommendationsRepositoryProvider);
  final result = await repository.guard(
      () async => (await repository.remote.alerts())['items'] as List<dynamic>);
  return result.map(
      ok: (value) => value.value, err: (failure) => throw failure.error);
});

final pricingMappingsProvider =
    FutureProvider.autoDispose<List<dynamic>>((ref) async {
  ref.watch(authProvider);
  final repository = ref.read(recommendationsRepositoryProvider);
  final result = await repository.guard(() async =>
      (await repository.remote.mappings())['items'] as List<dynamic>);
  return result.map(
      ok: (value) => value.value, err: (failure) => throw failure.error);
});

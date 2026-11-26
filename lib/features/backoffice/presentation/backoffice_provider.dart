import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/providers/auth_provider.dart';
import '../data/backoffice_repository.dart';

final backofficeRepositoryProvider = Provider<BackofficeRepository>(
    (ref) => throw UnimplementedError('Backoffice requires app setup.'));

final backofficeMetricsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  ref.watch(authProvider);
  final result = await ref
      .read(backofficeRepositoryProvider)
      .guard(() => ref.read(backofficeRepositoryProvider).remote.metrics());
  return result.map(
      ok: (value) => value.value, err: (failure) => throw failure.error);
});

final backofficeParametersProvider =
    FutureProvider.autoDispose<List<dynamic>>((ref) async {
  ref.watch(authProvider);
  final result = await ref.read(backofficeRepositoryProvider).guard(() async =>
      (await ref
          .read(backofficeRepositoryProvider)
          .remote
          .parameters())['items'] as List<dynamic>);
  return result.map(
      ok: (value) => value.value, err: (failure) => throw failure.error);
});

final backofficeVerificationsProvider =
    FutureProvider.autoDispose<List<dynamic>>((ref) async {
  ref.watch(authProvider);
  final result = await ref.read(backofficeRepositoryProvider).guard(() async =>
      (await ref
          .read(backofficeRepositoryProvider)
          .remote
          .verifications())['items'] as List<dynamic>);
  return result.map(
      ok: (value) => value.value, err: (failure) => throw failure.error);
});

final backofficeProposalsProvider =
    FutureProvider.autoDispose<List<dynamic>>((ref) async {
  ref.watch(authProvider);
  final result = await ref.read(backofficeRepositoryProvider).guard(() async =>
      await ref.read(backofficeRepositoryProvider).remote.proposals());
  return result.map(
      ok: (value) => value.value, err: (failure) => throw failure.error);
});

final backofficeCategoriesProvider =
    FutureProvider.autoDispose<List<dynamic>>((ref) async {
  ref.watch(authProvider);
  final repository = ref.read(backofficeRepositoryProvider);
  final result = await repository.guard(repository.remote.categories);
  return result.map(
      ok: (value) => value.value, err: (failure) => throw failure.error);
});

final backofficeProductsProvider =
    FutureProvider.autoDispose<List<dynamic>>((ref) async {
  ref.watch(authProvider);
  final repository = ref.read(backofficeRepositoryProvider);
  final result = await repository.guard(repository.remote.products);
  return result.map(
      ok: (value) => value.value, err: (failure) => throw failure.error);
});

final backofficeAuditProvider =
    FutureProvider.autoDispose<List<dynamic>>((ref) async {
  ref.watch(authProvider);
  final result = await ref.read(backofficeRepositoryProvider).guard(() async =>
      (await ref
          .read(backofficeRepositoryProvider)
          .remote
          .audit({'limit': 50}))['items'] as List<dynamic>);
  return result.map(
      ok: (value) => value.value, err: (failure) => throw failure.error);
});

final backofficeLogisticsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  ref.watch(authProvider);
  final repository = ref.read(backofficeRepositoryProvider);
  final result = await repository.guard(() async {
    final values = await Future.wait([
      repository.remote.carriers(),
      repository.remote.trips(),
      repository.remote.conflicts(),
      repository.remote.incidents(),
    ]);
    return {
      'carriers': values[0],
      'trips': values[1],
      'conflicts': values[2],
      'incidents': values[3],
    };
  });
  return result.map(
      ok: (value) => value.value, err: (failure) => throw failure.error);
});

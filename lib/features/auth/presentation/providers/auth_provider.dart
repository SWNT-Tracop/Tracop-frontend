import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/entities/user.dart';
import '../../domain/repository/auth_repository.dart';
import '../../../../core/result/result.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  throw UnimplementedError(
      'AuthRepository requires DioClient and AppDatabase setup.');
});

final authInvalidationSignal = ValueNotifier<int>(0);

final authProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<AuthSession?>>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return AuthNotifier(repo);
});

class AuthNotifier extends StateNotifier<AsyncValue<AuthSession?>> {
  final AuthRepository _repo;

  AuthNotifier(this._repo) : super(const AsyncValue.data(null)) {
    authInvalidationSignal.addListener(_handleInvalidation);
  }

  void _startConnectivityMonitor() {
    if (_connectivitySubscription != null) return;
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((results) {
      final online = results.any((result) => result != ConnectivityResult.none);
      if (online && offlineAuthenticated) refresh();
    });
  }

  bool offlineAuthenticated = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  void _handleInvalidation() {
    offlineAuthenticated = false;
    state = const AsyncValue.data(null);
  }

  bool get isAuthenticated => state.valueOrNull?.accessToken.isNotEmpty == true;

  Future<String> getDeviceId() => _repo.getDeviceId();

  Future<void> register(RegisterRequest request) async {
    state = const AsyncValue.loading();
    final result = await _repo.register(request);
    state = result.map(
      ok: (_) => const AsyncValue.data(null),
      err: (err) => AsyncValue.error(err.error, StackTrace.current),
    );
  }

  Future<void> loginOtp(RequestOtpRequest request) async {
    state = const AsyncValue.loading();
    final result = await _repo.requestOtp(request);
    state = result.map(
      ok: (_) => const AsyncValue.data(null),
      err: (err) => AsyncValue.error(err.error, StackTrace.current),
    );
  }

  Future<void> verifyOtp(VerifyOtpRequest request) async {
    state = const AsyncValue.loading();
    final result = await _repo.verifyOtp(request);
    state = result.map(
      ok: (ok) {
        offlineAuthenticated = false;
        return AsyncValue.data(ok.value);
      },
      err: (err) => AsyncValue.error(err.error, StackTrace.current),
    );
  }

  Future<void> refresh() async {
    final stored = await _repo.getStoredRefreshToken();
    final refreshToken =
        stored.map(ok: (value) => value.value, err: (_) => null);
    if (refreshToken == null) return;
    final result = await _repo.refreshSession(RefreshSessionRequest(
      refreshToken: refreshToken,
      deviceId: await _repo.getDeviceId(),
    ));
    if (result is Ok<AuthSession, DomainFailure>) {
      offlineAuthenticated = false;
      state = AsyncValue.data(result.value);
    } else {
      final failure = (result as Err<AuthSession, DomainFailure>).error;
      if (failure.statusCode == 401 || failure.code == 'invalid_session') {
        await invalidateSession();
      }
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    await _repo.clearSession();
    state = const AsyncValue.data(null);
    offlineAuthenticated = false;
  }

  Future<bool> restoreSession() async {
    _startConnectivityMonitor();
    state = const AsyncValue.loading();
    final stored = await _repo.getStoredRefreshToken();
    final refreshToken =
        stored.map(ok: (value) => value.value, err: (_) => null);
    if (refreshToken == null) {
      offlineAuthenticated = false;
      state = const AsyncValue.data(null);
      return false;
    }
    final cached = await _repo.getStoredUser();
    final cachedUser = cached.map(ok: (value) => value.value, err: (_) => null);
    final network = await Connectivity().checkConnectivity();
    if (!network.any((result) => result != ConnectivityResult.none) &&
        cachedUser != null) {
      offlineAuthenticated = true;
      state = const AsyncValue.data(null);
      return true;
    }
    final result = await _repo.refreshSession(RefreshSessionRequest(
      refreshToken: refreshToken,
      deviceId: await _repo.getDeviceId(),
    ));
    if (result is Ok<AuthSession, DomainFailure>) {
      offlineAuthenticated = false;
      state = AsyncValue.data(result.value);
      return true;
    }
    final failure = (result as Err<AuthSession, DomainFailure>).error;
    if (failure.statusCode == 401 || failure.code == 'invalid_session') {
      await _repo.clearSession();
      offlineAuthenticated = false;
      state = const AsyncValue.data(null);
      return false;
    }
    offlineAuthenticated = cachedUser != null;
    state = const AsyncValue.data(null);
    return offlineAuthenticated;
  }

  Future<void> refreshProfile() async {
    final result = await _repo.getMe();
    if (result is Err<User, DomainFailure> &&
        result.error.code == 'invalid_session') {
      await _repo.clearSession();
      _handleInvalidation();
    }
  }

  Future<void> invalidateSession() async {
    await _repo.clearSession();
    offlineAuthenticated = false;
    state = const AsyncValue.data(null);
  }

  Future<void> updateProfile(UpdateMeRequest request) async {
    final result = await _repo.updateMe(request);
    if (result is Err<User, DomainFailure> &&
        result.error.code == 'invalid_session') {
      await _repo.clearSession();
      _handleInvalidation();
    }
  }

  @override
  void dispose() {
    authInvalidationSignal.removeListener(_handleInvalidation);
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  Future<User?> getStoredUser() async {
    final result = await _repo.getStoredUser();
    return result.map(ok: (ok) => ok.value, err: (_) => null);
  }
}

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/result/result.dart';
import '../../../../core/storage/app_database.dart' hide User;
import '../remote/auth_remote.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/entities/user.dart';
import '../../domain/entities/saved_account.dart';
import '../../domain/repository/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository, LocalAccountRepository {
  final AuthRemoteDataSource remote;
  final AppDatabase db;
  final FlutterSecureStorage secureStorage;
  Future<Result<AuthSession, DomainFailure>>? _refreshInFlight;
  String? _pendingDeviceId;

  static const _accountsKey = 'localAccountsV1';
  static const _activeAccountKey = 'activeLocalAccountId';
  static const _legacyRefreshKey = 'refreshToken';
  static const _legacyDeviceKey = 'deviceId';

  AuthRepositoryImpl(
      {required this.remote, required this.db, required this.secureStorage});

  @override
  Future<Result<void, DomainFailure>> register(RegisterRequest request) async {
    try {
      await remote.register(request.toJson());
      return const Ok(null);
    } on DomainFailure catch (e) {
      return Err(e);
    } on DioException catch (e) {
      return Err(_networkFailure(e));
    } catch (e) {
      return Err(DomainFailure(
          statusCode: 500, code: 'unknown', message: e.toString()));
    }
  }

  @override
  Future<Result<RequestOtpResponse, DomainFailure>> requestOtp(
      RequestOtpRequest request) async {
    try {
      final json = await remote.requestOtp(request.toJson());
      return Ok(RequestOtpResponse.fromJson(json));
    } on DomainFailure catch (e) {
      return Err(e);
    } on DioException catch (e) {
      return Err(_networkFailure(e));
    } catch (e) {
      return Err(DomainFailure(
          statusCode: 500, code: 'unknown', message: e.toString()));
    }
  }

  @override
  Future<Result<AuthSession, DomainFailure>> verifyOtp(
      VerifyOtpRequest request) async {
    try {
      final json = await remote.verifyOtp(request.toJson());
      final session = AuthSession.fromJson(json);
      await saveSession(session);
      await _storeUser(session.user);
      return Ok(session);
    } on DomainFailure catch (e) {
      return Err(e);
    } on DioException catch (e) {
      return Err(_networkFailure(e));
    } catch (e) {
      return Err(DomainFailure(
          statusCode: 500, code: 'unknown', message: e.toString()));
    }
  }

  @override
  Future<Result<AuthSession, DomainFailure>> refreshSession(
      RefreshSessionRequest request) {
    return _refreshInFlight ??= _refreshSession(request).whenComplete(() {
      _refreshInFlight = null;
    });
  }

  Future<Result<AuthSession, DomainFailure>> _refreshSession(
      RefreshSessionRequest request) async {
    try {
      final json = await remote.refreshSession(request.toJson());
      final session = AuthSession.fromJson(json);
      await saveSession(session);
      await _storeUser(session.user);
      return Ok(session);
    } on DomainFailure catch (e) {
      return Err(e);
    } on DioException catch (e) {
      return Err(_networkFailure(e));
    } catch (e) {
      return Err(DomainFailure(
          statusCode: 500, code: 'unknown', message: e.toString()));
    }
  }

  @override
  Future<Result<void, DomainFailure>> logout() async {
    try {
      await remote.logout();
      return const Ok(null);
    } on DomainFailure catch (e) {
      return Err(e);
    } on DioException catch (e) {
      return Err(_networkFailure(e));
    } catch (e) {
      return Err(DomainFailure(
          statusCode: 500, code: 'unknown', message: e.toString()));
    }
  }

  @override
  Future<Result<User, DomainFailure>> getMe() async {
    try {
      final json = await remote.getMe();
      final user = User.fromJson(json);
      await _storeUser(user);
      return Ok(user);
    } on DomainFailure catch (e) {
      return Err(e);
    } on DioException catch (e) {
      return Err(_networkFailure(e));
    } catch (e) {
      return Err(DomainFailure(
          statusCode: 500, code: 'unknown', message: e.toString()));
    }
  }

  @override
  Future<Result<User, DomainFailure>> updateMe(UpdateMeRequest request) async {
    try {
      final json = await remote.updateMe(request.toJson());
      final user = User.fromJson(json);
      await _storeUser(user);
      return Ok(user);
    } on DomainFailure catch (e) {
      return Err(e);
    } on DioException catch (e) {
      return Err(_networkFailure(e));
    } catch (e) {
      return Err(DomainFailure(
          statusCode: 500, code: 'unknown', message: e.toString()));
    }
  }

  @override
  Future<Result<void, DomainFailure>> upsertProviderProfile(
      UpsertProviderProfileRequest request) async {
    try {
      await remote.upsertProviderProfile(request.toJson());
      final user = (await getStoredUser()).map(
        ok: (value) => value.value,
        err: (_) => null,
      );
      if (user != null) {
        await db.into(db.providerProfiles).insertOnConflictUpdate(
              ProviderProfilesCompanion.insert(
                userId: user.id,
                displayName: request.displayName,
                municipality: request.municipality,
                department: request.department,
                lat: request.lat,
                lng: request.lng,
                description: request.description,
                updatedAt: DateTime.now(),
              ),
            );
      }
      return const Ok(null);
    } on DomainFailure catch (e) {
      return Err(e);
    } on DioException catch (e) {
      return Err(_networkFailure(e));
    } catch (e) {
      return Err(DomainFailure(
          statusCode: 500, code: 'unknown', message: e.toString()));
    }
  }

  @override
  Future<Result<UpsertProviderProfileRequest?, DomainFailure>>
      getStoredProviderProfile() async {
    try {
      final activeId = await secureStorage.read(key: _activeAccountKey);
      final query = db.select(db.providerProfiles);
      if (activeId != null) query.where((row) => row.userId.equals(activeId));
      final row = await (query..limit(1)).getSingleOrNull();
      if (row == null) return const Ok(null);
      return Ok(UpsertProviderProfileRequest(
        displayName: row.displayName,
        municipality: row.municipality,
        department: row.department,
        lat: row.lat,
        lng: row.lng,
        description: row.description,
      ));
    } catch (e) {
      return Err(DomainFailure(
          statusCode: 500, code: 'unknown', message: e.toString()));
    }
  }

  @override
  Future<Result<User?, DomainFailure>> getStoredUser() async {
    try {
      final activeId = await secureStorage.read(key: _activeAccountKey);
      final stored = activeId == null
          ? await (db.select(db.users)
                ..orderBy([(row) => OrderingTerm.desc(row.updatedAt)])
                ..limit(1))
              .getSingleOrNull()
          : await (db.select(db.users)..where((row) => row.id.equals(activeId)))
              .getSingleOrNull();
      if (stored == null) return const Ok(null);
      return Ok(User(
        id: stored.id,
        role: stored.role,
        fullName: stored.fullName,
        phone: stored.phone,
        status: stored.status,
        locale: stored.locale,
      ));
    } catch (e) {
      return Err(DomainFailure(
          statusCode: 500, code: 'unknown', message: e.toString()));
    }
  }

  @override
  Future<void> saveSession(AuthSession session) async {
    final previousAccountId = await secureStorage.read(key: _activeAccountKey);
    if (previousAccountId != null && previousAccountId != session.user.id) {
      await _clearAccountScopedCache();
    }
    final account = await _readAccount(session.user.id);
    final deviceId = _pendingDeviceId ??
        account?['deviceId'] as String? ??
        await getDeviceId();
    _pendingDeviceId = null;
    await secureStorage.write(
        key: _refreshKey(session.user.id), value: session.refreshToken);
    await secureStorage.write(key: _activeAccountKey, value: session.user.id);
    await _writeAccount(session.user, deviceId);
    await remote.setAuthToken(session.accessToken);
    await db.into(db.users).insertOnConflictUpdate(
          UsersCompanion(
            id: Value(session.user.id),
            role: Value(session.user.role),
            fullName: Value(session.user.fullName),
            phone: Value(session.user.phone),
            status: Value(session.user.status),
            locale: Value(session.user.locale),
            updatedAt: Value(DateTime.now()),
          ),
        );
  }

  @override
  Future<Result<String?, DomainFailure>> getStoredRefreshToken() async {
    try {
      await _migrateLegacyAccount();
      final activeId = await secureStorage.read(key: _activeAccountKey);
      final refreshToken = activeId == null
          ? await secureStorage.read(key: _legacyRefreshKey)
          : await secureStorage.read(key: _refreshKey(activeId));
      if (refreshToken == null || refreshToken.isEmpty) return const Ok(null);
      return Ok(refreshToken);
    } catch (e) {
      return Err(DomainFailure(
          statusCode: 500, code: 'unknown', message: e.toString()));
    }
  }

  @override
  Future<void> clearSession() async {
    final activeId = await secureStorage.read(key: _activeAccountKey);
    await remote.setAuthToken(null);
    if (activeId != null) {
      await removeSavedAccount(activeId);
    } else {
      await secureStorage.delete(key: _legacyRefreshKey);
      await db.delete(db.users).go();
    }
  }

  @override
  Future<String> getDeviceId() async {
    await _migrateLegacyAccount();
    final activeId = await secureStorage.read(key: _activeAccountKey);
    if (activeId != null) {
      final account = await _readAccount(activeId);
      final accountDeviceId = account?['deviceId'] as String?;
      if (accountDeviceId != null && accountDeviceId.isNotEmpty) {
        return accountDeviceId;
      }
    }
    var id = await secureStorage.read(key: _legacyDeviceKey);
    if (id == null || id.isEmpty) {
      id = const Uuid().v4();
      await secureStorage.write(key: _legacyDeviceKey, value: id);
    }
    return id;
  }

  @override
  Future<String> getDeviceIdForPhone(String phone) async {
    final normalized = phone.replaceAll(RegExp(r'\D'), '');
    final key =
        'localDevice_${base64Url.encode(utf8.encode(normalized)).replaceAll('=', '')}';
    var id = await secureStorage.read(key: key);
    if (id == null || id.isEmpty) {
      id = const Uuid().v4();
      await secureStorage.write(key: key, value: id);
    }
    _pendingDeviceId = id;
    return id;
  }

  @override
  Future<List<SavedAccount>> getSavedAccounts() async {
    await _migrateLegacyAccount();
    final activeId = await secureStorage.read(key: _activeAccountKey);
    final accounts = await _readAccounts();
    return accounts
        .map((account) => SavedAccount(
              user: User.fromJson(account['user'] as Map<String, dynamic>),
              isActive: account['userId'] == activeId,
            ))
        .toList(growable: false);
  }

  @override
  Future<Result<AuthSession, DomainFailure>> activateSavedAccount(
      String userId) async {
    final account = await _readAccount(userId);
    final refreshToken = await secureStorage.read(key: _refreshKey(userId));
    if (account == null || refreshToken == null || refreshToken.isEmpty) {
      return const Err(DomainFailure(
        statusCode: 404,
        code: 'saved_account_missing',
        message: 'No encontramos una sesión guardada para esta cuenta.',
      ));
    }
    try {
      final json = await remote.refreshSession({
        'refreshToken': refreshToken,
        'deviceId': account['deviceId'],
      });
      final session = AuthSession.fromJson(json);
      await saveSession(session);
      await _storeUser(session.user);
      return Ok(session);
    } on DomainFailure catch (error) {
      return Err(error);
    } on DioException catch (error) {
      return Err(_networkFailure(error));
    } catch (error) {
      return Err(DomainFailure(
        statusCode: 500,
        code: 'unknown',
        message: error.toString(),
      ));
    }
  }

  @override
  Future<User?> activateSavedAccountOffline(String userId) async {
    final account = await _readAccount(userId);
    if (account == null) return null;
    final previousAccountId = await secureStorage.read(key: _activeAccountKey);
    if (previousAccountId != null && previousAccountId != userId) {
      await _clearAccountScopedCache();
    }
    await secureStorage.write(key: _activeAccountKey, value: userId);
    await remote.setAuthToken(null);
    return User.fromJson(account['user'] as Map<String, dynamic>);
  }

  @override
  Future<void> removeSavedAccount(String userId) async {
    await secureStorage.delete(key: _refreshKey(userId));
    final accounts = await _readAccounts()
      ..removeWhere((account) => account['userId'] == userId);
    await _writeAccounts(accounts);
    await (db.delete(db.users)..where((row) => row.id.equals(userId))).go();
    await (db.delete(db.providerProfiles)
          ..where((row) => row.userId.equals(userId)))
        .go();
    if (await secureStorage.read(key: _activeAccountKey) == userId) {
      await secureStorage.delete(key: _activeAccountKey);
      await remote.setAuthToken(null);
      await _clearAccountScopedCache();
    }
  }

  Future<void> _migrateLegacyAccount() async {
    final legacyToken = await secureStorage.read(key: _legacyRefreshKey);
    if (legacyToken == null || legacyToken.isEmpty) return;
    final activeId = await secureStorage.read(key: _activeAccountKey);
    if (activeId != null) return;
    final rows = await db.select(db.users).get();
    if (rows.isEmpty) return;
    rows.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final row = rows.first;
    final deviceId =
        await secureStorage.read(key: _legacyDeviceKey) ?? const Uuid().v4();
    final user = User(
      id: row.id,
      role: row.role,
      fullName: row.fullName,
      phone: row.phone,
      status: row.status,
      locale: row.locale,
    );
    await secureStorage.write(key: _refreshKey(user.id), value: legacyToken);
    await secureStorage.write(key: _activeAccountKey, value: user.id);
    await _writeAccount(user, deviceId);
    await secureStorage.delete(key: _legacyRefreshKey);
    await secureStorage.delete(key: _legacyDeviceKey);
  }

  Future<List<Map<String, dynamic>>> _readAccounts() async {
    final raw = await secureStorage.read(key: _accountsKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> _readAccount(String userId) async {
    for (final account in await _readAccounts()) {
      if (account['userId'] == userId) return account;
    }
    return null;
  }

  Future<void> _writeAccount(User user, String deviceId) async {
    final accounts = await _readAccounts()
      ..removeWhere((account) => account['userId'] == user.id);
    accounts.add({
      'userId': user.id,
      'deviceId': deviceId,
      'user': user.toJson(),
    });
    await _writeAccounts(accounts);
  }

  Future<void> _writeAccounts(List<Map<String, dynamic>> accounts) async {
    await secureStorage.write(key: _accountsKey, value: jsonEncode(accounts));
  }

  Future<void> _clearAccountScopedCache() async {
    await (db.delete(db.syncState)
          ..where((row) =>
              row.key.equals('catalog_my_lots') |
              row.key.like('catalog_lot_%') |
              row.key.like('catalog_search_%') |
              row.key.like('ordering_%') |
              row.key.equals('logistics:local-payment-candidates')))
        .go();
    await (db.delete(db.lots)..where((row) => row.isMine.equals(true))).go();
  }

  String _refreshKey(String userId) => 'refreshToken_$userId';

  DomainFailure _networkFailure(DioException error) {
    final response = error.response;
    final data = response?.data;
    final code = data is Map ? data['code']?.toString() : null;
    return DomainFailure(
      statusCode: response?.statusCode ?? 0,
      code: code ?? (response == null ? 'network_error' : 'unknown'),
      message: response == null ? 'Sin conexión.' : 'Error del servidor.',
    );
  }

  Future<void> _storeUser(User user) async {
    await db.into(db.users).insertOnConflictUpdate(
          UsersCompanion(
            id: Value(user.id),
            role: Value(user.role),
            fullName: Value(user.fullName),
            phone: Value(user.phone),
            status: Value(user.status),
            locale: Value(user.locale),
            updatedAt: Value(DateTime.now()),
          ),
        );
  }
}

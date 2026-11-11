import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/result/result.dart';
import '../../../../core/storage/app_database.dart' hide User;
import '../remote/auth_remote.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/entities/user.dart';
import '../../domain/repository/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remote;
  final AppDatabase db;
  final FlutterSecureStorage secureStorage;
  Future<Result<AuthSession, DomainFailure>>? _refreshInFlight;

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
      final row =
          await (db.select(db.providerProfiles)..limit(1)).getSingleOrNull();
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
      final stored = await db.select(db.users).getSingleOrNull();
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
    await secureStorage.write(key: 'refreshToken', value: session.refreshToken);
    await secureStorage.write(key: 'deviceId', value: await getDeviceId());
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
      final refreshToken = await secureStorage.read(key: 'refreshToken');
      if (refreshToken == null || refreshToken.isEmpty) return const Ok(null);
      return Ok(refreshToken);
    } catch (e) {
      return Err(DomainFailure(
          statusCode: 500, code: 'unknown', message: e.toString()));
    }
  }

  @override
  Future<void> clearSession() async {
    await remote.setAuthToken(null);
    await secureStorage.delete(key: 'refreshToken');
    await db.delete(db.users).go();
    await db.delete(db.providerProfiles).go();
  }

  @override
  Future<String> getDeviceId() async {
    var id = await secureStorage.read(key: 'deviceId');
    if (id == null || id.isEmpty) {
      id = const Uuid().v4();
      await secureStorage.write(key: 'deviceId', value: id);
    }
    return id;
  }

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

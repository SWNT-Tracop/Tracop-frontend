import '../../../../core/result/result.dart';
import '../entities/auth_session.dart';
import '../entities/saved_account.dart';
import '../entities/user.dart';

abstract class AuthRepository {
  Future<Result<void, DomainFailure>> register(RegisterRequest request);
  Future<Result<RequestOtpResponse, DomainFailure>> requestOtp(
      RequestOtpRequest request);
  Future<Result<AuthSession, DomainFailure>> verifyOtp(
      VerifyOtpRequest request);
  Future<Result<AuthSession, DomainFailure>> refreshSession(
      RefreshSessionRequest request);
  Future<Result<void, DomainFailure>> logout();
  Future<Result<User, DomainFailure>> getMe();
  Future<Result<User, DomainFailure>> updateMe(UpdateMeRequest request);
  Future<Result<void, DomainFailure>> upsertProviderProfile(
      UpsertProviderProfileRequest request);
  Future<Result<UpsertProviderProfileRequest?, DomainFailure>>
      getStoredProviderProfile();
  Future<Result<User?, DomainFailure>> getStoredUser();
  Future<void> saveSession(AuthSession session);
  Future<Result<String?, DomainFailure>> getStoredRefreshToken();
  Future<String> getDeviceId();
  Future<void> clearSession();
}

/// Additional local-only account tools. Kept separate so existing auth fakes
/// and implementations are not required to support multi-account storage.
abstract interface class LocalAccountRepository {
  Future<String> getDeviceIdForPhone(String phone);
  Future<List<SavedAccount>> getSavedAccounts();
  Future<Result<AuthSession, DomainFailure>> activateSavedAccount(
      String userId);
  Future<User?> activateSavedAccountOffline(String userId);
  Future<void> removeSavedAccount(String userId);
}

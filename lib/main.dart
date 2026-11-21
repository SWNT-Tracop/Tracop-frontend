import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'app/app.dart';
import 'core/config/env.dart';
import 'core/network/dio_client.dart';
import 'core/storage/app_database.dart';
import 'features/auth/data/repository/auth_repository_impl.dart';
import 'features/auth/data/remote/auth_remote.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/auth/domain/entities/auth_session.dart';
import 'features/auth/domain/entities/user.dart';
import 'core/result/result.dart';
import 'features/catalog/data/repository/catalog_repository_impl.dart';
import 'features/catalog/data/remote/catalog_remote.dart';
import 'features/catalog/presentation/providers/catalog_provider.dart';
import 'features/ordering/data/remote/order_remote.dart';
import 'features/ordering/data/repository/order_repository_impl.dart';
import 'features/ordering/presentation/providers/order_provider.dart';
import 'features/logistics/data/logistics_remote.dart';

import 'features/logistics/data/logistics_repository.dart';
import 'features/logistics/presentation/logistics_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) usePathUrlStrategy();

  final dioClient = DioClient(baseUrl: AppConfig.apiBaseUrl);
  final db = await AppDatabase.create();

  final authRemote = AuthRemoteDataSourceImpl(dioClient);
  final authRepo = AuthRepositoryImpl(
      remote: authRemote, db: db, secureStorage: const FlutterSecureStorage());

  final catalogRemote = CatalogRemoteDataSourceImpl(dioClient);
  final catalogRepo = CatalogRepositoryImpl(remote: catalogRemote, db: db);
  final orderRemote = OrderRemoteDataSourceImpl(dioClient);
  final orderRepo = OrderRepositoryImpl(remote: orderRemote, db: db);
  final logisticsRepo = LogisticsRepository(
    remote: LogisticsRemoteDataSource(dioClient),
    database: db,
  );

  dioClient.setRefreshHandler(() async {
    final stored = await authRepo.getStoredRefreshToken();
    final refreshToken =
        stored.map(ok: (value) => value.value, err: (_) => null);
    if (refreshToken == null) return null;
    final refreshed = await authRepo.refreshSession(RefreshSessionRequest(
      refreshToken: refreshToken,
      deviceId: await authRepo.getDeviceId(),
    ));
    if (refreshed is Ok<AuthSession, DomainFailure>) {
      return refreshed.value.accessToken;
    }
    final failure = (refreshed as Err<AuthSession, DomainFailure>).error;
    if (failure.statusCode == 401 || failure.code == 'invalid_session') {
      await authRepo.clearSession();
      authInvalidationSignal.value++;
    }
    return null;
  });
  runApp(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(authRepo),
        catalogRepositoryProvider.overrideWithValue(catalogRepo),
        orderRepositoryProvider.overrideWithValue(orderRepo),
        logisticsRepositoryProvider.overrideWithValue(logisticsRepo),
      ],
      child: const TracopApp(),
    ),
  );
}

import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/result/result.dart';
import '../../../../core/storage/app_database.dart' hide Category, Product, Lot;
import '../remote/catalog_remote.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/lot.dart' hide Category, Product;
import '../../domain/entities/product.dart';
import '../../domain/repository/catalog_repository.dart';

class CatalogRepositoryImpl implements CatalogRepository {
  final CatalogRemoteDataSource remote;
  final AppDatabase db;
  final Future<String?> Function()? ownerUserId;
  static const _uuid = Uuid();

  CatalogRepositoryImpl({
    required this.remote,
    required this.db,
    this.ownerUserId,
  });

  @override
  Future<Result<List<Category>, DomainFailure>> getCategories() async {
    try {
      final json = await remote.getCategories();
      final items = json.map((e) => Category.fromJson(e)).toList();
      await db.batch((batch) {
        for (final c in items) {
          batch.insert(
              db.categories,
              CategoriesCompanion(
                id: Value(c.id),
                name: Value(c.name),
                parentId: Value(c.parentId),
                depth: Value(c.depth),
                syncedAt: Value(DateTime.now()),
              ),
              mode: InsertMode.insertOrReplace);
        }
      });
      return Ok(items);
    } on DomainFailure catch (e) {
      final cached = await _readCategoriesCache();
      return cached.isNotEmpty ? Ok(cached) : Err(e);
    } catch (e) {
      final cached = await _readCategoriesCache();
      if (cached.isNotEmpty) {
        return Ok(cached);
      }
      return Err(DomainFailure(
          statusCode: 500, code: 'unknown', message: e.toString()));
    }
  }

  @override
  Future<Result<List<Product>, DomainFailure>> getProducts(
      {String? categoryId, String? q}) async {
    try {
      final json = await remote.getProducts(categoryId: categoryId, q: q);
      final items = json.map((e) => Product.fromJson(e)).toList();
      if (kDebugMode) {
        debugPrint(
          '[catalog] GET /catalog/products: ${items.length} productos; '
          'nombres: ${items.map((item) => item.name).join(', ')}',
        );
      }
      await db.batch((batch) {
        for (final p in items) {
          batch.insert(
              db.products,
              ProductsCompanion(
                id: Value(p.id),
                categoryId: Value(p.categoryId),
                name: Value(p.name),
                unit: Value(p.unit),
                attributesJson: Value(jsonEncode(p.attributes)),
                syncedAt: Value(DateTime.now()),
              ),
              mode: InsertMode.insertOrReplace);
        }
      });
      return Ok(items);
    } on DomainFailure catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[catalog] GET /catalog/products falló: HTTP ${e.statusCode} '
          '(código ${e.code}); no se registró ninguna credencial.',
        );
      }
      final cached = await _readProductsCache(categoryId: categoryId, q: q);
      return cached.isNotEmpty ? Ok(cached) : Err(e);
    } catch (e) {
      final cached = await _readProductsCache(categoryId: categoryId, q: q);
      if (cached.isNotEmpty) return Ok(cached);
      return Err(DomainFailure(
          statusCode: 500, code: 'unknown', message: e.toString()));
    }
  }

  @override
  Future<Result<Product, DomainFailure>> createProduct(
      CreateProductRequest request) async {
    try {
      final json = await remote.createProduct(request.toJson());
      final product = Product.fromJson(json);
      await db.into(db.products).insertOnConflictUpdate(
            ProductsCompanion(
              id: Value(product.id),
              categoryId: Value(product.categoryId),
              name: Value(product.name),
              unit: Value(product.unit),
              attributesJson: Value(jsonEncode(product.attributes)),
              syncedAt: Value(DateTime.now()),
            ),
          );
      return Ok(product);
    } on DomainFailure catch (e) {
      return Err(e);
    } catch (e) {
      return Err(DomainFailure(
          statusCode: 500, code: 'unknown', message: e.toString()));
    }
  }

  @override
  Future<Result<LotPage, DomainFailure>> searchLots({
    String? cursor,
    int limit = 20,
    String? categoryId,
    String? productId,
    String? q,
    int? minPrice,
    int? maxPrice,
    DateTime? availableFrom,
    DateTime? availableUntil,
    double? lat,
    double? lng,
    int? radiusKm,
    String sort = 'recent',
  }) async {
    final query = <String, dynamic>{
      'limit': limit,
      'sort': sort,
      if (cursor != null) 'cursor': cursor,
      if (categoryId != null) 'categoryId': categoryId,
      if (productId != null) 'productId': productId,
      if (q != null) 'q': q,
      if (minPrice != null) 'minPrice': minPrice,
      if (maxPrice != null) 'maxPrice': maxPrice,
      if (availableFrom != null)
        'availableFrom': availableFrom.toIso8601String(),
      if (availableUntil != null)
        'availableUntil': availableUntil.toIso8601String(),
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
      if (radiusKm != null) 'radiusKm': radiusKm,
    };
    try {
      final json = await remote.searchLots(query);
      final page = LotPage.fromJson(json);
      final existing = cursor == null ? null : await _readSearchCache(query);
      final cachedAt = DateTime.now().toUtc();
      final cachedPage = existing == null
          ? LotPage(
              items: page.items,
              nextCursor: page.nextCursor,
              cachedAt: cachedAt,
            )
          : LotPage(
              items: [...existing.items, ...page.items],
              nextCursor: page.nextCursor,
              cachedAt: cachedAt,
            );
      await _writeCache(
        _searchCacheKey(query),
        jsonEncode({
          'items': cachedPage.items.map((item) => item.toJson()).toList(),
          'nextCursor': cachedPage.nextCursor,
          '_cachedAt': cachedAt.toIso8601String(),
        }),
      );
      await _cacheLots(page.items, cachedAt);
      return Ok(LotPage(
        items: page.items,
        nextCursor: page.nextCursor,
        cachedAt: cachedAt,
      ));
    } on DomainFailure catch (e) {
      final cached = await _readSearchCache(query);
      return cached == null
          ? Err(e)
          : Ok(LotPage(
              items: cached.items,
              nextCursor: cached.nextCursor,
              cachedAt: cached.cachedAt,
              isFromCache: true,
            ));
    } catch (e) {
      final cached = await _readSearchCache(query);
      if (cached != null) {
        return Ok(LotPage(
          items: cached.items,
          nextCursor: cached.nextCursor,
          cachedAt: cached.cachedAt,
          isFromCache: true,
        ));
      }
      return Err(DomainFailure(
          statusCode: 500, code: 'unknown', message: e.toString()));
    }
  }

  @override
  Future<Result<Lot, DomainFailure>> getLot(String id) async {
    try {
      final json = await remote.getLot(id);
      final lot = Lot.fromJson(json);
      final cachedAt = DateTime.now().toUtc();
      final cacheJson = Map<String, dynamic>.from(json)..remove('photos');
      await _writeCache(
          'catalog_lot_$id',
          jsonEncode({
            ...cacheJson,
            '_cachedAt': cachedAt.toIso8601String(),
          }));
      await _cacheLots([lot], cachedAt);
      return Ok(
          Lot.fromJson({...json, '_cachedAt': cachedAt.toIso8601String()}));
    } on DomainFailure catch (e) {
      final cached = await _readLotCache(id);
      return cached == null
          ? Err(e)
          : Ok(Lot.fromJson({...cached.toJson(), '_fromCache': true}));
    } catch (e) {
      final cached = await _readLotCache(id);
      if (cached != null) {
        return Ok(Lot.fromJson({...cached.toJson(), '_fromCache': true}));
      }
      return Err(DomainFailure(
          statusCode: 500, code: 'unknown', message: e.toString()));
    }
  }

  Future<List<Category>> _readCategoriesCache() async {
    final rows = await (db.select(db.categories)
          ..orderBy([
            (row) => OrderingTerm.asc(row.depth),
            (row) => OrderingTerm.asc(row.name)
          ]))
        .get();
    return rows
        .map((row) => Category(
              id: row.id,
              name: row.name,
              parentId: row.parentId,
              depth: row.depth,
            ))
        .toList();
  }

  Future<List<Product>> _readProductsCache(
      {String? categoryId, String? q}) async {
    final query = db.select(db.products);
    if (categoryId != null) {
      query.where((row) => row.categoryId.equals(categoryId));
    }
    final rows = await query.get();
    final normalized = q?.trim().toLowerCase();
    return rows
        .map((row) => Product(
              id: row.id,
              categoryId: row.categoryId,
              name: row.name,
              unit: row.unit,
              attributes: _decodeMap(row.attributesJson),
            ))
        .where((product) =>
            normalized == null ||
            normalized.isEmpty ||
            product.name.toLowerCase().contains(normalized))
        .toList();
  }

  String _searchCacheKey(Map<String, dynamic> query) {
    final normalized = Map<String, dynamic>.from(query)..remove('cursor');
    final encoded = base64Url.encode(utf8.encode(jsonEncode(normalized)));
    return 'catalog_search_${encoded.replaceAll('=', '')}';
  }

  Future<void> _cacheLots(List<Lot> lots, DateTime cachedAt) async {
    for (final lot in lots) {
      await _writeCache(
          'catalog_lot_${lot.id}', _lotCachePayload(lot, cachedAt));
    }
  }

  Future<void> _writeCache(String key, String value) async {
    await db.into(db.syncState).insertOnConflictUpdate(
          SyncStateCompanion.insert(key: key, value: value),
        );
  }

  Future<String?> _readCache(String key) async {
    final row = await (db.select(db.syncState)
          ..where((row) => row.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  Future<LotPage?> _readSearchCache(Map<String, dynamic> query) async {
    final raw = await _readCache(_searchCacheKey(query));
    if (raw == null) return null;
    return LotPage.fromJson({
      ...(jsonDecode(raw) as Map<String, dynamic>),
      '_fromCache': true,
    });
  }

  Future<Lot?> _readLotCache(String id) async {
    final raw = await _readCache('catalog_lot_$id');
    if (raw == null) return null;
    final cachedJson =
        Map<String, dynamic>.from(jsonDecode(raw) as Map<String, dynamic>)
          ..remove('photos');
    await _writeCache('catalog_lot_$id', jsonEncode(cachedJson));
    return Lot.fromJson({
      ...cachedJson,
      '_fromCache': true,
    });
  }

  Map<String, dynamic> _decodeMap(String raw) {
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return const {};
    }
  }

  @override
  Future<Result<List<Lot>, DomainFailure>> getMyLots() async {
    try {
      final json = await remote.getMyLots();
      final items =
          json.map((e) => Lot.fromJson(e..['isMine'] = true)).toList();
      final cachedAt = DateTime.now().toUtc();
      await _writeMyLotsCache(items, cachedAt);
      await _cacheLots(items, cachedAt);
      return Ok(items);
    } on DomainFailure catch (e) {
      final cached = await _readMyLotsCache();
      return cached == null ? Err(e) : Ok(cached);
    } catch (e) {
      final cached = await _readMyLotsCache();
      if (cached != null) return Ok(cached);
      return Err(DomainFailure(
          statusCode: 500, code: 'unknown', message: e.toString()));
    }
  }

  @override
  Future<Result<Lot, DomainFailure>> createLot(CreateLotRequest request) async {
    if (await _isOffline()) {
      final userId = await _ownerId();
      if (userId == null) return _offlineOwnerError();
      final lot = _optimisticLot(request.toJson(),
          providerId: userId, status: 'draft', version: 1);
      await _enqueueLot(
        ownerUserId: userId,
        entityId: request.id,
        type: 'create',
        payload: request.toJson(),
      );
      await _rememberLot(lot);
      return Ok(lot);
    }
    try {
      final json = await remote.createLot(request.toJson());
      final lot = Lot.fromJson({...json, 'isMine': true});
      await _rememberLot(lot);
      return Ok(lot);
    } on DomainFailure catch (e) {
      return Err(e);
    } catch (e) {
      return Err(DomainFailure(
          statusCode: 500, code: 'unknown', message: e.toString()));
    }
  }

  @override
  Future<Result<Lot, DomainFailure>> updateLot(
      String id, UpdateLotRequest request) async {
    if (await _isOffline()) {
      final userId = await _ownerId();
      final current = await _readLotCache(id);
      if (userId == null || current == null) return _offlineOwnerError();
      final patch = Map<String, dynamic>.from(request.toJson())
        ..remove('version');
      final merged = current.toJson()..addAll(patch);
      final lot = _optimisticLot(merged,
          providerId: current.providerId ?? userId,
          status: current.status,
          version: request.version + 1);
      await _enqueueLot(
        ownerUserId: userId,
        entityId: id,
        type: 'update',
        baseVersion: request.version,
        payload: patch,
      );
      await _rememberLot(lot);
      return Ok(lot);
    }
    try {
      final json = await remote.updateLot(id, request.toJson());
      final lot = Lot.fromJson({...json, 'isMine': true});
      await _rememberLot(lot);
      return Ok(lot);
    } on DomainFailure catch (e) {
      return Err(e);
    } catch (e) {
      return Err(DomainFailure(
          statusCode: 500, code: 'unknown', message: e.toString()));
    }
  }

  @override
  Future<Result<Lot, DomainFailure>> publishLot(String id, int version) async {
    if (await _isOffline()) return _queueTransition(id, version, 'published');
    try {
      final json = await remote.publishLot(
          id, PublishCancelRequest(version: version).toJson());
      final lot = Lot.fromJson({...json, 'isMine': true});
      await _rememberLot(lot);
      return Ok(lot);
    } on DomainFailure catch (e) {
      return Err(e);
    } catch (e) {
      return Err(DomainFailure(
          statusCode: 500, code: 'unknown', message: e.toString()));
    }
  }

  @override
  Future<Result<Lot, DomainFailure>> cancelLot(String id, int version) async {
    if (await _isOffline()) return _queueTransition(id, version, 'cancelled');
    try {
      final json = await remote.cancelLot(
          id, PublishCancelRequest(version: version).toJson());
      final lot = Lot.fromJson({...json, 'isMine': true});
      await _rememberLot(lot);
      return Ok(lot);
    } on DomainFailure catch (e) {
      return Err(e);
    } catch (e) {
      return Err(DomainFailure(
          statusCode: 500, code: 'unknown', message: e.toString()));
    }
  }

  @override
  Future<Result<void, DomainFailure>> deleteLot(String id, int version) async {
    if (await _isOffline()) {
      final userId = await _ownerId();
      if (userId == null) return _offlineOwnerError<void>();
      await _enqueueLot(
        ownerUserId: userId,
        entityId: id,
        type: 'delete',
        baseVersion: version,
        payload: const {},
      );
      await _forgetLot(id);
      return const Ok(null);
    }
    try {
      await remote.deleteLot(
          id, PublishCancelRequest(version: version).toJson());
      await _forgetLot(id);
      return const Ok(null);
    } on DomainFailure catch (e) {
      return Err(e);
    } catch (e) {
      return Err(DomainFailure(
          statusCode: 500, code: 'unknown', message: e.toString()));
    }
  }

  @override
  Future<Result<List<LotPhoto>, DomainFailure>> uploadLotPhoto({
    required String lotId,
    required String photoId,
    required String filename,
    required Uint8List bytes,
  }) async {
    try {
      final preparation = await remote.prepareLotPhotoUpload(lotId, photoId);
      var state = preparation['state'];
      if (state == 'pending') {
        final policy = preparation['uploadPolicy'] as Map<String, dynamic>?;
        if (policy == null) {
          throw const DomainFailure(
            statusCode: 502,
            code: 'photo_policy_missing',
            message: 'No se recibió la autorización para cargar la foto.',
          );
        }
        await remote.uploadPhotoObject(
          url: policy['url'] as String,
          fields: Map<String, String>.from(policy['fields'] as Map),
          filename: filename,
          bytes: bytes,
        );
        state = (await remote.confirmLotPhoto(lotId, photoId))['state'];
      }

      for (var attempt = 0; state == 'processing' && attempt < 6; attempt++) {
        await Future<void>.delayed(const Duration(milliseconds: 700));
        state = (await remote.confirmLotPhoto(lotId, photoId))['state'];
      }
      if (state != 'ready') {
        throw const DomainFailure(
          statusCode: 503,
          code: 'photo_processing',
          message: 'La foto sigue procesándose. Intenta actualizar el lote.',
        );
      }
      return Ok(await _fetchLotPhotos(lotId));
    } on DomainFailure catch (e) {
      return Err(e);
    } catch (e) {
      return const Err(DomainFailure(
        statusCode: 500,
        code: 'photo_upload_failed',
        message: 'No se pudo cargar la foto al almacenamiento.',
      ));
    }
  }

  @override
  Future<Result<List<LotPhoto>, DomainFailure>> deleteLotPhoto(
      String lotId, String photoId) async {
    try {
      await remote.deleteLotPhoto(lotId, photoId);
      return Ok(await _fetchLotPhotos(lotId));
    } on DomainFailure catch (e) {
      return Err(e);
    } catch (e) {
      return Err(DomainFailure(
        statusCode: 500,
        code: 'photo_delete_failed',
        message: e.toString(),
      ));
    }
  }

  @override
  Future<Result<List<LotPhoto>, DomainFailure>> reorderLotPhotos(
      String lotId, List<String> photoIds) async {
    try {
      await remote.reorderLotPhotos(lotId, photoIds);
      return Ok(await _fetchLotPhotos(lotId));
    } on DomainFailure catch (e) {
      return Err(e);
    } catch (e) {
      return Err(DomainFailure(
        statusCode: 500,
        code: 'photo_order_failed',
        message: e.toString(),
      ));
    }
  }

  Future<List<LotPhoto>> _fetchLotPhotos(String lotId) async {
    final json = await remote.getLot(lotId);
    final lot = Lot.fromJson(json);
    final cachedAt = DateTime.now().toUtc();
    final cacheJson = Map<String, dynamic>.from(json)..remove('photos');
    await _writeCache(
        'catalog_lot_$lotId',
        jsonEncode({
          ...cacheJson,
          '_cachedAt': cachedAt.toIso8601String(),
        }));
    return lot.photos;
  }

  Future<bool> _isOffline() async {
    final connectivity = await Connectivity().checkConnectivity();
    return !connectivity.any((item) => item != ConnectivityResult.none);
  }

  Future<String?> _ownerId() async {
    final provided = ownerUserId;
    if (provided != null) return provided();
    final row = await (db.select(db.users)
          ..orderBy([(item) => OrderingTerm.desc(item.updatedAt)])
          ..limit(1))
        .getSingleOrNull();
    return row?.id;
  }

  Future<Result<T, DomainFailure>> _offlineOwnerError<T>() async =>
      const Err(DomainFailure(
        statusCode: 401,
        code: 'offline_session_missing',
        message: 'No hay una sesión local disponible para guardar el cambio.',
      ));

  Future<void> _enqueueLot({
    required String ownerUserId,
    required String entityId,
    required String type,
    required Map<String, dynamic> payload,
    int? baseVersion,
  }) async {
    final now = DateTime.now().toUtc();
    await db.into(db.outboxOperations).insert(
          OutboxOperationsCompanion.insert(
            opId: _uuid.v7(),
            ownerUserId: Value(ownerUserId),
            entity: 'lot',
            entityId: entityId,
            type: type,
            payloadJson: jsonEncode(payload),
            baseVersion: Value(baseVersion),
            clientTs: now,
            status: 'pending',
            attempts: 0,
            nextAttemptAt: now,
          ),
        );
  }

  Future<Result<Lot, DomainFailure>> _queueTransition(
      String id, int version, String status) async {
    final userId = await _ownerId();
    final current = await _readLotCache(id);
    if (userId == null || current == null) return _offlineOwnerError();
    final lot = _optimisticLot(current.toJson(),
        providerId: current.providerId ?? userId,
        status: status,
        version: version + 1);
    await _enqueueLot(
      ownerUserId: userId,
      entityId: id,
      type: 'transition',
      baseVersion: version,
      payload: {'status': status},
    );
    await _rememberLot(lot);
    return Ok(lot);
  }

  Lot _optimisticLot(
    Map<String, dynamic> json, {
    required String providerId,
    required String status,
    required int version,
  }) {
    return Lot.fromJson({
      ...json,
      'providerId': providerId,
      'quantityMilli': '${json['quantityMilli']}',
      'unitPrice': '${json['unitPrice']}',
      'status': status,
      'version': version,
      'isMine': true,
      'photos': json['photos'] ?? const [],
    });
  }

  Future<void> _rememberLot(Lot lot) async {
    final cachedAt = DateTime.now().toUtc();
    await _writeCache('catalog_lot_${lot.id}', _lotCachePayload(lot, cachedAt));
    final current = await _readMyLotsCache();
    if (current == null) return;
    final updated = [
      lot,
      ...current.where((item) => item.id != lot.id),
    ];
    await _writeMyLotsCache(updated, cachedAt);
  }

  Future<void> _forgetLot(String id) async {
    await (db.delete(db.syncState)
          ..where((row) => row.key.equals('catalog_lot_$id')))
        .go();
    final current = await _readMyLotsCache();
    if (current == null) return;
    await _writeMyLotsCache(
      current.where((item) => item.id != id).toList(),
      DateTime.now().toUtc(),
    );
  }

  Future<void> _writeMyLotsCache(List<Lot> lots, DateTime cachedAt) async {
    await _writeCache(
      'catalog_my_lots',
      jsonEncode({
        'items': [
          for (final lot in lots)
            {...lot.toJson(), '_cachedAt': cachedAt.toIso8601String()},
        ],
        '_cachedAt': cachedAt.toIso8601String(),
      }),
    );
  }

  Future<List<Lot>?> _readMyLotsCache() async {
    final raw = await _readCache('catalog_my_lots');
    if (raw == null) return null;
    final data = jsonDecode(raw) as Map<String, dynamic>;
    return (data['items'] as List)
        .map((item) => Lot.fromJson({
              ...(item as Map<String, dynamic>),
              'isMine': true,
              '_fromCache': true,
            }))
        .toList();
  }

  String _lotCachePayload(Lot lot, DateTime cachedAt) => jsonEncode({
        ...lot.toJson(),
        '_cachedAt': cachedAt.toIso8601String(),
      });
}

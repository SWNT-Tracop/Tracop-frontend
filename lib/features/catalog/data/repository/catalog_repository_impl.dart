import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:drift/drift.dart';
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

  CatalogRepositoryImpl({required this.remote, required this.db});

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
      await _writeCache('catalog_lot_$id',
          jsonEncode({...json, '_cachedAt': cachedAt.toIso8601String()}));
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
    return Lot.fromJson({
      ...(jsonDecode(raw) as Map<String, dynamic>),
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

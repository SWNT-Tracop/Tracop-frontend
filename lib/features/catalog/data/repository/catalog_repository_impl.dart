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
              ));
        }
      });
      return Ok(items);
    } on DomainFailure catch (e) {
      return Err(e);
    } catch (e) {
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
      await db.batch((batch) {
        for (final p in items) {
          batch.insert(
              db.products,
              ProductsCompanion(
                id: Value(p.id),
                categoryId: Value(p.categoryId),
                name: Value(p.name),
                unit: Value(p.unit),
                attributesJson: Value(p.attributes.toString()),
                syncedAt: Value(DateTime.now()),
              ));
        }
      });
      return Ok(items);
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
    try {
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
      final json = await remote.searchLots(query);
      final page = LotPage.fromJson(json);
      return Ok(page);
    } on DomainFailure catch (e) {
      return Err(e);
    } catch (e) {
      return Err(DomainFailure(
          statusCode: 500, code: 'unknown', message: e.toString()));
    }
  }

  @override
  Future<Result<Lot, DomainFailure>> getLot(String id) async {
    try {
      final json = await remote.getLot(id);
      return Ok(Lot.fromJson(json));
    } on DomainFailure catch (e) {
      return Err(e);
    } catch (e) {
      return Err(DomainFailure(
          statusCode: 500, code: 'unknown', message: e.toString()));
    }
  }

  @override
  Future<Result<List<Lot>, DomainFailure>> getMyLots() async {
    try {
      final json = await remote.getMyLots();
      final items =
          json.map((e) => Lot.fromJson(e..['isMine'] = true)).toList();
      return Ok(items);
    } on DomainFailure catch (e) {
      return Err(e);
    } catch (e) {
      return Err(DomainFailure(
          statusCode: 500, code: 'unknown', message: e.toString()));
    }
  }

  @override
  Future<Result<Lot, DomainFailure>> createLot(CreateLotRequest request) async {
    try {
      final json = await remote.createLot(request.toJson());
      return Ok(Lot.fromJson(json));
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
      return Ok(Lot.fromJson(json));
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
      return Ok(Lot.fromJson(json));
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
      return Ok(Lot.fromJson(json));
    } on DomainFailure catch (e) {
      return Err(e);
    } catch (e) {
      return Err(DomainFailure(
          statusCode: 500, code: 'unknown', message: e.toString()));
    }
  }
}

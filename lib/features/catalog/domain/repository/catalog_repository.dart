import '../../../../core/result/result.dart';
import '../entities/category.dart';
import '../entities/lot.dart' hide Category, Product;
import '../entities/product.dart';

abstract class CatalogRepository {
  Future<Result<List<Category>, DomainFailure>> getCategories();
  Future<Result<List<Product>, DomainFailure>> getProducts(
      {String? categoryId, String? q});
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
  });
  Future<Result<Lot, DomainFailure>> getLot(String id);
  Future<Result<List<Lot>, DomainFailure>> getMyLots();
  Future<Result<Lot, DomainFailure>> createLot(CreateLotRequest request);
  Future<Result<Lot, DomainFailure>> updateLot(
      String id, UpdateLotRequest request);
  Future<Result<Lot, DomainFailure>> publishLot(String id, int version);
  Future<Result<Lot, DomainFailure>> cancelLot(String id, int version);
}

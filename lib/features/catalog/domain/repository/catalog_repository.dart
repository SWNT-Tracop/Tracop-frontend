import 'dart:typed_data';

import '../../../../core/result/result.dart';
import '../entities/category.dart';
import '../entities/lot.dart' hide Category, Product;
import '../entities/product.dart';

class PendingPhotoStatus {
  const PendingPhotoStatus({
    required this.photoId,
    required this.state,
    required this.attempts,
    required this.nextAttemptAt,
    this.lastError,
  });

  final String photoId;
  final String state;
  final int attempts;
  final DateTime nextAttemptAt;
  final String? lastError;
}

abstract interface class PendingPhotoStatusReader {
  Future<List<PendingPhotoStatus>> pendingLotPhotoStatuses(String lotId);
}

abstract class CatalogRepository {
  Future<Result<List<Category>, DomainFailure>> getCategories();
  Future<Result<List<Product>, DomainFailure>> getProducts(
      {String? categoryId, String? q});
  Future<Result<Product, DomainFailure>> createProduct(
      CreateProductRequest request);
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
  Future<Result<void, DomainFailure>> deleteLot(String id, int version);
  Future<Result<List<LotPhoto>, DomainFailure>> uploadLotPhoto({
    required String lotId,
    required String photoId,
    required String filename,
    required Uint8List bytes,
  });
  Future<Result<List<LotPhoto>, DomainFailure>> deleteLotPhoto(
      String lotId, String photoId);
  Future<Result<List<LotPhoto>, DomainFailure>> reorderLotPhotos(
      String lotId, List<String> photoIds);

  Future<void> syncPendingLotPhotos();
}

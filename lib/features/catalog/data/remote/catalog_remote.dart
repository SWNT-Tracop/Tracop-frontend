import '../../../../core/network/dio_client.dart';

abstract class CatalogRemoteDataSource {
  Future<List<Map<String, dynamic>>> getCategories();
  Future<List<Map<String, dynamic>>> getProducts(
      {String? categoryId, String? q});
  Future<Map<String, dynamic>> createProduct(Map<String, dynamic> body);
  Future<Map<String, dynamic>> searchLots(Map<String, dynamic> query);
  Future<Map<String, dynamic>> getLot(String id);
  Future<List<Map<String, dynamic>>> getMyLots();
  Future<Map<String, dynamic>> createLot(Map<String, dynamic> body);
  Future<Map<String, dynamic>> updateLot(String id, Map<String, dynamic> body);
  Future<Map<String, dynamic>> publishLot(String id, Map<String, dynamic> body);
  Future<Map<String, dynamic>> cancelLot(String id, Map<String, dynamic> body);
  Future<void> deleteLot(String id, Map<String, dynamic> body);
}

class CatalogRemoteDataSourceImpl implements CatalogRemoteDataSource {
  final DioClient dioClient;

  CatalogRemoteDataSourceImpl(this.dioClient);

  @override
  Future<List<Map<String, dynamic>>> getCategories() async {
    final response = await dioClient.instance.get('/catalog/categories');
    return (response.data as List).cast<Map<String, dynamic>>();
  }

  @override
  Future<List<Map<String, dynamic>>> getProducts(
      {String? categoryId, String? q}) async {
    final query = <String, dynamic>{};
    if (categoryId != null) query['categoryId'] = categoryId;
    if (q != null) query['q'] = q;
    final response = await dioClient.instance
        .get('/catalog/products', queryParameters: query);
    return (response.data as List).cast<Map<String, dynamic>>();
  }

  @override
  Future<Map<String, dynamic>> createProduct(Map<String, dynamic> body) async {
    final response =
        await dioClient.instance.post('/catalog/products', data: body);
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> searchLots(Map<String, dynamic> query) async {
    final response =
        await dioClient.instance.get('/lots', queryParameters: query);
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> getLot(String id) async {
    final response = await dioClient.instance.get('/lots/$id');
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<List<Map<String, dynamic>>> getMyLots() async {
    final response = await dioClient.instance.get('/lots/mine');
    return (response.data as List).cast<Map<String, dynamic>>();
  }

  @override
  Future<Map<String, dynamic>> createLot(Map<String, dynamic> body) async {
    final response = await dioClient.instance.post('/lots', data: body);
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> updateLot(
      String id, Map<String, dynamic> body) async {
    final response = await dioClient.instance.patch('/lots/$id', data: body);
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> publishLot(
      String id, Map<String, dynamic> body) async {
    final response =
        await dioClient.instance.post('/lots/$id/publish', data: body);
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> cancelLot(
      String id, Map<String, dynamic> body) async {
    final response =
        await dioClient.instance.post('/lots/$id/cancel', data: body);
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<void> deleteLot(String id, Map<String, dynamic> body) async {
    await dioClient.instance.delete('/lots/$id', data: body);
  }
}

import '../../../../core/result/result.dart';
import '../entities/order.dart';

abstract interface class OrderRepository {
  Future<Result<OrderResponse, DomainFailure>> createOrder(
      CreateOrderRequest request);
  Future<Result<OrderPage, DomainFailure>> listMyOrders(
      {String? cursor, int limit = 20});
  Future<Result<OrderPage, DomainFailure>> listIncomingOrders(
      {String? cursor, int limit = 20});
  Future<Result<OrderResponse, DomainFailure>> getOrderById(String id);
  Future<Result<OrderResponse, DomainFailure>> acceptQuote(
      String id, int expectedVersion);
  Future<Result<OrderResponse, DomainFailure>> cancelOrder(
      String id, int expectedVersion,
      {String? reason});
  Future<Result<OrderResponse, DomainFailure>> simulatePaymentLocally(
      OrderResponse order);
}

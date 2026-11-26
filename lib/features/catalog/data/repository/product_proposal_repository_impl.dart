import '../../../../core/result/result.dart';
import '../../domain/entities/product_proposal.dart';
import '../../domain/repository/product_proposal_repository.dart';
import '../remote/catalog_remote.dart';

class ProductProposalRepositoryImpl implements ProductProposalRepository {
  ProductProposalRepositoryImpl({required this.remote});

  final CatalogRemoteDataSource remote;

  @override
  Future<Result<ProductProposal, DomainFailure>> create(
      CreateProductProposalRequest request) async {
    try {
      final response = await remote.createProductProposal(request.toJson());
      return Ok(ProductProposal.fromJson(
          Map<String, dynamic>.from(response['product'] as Map)));
    } on DomainFailure catch (error) {
      return Err(error);
    } catch (error) {
      return Err(DomainFailure(
        statusCode: 500,
        code: 'product_proposal_failed',
        message: error.toString(),
      ));
    }
  }

  @override
  Future<Result<List<ProductProposal>, DomainFailure>> listMine() async {
    try {
      final response = await remote.getProductProposals();
      return Ok(response
          .map((item) => ProductProposal.fromJson(item))
          .toList(growable: false));
    } on DomainFailure catch (error) {
      return Err(error);
    } catch (error) {
      return Err(DomainFailure(
        statusCode: 500,
        code: 'product_proposals_failed',
        message: error.toString(),
      ));
    }
  }
}

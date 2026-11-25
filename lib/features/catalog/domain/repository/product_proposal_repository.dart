import '../../../../core/result/result.dart';
import '../entities/product_proposal.dart';

abstract class ProductProposalRepository {
  Future<Result<ProductProposal, DomainFailure>> create(
      CreateProductProposalRequest request);
  Future<Result<List<ProductProposal>, DomainFailure>> listMine();
}

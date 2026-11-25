import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/product_proposal.dart';
import '../../domain/repository/product_proposal_repository.dart';

final productProposalRepositoryProvider =
    Provider<ProductProposalRepository>((ref) {
  throw UnimplementedError('ProductProposalRepository requires app setup.');
});

final productProposalsProvider =
    FutureProvider<List<ProductProposal>>((ref) async {
  final result = await ref.read(productProposalRepositoryProvider).listMine();
  return result.map(
      ok: (value) => value.value, err: (failure) => throw failure);
});

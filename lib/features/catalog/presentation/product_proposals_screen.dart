import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../app/theme.dart';
import '../../../core/i18n/strings.dart';
import '../domain/entities/product_proposal.dart';
import 'providers/product_proposal_provider.dart';

class ProductProposalsScreen extends ConsumerWidget {
  const ProductProposalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final proposals = ref.watch(productProposalsProvider);
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(CatalogStrings.productProposals),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: proposals.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (items) => items.isEmpty
            ? const Center(child: Text(CatalogStrings.noProductProposals))
            : ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) => _ProposalCard(items[index]),
              ),
      ),
    );
  }
}

class _ProposalCard extends ConsumerWidget {
  const _ProposalCard(this.proposal);

  final ProductProposal proposal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (label, color) = switch (proposal.status) {
      'approved' => (CatalogStrings.approved, AppTheme.forest),
      'rejected' => (CatalogStrings.rejected, AppTheme.dangerStrong),
      _ => (CatalogStrings.pendingReview, AppTheme.warningIcon),
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
                child: Text(proposal.name,
                    style: Theme.of(context).textTheme.titleMedium)),
            Text(label,
                style: TextStyle(color: color, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 6),
          Text(proposal.unit),
          if (proposal.rejectionReason?.isNotEmpty == true) ...[
            const SizedBox(height: 10),
            Text(
                '${CatalogStrings.rejectionReason}: ${proposal.rejectionReason}',
                style: const TextStyle(color: AppTheme.dangerStrong)),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => _resubmit(context, ref),
              child: const Text(CatalogStrings.resubmit),
            ),
          ],
        ]),
      ),
    );
  }

  Future<void> _resubmit(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController(text: proposal.name);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(CatalogStrings.resubmit),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 120,
          decoration: const InputDecoration(labelText: 'Nombre corregido'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(CommonStrings.back)),
          FilledButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text(CatalogStrings.resubmit)),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty || !context.mounted) return;
    final result = await ref.read(productProposalRepositoryProvider).create(
          CreateProductProposalRequest(
            id: const Uuid().v7(),
            categoryId: proposal.categoryId,
            name: name,
            unit: proposal.unit,
            attributes: proposal.attributes,
          ),
        );
    if (!context.mounted) return;
    result.map(
      ok: (_) {
        ref.invalidate(productProposalsProvider);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('La propuesta corregida fue enviada.')));
      },
      err: (failure) => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(failure.error.message))),
    );
  }
}

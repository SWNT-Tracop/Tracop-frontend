import 'package:flutter/material.dart';

import '../../app/theme.dart';

class ProviderTrustSummary extends StatelessWidget {
  const ProviderTrustSummary({
    super.key,
    required this.verified,
    required this.rating,
    required this.ratingsCount,
    this.compact = false,
  });

  final bool verified;
  final String? rating;
  final int ratingsCount;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final hasRating = rating?.isNotEmpty == true;
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (verified)
          const _TrustPill(
            icon: Icons.verified_outlined,
            label: 'Proveedor verificado',
            color: AppTheme.forest,
          ),
        if (hasRating)
          _TrustPill(
            icon: Icons.star_rounded,
            label: '$rating ($ratingsCount)',
            color: const Color(0xFF9A6500),
          )
        else if (!compact)
          Text(
            ratingsCount == 0
                ? 'Aún sin valoraciones'
                : 'Valoración visible después de $ratingsCount calificaciones',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.mutedText,
                ),
          ),
      ],
    );
  }
}

class _TrustPill extends StatelessWidget {
  const _TrustPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .10),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    color: color, fontSize: 12, fontWeight: FontWeight.w700)),
          ],
        ),
      );
}

import 'package:flutter/material.dart';

import '../../app/theme.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader(
      {super.key,
      required this.name,
      required this.phone,
      required this.role,
      required this.icon,
      required this.color,
      this.onEdit});
  final String name, phone, role;
  final IconData icon;
  final Color color;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) => Row(children: [
        Semantics(
            label: 'Avatar de $name',
            child: CircleAvatar(
                radius: 38,
                backgroundColor: AppTheme.mint,
                child: Text(_initials(name),
                    style: const TextStyle(
                        color: AppTheme.forest,
                        fontSize: 24,
                        fontWeight: FontWeight.w700)))),
        const SizedBox(width: 16),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(phone),
          const SizedBox(height: 8),
          DecoratedBox(
              decoration: BoxDecoration(
                  color: color.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(20)),
              child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(icon, size: 16, color: color),
                    const SizedBox(width: 6),
                    Flexible(
                        child: Text(role,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: color, fontWeight: FontWeight.w600)))
                  ])))
        ])),
        if (onEdit != null)
          IconButton(
              onPressed: onEdit,
              tooltip: 'Editar nombre',
              icon: const Icon(Icons.edit_outlined)),
      ]);
}

class ProfileCompletenessRing extends StatelessWidget {
  const ProfileCompletenessRing(
      {super.key, required this.progress, required this.label});
  final double progress;
  final String label;
  @override
  Widget build(BuildContext context) => Semantics(
      label: '$label ${(progress * 100).round()}% completo',
      child: Row(children: [
        SizedBox(
            width: 56,
            height: 56,
            child: TweenAnimationBuilder<double>(
                tween: Tween(end: progress),
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 320),
                builder: (context, value, _) => CircularProgressIndicator(
                    value: value,
                    strokeWidth: 6,
                    backgroundColor: AppTheme.outline,
                    color: AppTheme.primary))),
        const SizedBox(width: 14),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('$label ${(progress * 100).round()}% completo',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text('Completa tu perfil para publicar lotes.')
        ]))
      ]));
}

class EditableInfoTile extends StatelessWidget {
  const EditableInfoTile(
      {super.key,
      required this.title,
      required this.value,
      required this.icon,
      this.onTap});
  final String title, value;
  final IconData icon;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => ListTile(
      minTileHeight: 60,
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(value),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap);
}

class SettingsSection extends StatelessWidget {
  const SettingsSection(
      {super.key, required this.title, required this.children});
  final String title;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
            padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
            child: Text(title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppTheme.forest, fontWeight: FontWeight.w700))),
        Card(margin: EdgeInsets.zero, child: Column(children: children))
      ]);
}

String _initials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '?';
  return parts
      .take(2)
      .map((part) => part.characters.first.toUpperCase())
      .join();
}

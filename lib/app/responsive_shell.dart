import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../features/home/presentation/home_screen.dart';
import 'theme.dart';

class ResponsiveShell extends ConsumerWidget {
  const ResponsiveShell(
      {required this.currentLocation, required this.child, super.key});
  final String currentLocation;
  final Widget child;

  static const _destinations = <({String path, String label, IconData icon})>[
    (path: '/', label: 'Inicio', icon: Icons.home_outlined),
    (path: '/buscar', label: 'Buscar', icon: Icons.search),
    (path: '/lotes', label: 'Mis lotes', icon: Icons.inventory_2_outlined),
    (path: '/perfil', label: 'Perfil', icon: Icons.person_outline),
  ];

  int get _selectedIndex {
    if (currentLocation.startsWith('/lots/')) return 1;
    final index = _destinations.indexWhere((item) =>
        currentLocation == item.path ||
        currentLocation.startsWith('${item.path}/'));
    return index < 0 ? 0 : index;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(homeUserProvider).valueOrNull;
    final connectivity = ref.watch(homeConnectivityProvider);
    final lots = currentLocation == '/' ? ref.watch(homeLotsProvider) : null;
    final connected = connectivity.valueOrNull;
    final syncing = lots?.isLoading ?? false;
    final failed = lots?.hasError ?? false;
    final syncLabel = connected == null
        ? 'Comprobando conexión'
        : connected == false
            ? 'Sin conexión'
            : syncing
                ? 'Actualizando'
                : failed
                    ? 'Pendiente'
                    : currentLocation == '/'
                        ? 'Al día'
                        : 'En línea';
    final syncIcon = connected == null
        ? Icons.cloud_sync_outlined
        : connected == false
            ? Icons.cloud_off_outlined
            : syncing
                ? Icons.sync
                : failed
                    ? Icons.cloud_sync_outlined
                    : Icons.cloud_done_outlined;
    final syncColor = connected == false || failed
        ? AppTheme.earth
        : connected == null
            ? AppTheme.mutedText
            : AppTheme.forest;
    final displayName = user?.fullName.trim().isNotEmpty == true
        ? user!.fullName.trim()
        : 'Mi cuenta';
    final avatarLetter = displayName == 'Mi cuenta'
        ? '?'
        : displayName.characters.first.toUpperCase();

    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      if (width < 600) {
        return Scaffold(
          appBar: AppBar(
            elevation: 0,
            scrolledUnderElevation: 0,
            centerTitle: false,
            toolbarHeight: 61,
            backgroundColor: const Color(0xFFFDFBF3),
            bottom: const PreferredSize(
              preferredSize: Size.fromHeight(1),
              child: Divider(height: 1, thickness: 1, color: AppTheme.outline),
            ),
            title: Row(
              children: [
                SvgPicture.asset(
                  'assets/branding/tracop-logo-horizontal-fondo-crema.svg',
                  width: 112,
                  height: 34,
                  fit: BoxFit.contain,
                  semanticsLabel: 'TRACOP Agro',
                ),
              ],
            ),
            actions: [
              Tooltip(
                message: syncLabel,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(syncIcon, color: syncColor, size: 22),
                ),
              ),
              Tooltip(
                message: 'Perfil: $displayName',
                child: InkWell(
                  onTap: () => context.go('/perfil'),
                  borderRadius: BorderRadius.circular(24),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: CircleAvatar(
                      radius: 17,
                      backgroundColor: AppTheme.mint,
                      foregroundColor: AppTheme.forest,
                      child: Text(
                        avatarLetter,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: SafeArea(top: false, child: child),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) =>
                context.go(_destinations[index].path),
            destinations: [
              for (final item in _destinations)
                NavigationDestination(icon: Icon(item.icon), label: item.label)
            ],
          ),
        );
      }

      final expanded = width > 1024;
      return Scaffold(
        body: Row(children: [
          NavigationRail(
            extended: expanded,
            minExtendedWidth: 224,
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) =>
                context.go(_destinations[index].path),
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: expanded
                  ? SvgPicture.asset(
                      'assets/branding/tracop-logo-horizontal-fondo-crema.svg',
                      width: 164,
                      height: 42,
                      fit: BoxFit.contain,
                      semanticsLabel: 'TRACOP Agro',
                    )
                  : SvgPicture.asset(
                      'assets/branding/tracop-isotipo.svg',
                      width: 34,
                      height: 34,
                      semanticsLabel: 'Isotipo TRACOP',
                    ),
            ),
            destinations: [
              for (final item in _destinations)
                NavigationRailDestination(
                    icon: Icon(item.icon), label: Text(item.label))
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(
              child: Column(children: [
            Container(
              height: 68,
              decoration: const BoxDecoration(
                color: Color(0xFFFDFBF3),
                border: Border(bottom: BorderSide(color: AppTheme.outline)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Row(children: [
                Text(
                  currentLocation == '/' ? 'Inicio' : 'TRACOP Agro',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                _SyncBadge(label: syncLabel, icon: syncIcon, color: syncColor),
                const SizedBox(width: 18),
                InkWell(
                  onTap: () => context.go('/perfil'),
                  borderRadius: BorderRadius.circular(22),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    child: Row(children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppTheme.mint,
                        foregroundColor: AppTheme.forest,
                        child: Text(avatarLetter,
                            style:
                                const TextStyle(fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(width: 10),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 168),
                        child: Text(displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium),
                      ),
                    ]),
                  ),
                ),
              ]),
            ),
            Expanded(
                child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1440),
                  child: child),
            )),
          ])),
        ]),
      );
    });
  }
}

class _SyncBadge extends StatelessWidget {
  const _SyncBadge({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: label,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 20, color: color),
        ),
      );
}

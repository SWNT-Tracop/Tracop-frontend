import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../core/i18n/strings.dart';
import '../features/home/presentation/home_screen.dart';
import 'back_guard.dart';
import 'messenger.dart';
import 'theme.dart';

class ResponsiveShell extends ConsumerWidget {
  const ResponsiveShell(
      {required this.currentLocation, required this.child, super.key});
  final String currentLocation;
  final Widget child;

  static const _logoAsset =
      'assets/branding/tracop-logo-horizontal-fondo-crema.svg';
  static const _isotypeAsset = 'assets/branding/tracop-isotipo.svg';
  static const _compactBreakpoint = 600.0;
  static const _expandedBreakpoint = 1024.0;

  static const _baseDestinations =
      <({String path, String label, IconData icon})>[
    (path: '/', label: NavStrings.home, icon: Icons.home_outlined),
    (path: '/buscar', label: NavStrings.search, icon: Icons.search),
    (
      path: '/lotes',
      label: NavStrings.myLots,
      icon: Icons.inventory_2_outlined
    ),
    (path: '/perfil', label: NavStrings.profile, icon: Icons.person_outline),
  ];

  List<({String path, String label, IconData icon})> _destinationsFor(
          String? role) =>
      [
        ..._baseDestinations.take(2),
        if (role == 'buyer')
          (
            path: '/pedidos/mis-pedidos',
            label: 'Pedidos',
            icon: Icons.receipt_long_outlined
          ),
        if (role == 'supplier')
          (
            path: '/pedidos/entrantes',
            label: 'Pedidos',
            icon: Icons.inbox_outlined
          ),
        ..._baseDestinations.skip(2),
      ];

  void _onConnectivityChange(
      AsyncValue<bool>? previous, AsyncValue<bool> next) {
    final before = previous?.valueOrNull, now = next.valueOrNull;
    if (before == null || now == null || before == now) return;
    showAppNotice(now ? SyncStrings.backOnline : SyncStrings.lostConnection,
        icon: now ? Icons.cloud_done_outlined : Icons.cloud_off_outlined);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(homeConnectivityProvider, _onConnectivityChange);
    final user = ref.watch(homeUserProvider).valueOrNull;
    final role = user?.role;
    final destinations = _destinationsFor(role);
    final connectivity = ref.watch(homeConnectivityProvider);
    final lots = currentLocation == '/' ? ref.watch(homeLotsProvider) : null;
    final connected = connectivity.valueOrNull;
    final syncing = lots?.isLoading ?? false;
    final failed = lots?.hasError ?? false;
    final syncLabel = connected == null
        ? SyncStrings.checking
        : connected == false
            ? SyncStrings.offline
            : syncing
                ? SyncStrings.updating
                : failed
                    ? SyncStrings.failed
                    : currentLocation == '/'
                        ? SyncStrings.upToDate
                        : SyncStrings.online;
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
    final hasName = user?.fullName.trim().isNotEmpty == true;
    final displayName = hasName ? user!.fullName.trim() : NavStrings.myAccount;
    final avatarLetter =
        hasName ? displayName.characters.first.toUpperCase() : '?';
    final selectedIndex = currentLocation.startsWith('/lots/')
        ? 1
        : currentLocation.startsWith('/pedidos/')
            ? destinations
                .indexWhere((item) => item.path.startsWith('/pedidos/'))
            : destinations.indexWhere((item) =>
                currentLocation == item.path ||
                currentLocation.startsWith('${item.path}/'));
    final selected = selectedIndex < 0 ? 0 : selectedIndex;
    final sectionTitle = destinations[selected].label;
    final router = GoRouter.maybeOf(context);
    final backTarget = router == null || currentLocation == '/'
        ? null
        : destinations[selected].path == currentLocation
            ? '/'
            : destinations[selected].path;

    return PopScope(
      canPop: backTarget == null || router!.canPop(),
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop || backTarget == null) return;
        await _guardedGo(context, backTarget);
      },
      child: LayoutBuilder(builder: (context, constraints) {
        final width = constraints.maxWidth;
        if (width < _compactBreakpoint) {
          return Scaffold(
            appBar: AppBar(
              elevation: 0,
              scrolledUnderElevation: 0,
              centerTitle: false,
              toolbarHeight: 61,
              backgroundColor: AppTheme.headerSurface,
              bottom: const PreferredSize(
                preferredSize: Size.fromHeight(1),
                child:
                    Divider(height: 1, thickness: 1, color: AppTheme.outline),
              ),
              title: Row(
                children: [
                  SvgPicture.asset(
                    _logoAsset,
                    width: 112,
                    height: 34,
                    fit: BoxFit.contain,
                    semanticsLabel: NavStrings.brandLogoLabel,
                  ),
                ],
              ),
              actions: [
                Tooltip(
                  message: syncLabel,
                  child: Semantics(
                    label: syncLabel,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(syncIcon, color: syncColor, size: 22),
                    ),
                  ),
                ),
                Tooltip(
                  message: NavStrings.profileTooltip(displayName),
                  child: InkWell(
                    onTap: () => _guardedGo(context, '/perfil'),
                    borderRadius: BorderRadius.circular(24),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 8),
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
              selectedIndex: selected,
              onDestinationSelected: (index) =>
                  _guardedGo(context, destinations[index].path),
              destinations: [
                for (final item in destinations)
                  NavigationDestination(
                      icon: Icon(item.icon), label: item.label)
              ],
            ),
          );
        }

        final expanded = width > _expandedBreakpoint;
        return Scaffold(
          body: Row(children: [
            NavigationRail(
              extended: expanded,
              minExtendedWidth: 224,
              selectedIndex: selected,
              onDestinationSelected: (index) =>
                  _guardedGo(context, destinations[index].path),
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: expanded
                    ? SvgPicture.asset(
                        _logoAsset,
                        width: 164,
                        height: 42,
                        fit: BoxFit.contain,
                        semanticsLabel: NavStrings.brandLogoLabel,
                      )
                    : SvgPicture.asset(
                        _isotypeAsset,
                        width: 34,
                        height: 34,
                        semanticsLabel: NavStrings.brandIsotypeLabel,
                      ),
              ),
              destinations: [
                for (final item in destinations)
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
                  color: AppTheme.headerSurface,
                  border: Border(bottom: BorderSide(color: AppTheme.outline)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Row(children: [
                  Text(
                    sectionTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Spacer(),
                  _SyncBadge(
                      label: syncLabel, icon: syncIcon, color: syncColor),
                  const SizedBox(width: 18),
                  InkWell(
                    onTap: () => _guardedGo(context, '/perfil'),
                    borderRadius: BorderRadius.circular(22),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 4),
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
      }),
    );
  }
}

// En escritorio el estado se ve con texto, no solo con el icono.
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
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(8),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: color, fontSize: 14)),
        ]),
      );
}

// Navega desde el shell respetando el aviso de cambios sin guardar.
Future<void> _guardedGo(BuildContext context, String path) async {
  final guard = backGuard.value;
  if (guard != null && !await guard()) return;
  if (context.mounted) context.go(path);
}

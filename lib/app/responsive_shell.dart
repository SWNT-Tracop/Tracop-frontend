import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../core/i18n/strings.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/notifications/presentation/notifications_provider.dart';
import '../features/payments/domain/payment_permissions.dart';
import 'back_guard.dart';
import 'messenger.dart';
import 'theme.dart';

class ResponsiveShell extends ConsumerWidget {
  const ResponsiveShell(
      {required this.currentLocation,
      required this.child,
      this.origin,
      super.key});
  final String currentLocation;

  /// Sección desde la que se abrió la ruta (`?desde=liquidaciones`).
  final String? origin;
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

  /// Personal TRACOP (finance, operator, admin): resumen, revisión y
  /// liquidaciones. Sin "Inicio": para el personal, `/` redirige al resumen.
  static const _staffDestinations =
      <({String path, String label, IconData icon})>[
    (
      path: '/pagos/resumen',
      label: NavStrings.paymentsSummary,
      icon: Icons.space_dashboard_outlined
    ),
    (
      path: '/pagos/revision',
      label: NavStrings.paymentsReview,
      icon: Icons.fact_check_outlined
    ),
    (
      path: '/pagos/liquidaciones',
      label: NavStrings.settlements,
      icon: Icons.payments_outlined
    ),
    (path: '/perfil', label: NavStrings.profile, icon: Icons.person_outline),
  ];

  /// Destino activo dentro de /pagos/: coincidencia exacta o, para el
  /// detalle `/pagos/:id`, liquidaciones si se abrió desde ahí
  /// (`?desde=liquidaciones`) y si no la revisión.
  static int _paymentsIndex(
          List<({String path, String label, IconData icon})> destinations,
          String location,
          String? origin) =>
      switch (destinations.indexWhere((item) => item.path == location)) {
        -1 => destinations.indexWhere((item) =>
            item.path ==
            (origin == 'liquidaciones'
                ? '/pagos/liquidaciones'
                : '/pagos/revision')),
        final index => index,
      };

  List<({String path, String label, IconData icon})> _destinationsFor(
          String? role) =>
      PaymentPermissions.isStaff(role)
          ? [
              ..._staffDestinations.take(3),
              const (
                path: '/backoffice/resumen',
                label: 'Operación',
                icon: Icons.dashboard_outlined
              ),
              const (
                path: '/backoffice/verificaciones',
                label: 'Confianza',
                icon: Icons.verified_user_outlined
              ),
              const (
                path: '/backoffice/catalogo',
                label: 'Catálogo',
                icon: Icons.category_outlined
              ),
              _staffDestinations[3],
            ]
          : role == 'carrier'
              ? const [
                  (
                    path: '/logistica',
                    label: 'Logística',
                    icon: Icons.local_shipping_outlined
                  ),
                  (
                    path: '/perfil',
                    label: NavStrings.profile,
                    icon: Icons.person_outline
                  ),
                ]
              : [
                  ..._baseDestinations.take(2),
                  if (role == 'buyer')
                    (
                      path: '/pedidos/mis-pedidos',
                      label: 'Pedidos',
                      icon: Icons.receipt_long_outlined
                    ),
                  if (role == 'producer' || role == 'supplier')
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

  Future<void> _showConnectivityDetails(
      BuildContext context, bool? connected) async {
    final isConnected = connected == true;
    final title = connected == null
        ? SyncStrings.checking
        : isConnected
            ? SyncStrings.connectedToInternet
            : SyncStrings.noInternetConnection;
    final body = connected == null
        ? 'Estamos verificando el acceso a internet.'
        : isConnected
            ? 'Tu dispositivo puede comunicarse con TRACOP.'
            : SyncStrings.connectionDialogHint;
    final icon = connected == null
        ? Icons.cloud_sync_outlined
        : isConnected
            ? Icons.cloud_done_outlined
            : Icons.cloud_off_outlined;
    final color = connected == true ? AppTheme.forest : AppTheme.earth;
    final content = _ConnectivityMessage(
      title: title,
      body: body,
      icon: icon,
      color: color,
    );
    if (MediaQuery.sizeOf(context).width < _compactBreakpoint) {
      await showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (_) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                content,
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      context.push('/sincronizacion');
                    },
                    icon: const Icon(Icons.sync),
                    label: const Text(SyncStrings.syncCenter),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          content: content,
          actions: [
            TextButton.icon(
              onPressed: () {
                Navigator.pop(context);
                context.push('/sincronizacion');
              },
              icon: const Icon(Icons.sync),
              label: const Text(SyncStrings.syncCenter),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(SyncStrings.connectionDialogAction),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _showStaffMenu(BuildContext context, String? role) async {
    if (!PaymentPermissions.isStaff(role)) return;
    final destination = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Wrap(children: [
          const ListTile(
            title: Text('Más herramientas'),
            subtitle: Text('Accesos administrativos'),
          ),
          ListTile(
            leading: const Icon(Icons.local_shipping_outlined),
            title: const Text('Logística'),
            onTap: () => Navigator.pop(sheetContext, '/backoffice/logistica'),
          ),
          ListTile(
            leading: const Icon(Icons.fact_check_outlined),
            title: const Text('Propuestas'),
            onTap: () => Navigator.pop(sheetContext, '/backoffice/propuestas'),
          ),
          ListTile(
            leading: const Icon(Icons.tune_outlined),
            title: const Text('Parámetros'),
            onTap: () => Navigator.pop(sheetContext, '/backoffice/parametros'),
          ),
          if (role == 'admin')
            ListTile(
              leading: const Icon(Icons.history_outlined),
              title: const Text('Auditoría'),
              onTap: () => Navigator.pop(sheetContext, '/backoffice/auditoria'),
            ),
        ]),
      ),
    );
    if (destination != null && context.mounted) {
      await _guardedGo(context, destination);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(homeConnectivityProvider, _onConnectivityChange);
    final user = ref.watch(homeUserProvider).valueOrNull;
    final unreadNotifications = ref.watch(notificationsProvider).maybeWhen(
          data: (items) => items.where((item) => item.readAt == null).length,
          orElse: () => 0,
        );
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
            : currentLocation.startsWith('/pagos/')
                ? _paymentsIndex(destinations, currentLocation, origin)
                : destinations.indexWhere((item) =>
                    currentLocation == item.path ||
                    currentLocation.startsWith('${item.path}/'));
    final selected = selectedIndex < 0 ? 0 : selectedIndex;
    final sectionTitle = destinations[selected].label;
    final router = GoRouter.maybeOf(context);
    // El primer destino es el inicio de cada rol ('/' o '/pagos/resumen').
    final home = destinations.first.path;
    final backTarget =
        router == null || currentLocation == '/' || currentLocation == home
            ? null
            : destinations[selected].path == currentLocation
                ? home
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
                  child: InkWell(
                    onTap: () => _showConnectivityDetails(context, connected),
                    borderRadius: BorderRadius.circular(24),
                    child: Semantics(
                      label: syncLabel,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(syncIcon, color: syncColor, size: 22),
                      ),
                    ),
                  ),
                ),
                Tooltip(
                  message: 'Notificaciones',
                  child: InkWell(
                    onTap: () => _guardedGo(context, '/notificaciones'),
                    borderRadius: BorderRadius.circular(24),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: _NotificationIcon(count: unreadNotifications),
                    ),
                  ),
                ),
                if (PaymentPermissions.isStaff(role))
                  IconButton(
                    tooltip: 'Más herramientas',
                    onPressed: () => _showStaffMenu(context, role),
                    icon: const Icon(Icons.more_horiz),
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
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(children: [
                  Expanded(
                    child: Text(
                      sectionTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  _SyncBadge(
                      label: syncLabel,
                      icon: syncIcon,
                      color: syncColor,
                      compact: width < 800,
                      onTap: () =>
                          _showConnectivityDetails(context, connected)),
                  const SizedBox(width: 18),
                  Tooltip(
                    message: 'Notificaciones',
                    child: InkWell(
                      onTap: () => _guardedGo(context, '/notificaciones'),
                      borderRadius: BorderRadius.circular(24),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: _NotificationIcon(count: unreadNotifications),
                      ),
                    ),
                  ),
                  if (PaymentPermissions.isStaff(role))
                    IconButton(
                      tooltip: 'Más herramientas',
                      onPressed: () => _showStaffMenu(context, role),
                      icon: const Icon(Icons.more_horiz),
                    ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: InkWell(
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
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700)),
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleMedium),
                          ),
                        ]),
                      ),
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

class _NotificationIcon extends StatelessWidget {
  const _NotificationIcon({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) => Badge(
        isLabelVisible: count > 0,
        label: Text(count > 99 ? '99+' : '$count'),
        child: const Icon(Icons.notifications_none_outlined, size: 22),
      );
}

// En escritorio el estado se ve con texto, no solo con el icono.
class _SyncBadge extends StatelessWidget {
  const _SyncBadge({
    required this.label,
    required this.icon,
    required this.color,
    this.compact = false,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 20, color: color),
            if (!compact) ...[
              const SizedBox(width: 8),
              Text(label,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: color, fontSize: 14)),
            ],
          ]),
        ),
      );
}

class _ConnectivityMessage extends StatelessWidget {
  const _ConnectivityMessage({
    required this.title,
    required this.body,
    required this.icon,
    required this.color,
  });

  final String title;
  final String body;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(width: 12),
            Expanded(
              child: Text(title, style: Theme.of(context).textTheme.titleLarge),
            ),
          ]),
          const SizedBox(height: 12),
          Text(body, style: Theme.of(context).textTheme.bodyMedium),
        ],
      );
}

// Navega desde el shell respetando el aviso de cambios sin guardar.
Future<void> _guardedGo(BuildContext context, String path) async {
  final guard = backGuard.value;
  if (guard != null && !await guard()) return;
  if (context.mounted) context.go(path);
}

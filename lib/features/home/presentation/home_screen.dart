import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../auth/domain/entities/user.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../catalog/domain/entities/lot.dart' hide Category, Product;
import '../../catalog/presentation/providers/catalog_provider.dart';

const _isotypePath = 'assets/branding/tracop-isotipo.svg';
const _harvestPhotoPath = 'assets/images/campesino-cosecha.jpg';

final homeLotsCacheProvider = StateProvider<List<Lot>?>((ref) => null);
final homePhotoAvailableProvider = FutureProvider<bool>((ref) async {
  final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
  return manifest.listAssets().contains(_harvestPhotoPath);
});

final homeUserProvider = FutureProvider<User?>((ref) async {
  final result = await ref.read(authRepositoryProvider).getStoredUser();
  return result.map(ok: (value) => value.value, err: (_) => null);
});

final homeLotsProvider = FutureProvider<List<Lot>>((ref) async {
  final result = await ref.read(catalogRepositoryProvider).getMyLots();
  return result.map(
    ok: (value) {
      ref.read(homeLotsCacheProvider.notifier).state = value.value;
      return value.value;
    },
    err: (failure) => throw failure,
  );
});

final homeConnectivityProvider = StreamProvider<bool>((ref) async* {
  final connectivity = Connectivity();
  bool isConnected(List<ConnectivityResult> results) =>
      results.any((result) => result != ConnectivityResult.none);

  yield isConnected(await connectivity.checkConnectivity());
  yield* connectivity.onConnectivityChanged.map(isConnected);
});

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(homeUserProvider).valueOrNull;
    final lots = ref.watch(homeLotsProvider);
    final cachedLots = ref.watch(homeLotsCacheProvider);
    final connectivity = ref.watch(homeConnectivityProvider);
    final photoAvailable =
        ref.watch(homePhotoAvailableProvider).valueOrNull ?? false;
    final greeting = _greeting(DateTime.now(), user?.fullName);

    return LayoutBuilder(
      builder: (context, viewport) {
        final wide = viewport.maxWidth >= 960;
        final heroWide = viewport.maxWidth >= 700;
        final content = Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1320),
            child: Padding(
              padding: EdgeInsets.fromLTRB(wide ? 48 : 20, wide ? 36 : 24,
                  wide ? 48 : 20, wide ? 48 : 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _WelcomePanel(
                    greeting: greeting,
                    wide: heroWide,
                    onExplore: () => context.go('/buscar'),
                    photoAvailable: photoAvailable,
                  ),
                  const SizedBox(height: 20),
                  _ConnectionBanner(
                    connectivity: connectivity,
                    lots: lots,
                    onRetry: () => ref.invalidate(homeLotsProvider),
                  ),
                  const SizedBox(height: 30),
                  if (wide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 11,
                          child: _DailySummary(
                            lots: lots,
                            cachedLots: cachedLots,
                          ),
                        ),
                        const SizedBox(width: 24),
                        const Expanded(flex: 9, child: _QuickTasks()),
                      ],
                    )
                  else ...[
                    _DailySummary(
                      lots: lots,
                      cachedLots: cachedLots,
                    ),
                    const SizedBox(height: 26),
                    const _QuickTasks(),
                  ],
                ],
              ),
            ),
          ),
        );

        return Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppTheme.background, Color(0xFFF0F6EB)],
                  ),
                ),
                child: CustomPaint(painter: _FieldWashPainter()),
              ),
            ),
            SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: content,
            ),
          ],
        );
      },
    );
  }
}

String _greeting(DateTime now, String? fullName) {
  final hour = now.hour;
  final salutation = hour >= 5 && hour < 12
      ? 'Buenos días'
      : hour >= 12 && hour < 19
          ? 'Buenas tardes'
          : 'Buenas noches';
  final firstName = fullName?.trim().split(RegExp(r'\s+')).firstOrNull;
  return firstName == null || firstName.isEmpty
      ? '$salutation. ¿Qué vamos a mover hoy?'
      : '$salutation, $firstName. ¿Qué vamos a mover hoy?';
}

class _WelcomePanel extends StatelessWidget {
  const _WelcomePanel({
    required this.greeting,
    required this.wide,
    required this.onExplore,
    required this.photoAvailable,
  });

  final String greeting;
  final bool wide;
  final VoidCallback onExplore;
  final bool photoAvailable;

  @override
  Widget build(BuildContext context) {
    final art = ClipPath(
      clipper: const _LeafPhotoClipper(),
      child: AspectRatio(
        aspectRatio: wide ? 1.78 : 2.8,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (photoAvailable)
              Image.asset(
                _harvestPhotoPath,
                fit: BoxFit.cover,
                alignment: const Alignment(0.62, 0),
              )
            else
              const _PhotoAwaitingAsset(),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Color(0xDDE8F5E9), Color(0x00E8F5E9)],
                  stops: [0, .82],
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFCF4), Color(0xFFF0F5E7)],
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(56),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: wide ? 20 : 12,
            top: 12,
            child: IgnorePointer(
              child: Opacity(
                opacity: .07,
                child: SvgPicture.asset(
                  _isotypePath,
                  width: wide ? 148 : 112,
                  height: wide ? 126 : 96,
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(wide ? 28 : 20),
            child: wide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 11,
                        child: _welcomeCopy(context),
                      ),
                      const SizedBox(width: 28),
                      Expanded(flex: 9, child: art),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _welcomeCopy(context),
                      const SizedBox(height: 18),
                      SizedBox(width: double.infinity, child: art),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _welcomeCopy(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(
            greeting,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppTheme.forest,
                  fontSize: wide ? 29 : 25,
                  height: 1.18,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            'De la finca al mercado, paso a paso.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.mutedText,
                ),
          ),
          const SizedBox(height: 20),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton.icon(
                onPressed: onExplore,
                icon: const Icon(Icons.storefront_outlined),
                label: const Text('Explorar lotes'),
                style: FilledButton.styleFrom(
                  elevation: 1,
                  shadowColor: AppTheme.forest.withValues(alpha: .16),
                ),
              ),
            ),
          ),
        ],
      );
}

class _LeafPhotoClipper extends CustomClipper<Path> {
  const _LeafPhotoClipper();

  @override
  Path getClip(Size size) {
    final path = Path()
      ..moveTo(0, 28)
      ..quadraticBezierTo(0, 0, 30, 0)
      ..lineTo(size.width - 42, 0)
      ..cubicTo(size.width - 10, 0, size.width, 12, size.width, 42)
      ..lineTo(size.width, size.height - 44)
      ..cubicTo(size.width, size.height - 12, size.width - 18, size.height,
          size.width - 50, size.height)
      ..cubicTo(size.width * .68, size.height * .94, size.width * .42,
          size.height * 1.04, size.width * .2, size.height)
      ..lineTo(32, size.height)
      ..quadraticBezierTo(0, size.height, 0, size.height - 32)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _PhotoAwaitingAsset extends StatelessWidget {
  const _PhotoAwaitingAsset();

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE8F5E9), Color(0xFFE4D6C6)],
          ),
        ),
        child: Center(
          child: SvgPicture.asset(
            _isotypePath,
            width: 84,
            height: 72,
            semanticsLabel: 'Cosecha TRACOP',
          ),
        ),
      );
}

class _ConnectionBanner extends StatelessWidget {
  const _ConnectionBanner({
    required this.connectivity,
    required this.lots,
    required this.onRetry,
  });

  final AsyncValue<bool> connectivity;
  final AsyncValue<List<Lot>> lots;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    final bool? connected = connectivity.valueOrNull;
    final isLoading = connected == true && lots.isLoading;
    final failed = connected == true && lots.hasError;
    final offline = connected == false;
    final statusColor = offline || failed ? AppTheme.earth : AppTheme.forest;
    final title = offline
        ? 'Sin conexión'
        : failed
            ? 'No pudimos actualizar tus lotes'
            : isLoading
                ? 'Revisando tus lotes'
                : connected == true
                    ? 'Conexión disponible'
                    : 'Revisando conexión';
    final detail = offline
        ? 'Volvemos a actualizar cuando regrese la señal.'
        : failed
            ? 'Revisa la señal y vuelve a intentarlo.'
            : isLoading
                ? 'Un momento, estamos alistando la jornada.'
                : connected == true
                    ? 'La conexión está lista para tus tareas.'
                    : 'Comprobando la señal de este dispositivo.';
    final statusCopy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: AppTheme.ink)),
        const SizedBox(height: 3),
        Text(detail,
            style:
                Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 14)),
      ],
    );
    final retryButton = OutlinedButton(
      onPressed: onRetry,
      child: const Text('Reintentar'),
    );

    return _RevealIn(
      child: Material(
        color: Colors.white.withValues(alpha: .88),
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 440) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        _SwayingLeaf(
                            color: statusColor, disabled: reducedMotion),
                        const SizedBox(width: 14),
                        Expanded(child: statusCopy),
                        if (isLoading) ...[
                          const SizedBox(width: 8),
                          const _LeafLoadingMark(size: 28),
                        ],
                      ],
                    ),
                    if ((failed || offline) && !isLoading) ...[
                      const SizedBox(height: 8),
                      Align(
                          alignment: Alignment.centerRight, child: retryButton),
                    ],
                  ],
                );
              }

              return Row(
                children: [
                  _SwayingLeaf(color: statusColor, disabled: reducedMotion),
                  const SizedBox(width: 14),
                  Expanded(child: statusCopy),
                  if (isLoading) ...[
                    const SizedBox(width: 8),
                    const _LeafLoadingMark(size: 32),
                  ] else if (failed || offline)
                    retryButton,
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _DailySummary extends StatelessWidget {
  const _DailySummary({required this.lots, required this.cachedLots});

  final AsyncValue<List<Lot>> lots;
  final List<Lot>? cachedLots;

  @override
  Widget build(BuildContext context) {
    final items = lots.valueOrNull ?? cachedLots;
    final isLoading = lots.isLoading && items == null;
    final published =
        items?.where((lot) => lot.status == 'published').length ?? 0;
    final drafts = items?.where((lot) => lot.status == 'draft').length ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeading(title: 'Tu movimiento'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.spa_outlined,
                value: items == null ? '—' : '$published',
                label: 'Lotes publicados',
                detail: items == null ? null : 'Visibles para compradores',
                tint: const Color(0xFFE8F5E9),
                loading: isLoading,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.inventory_2_outlined,
                value: items == null ? '—' : '$drafts',
                label: 'Borradores',
                detail: items == null ? null : 'Por completar o publicar',
                tint: const Color(0xFFF2E9DF),
                loading: isLoading,
              ),
            ),
          ],
        ),
        if (!isLoading && items != null && published == 0) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .74),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                SvgPicture.asset(_isotypePath, width: 32, height: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Aún no tienes lotes publicados. ¡Publica el primero!',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 14,
                          color: AppTheme.ink,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.detail,
    required this.tint,
    required this.loading,
  });

  final IconData icon;
  final String value;
  final String label;
  final String? detail;
  final Color tint;
  final bool loading;

  @override
  Widget build(BuildContext context) => _RevealIn(
        child: Container(
          constraints: const BoxConstraints(minHeight: 154),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .94),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(42),
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.forest.withValues(alpha: .07),
                blurRadius: 22,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
                child: Icon(icon, color: AppTheme.forest, size: 22),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (loading)
                    const _SkeletonBlock(width: 42, height: 30)
                  else
                    Text(value,
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                          color: AppTheme.ink,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        )),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(label,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontSize: 15)),
                    ),
                  ),
                ],
              ),
              if (detail != null) ...[
                const SizedBox(height: 3),
                Text(detail!,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontSize: 13)),
              ],
            ],
          ),
        ),
      );
}

class _SkeletonBlock extends StatelessWidget {
  const _SkeletonBlock({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFFE8ECE5),
          borderRadius: BorderRadius.circular(10),
        ),
      );
}

class _QuickTasks extends StatelessWidget {
  const _QuickTasks();

  static const tasks =
      <({IconData icon, String title, String subtitle, String path})>[
    (
      icon: Icons.inventory_2_outlined,
      title: 'Mis lotes',
      subtitle: 'Revisa lo que tienes en camino',
      path: '/lotes',
    ),
    (
      icon: Icons.search,
      title: 'Buscar productos',
      subtitle: 'Encuentra lo que hace falta',
      path: '/buscar',
    ),
    (
      icon: Icons.person_outline,
      title: 'Mi perfil',
      subtitle: 'Mantén tus datos al día',
      path: '/perfil',
    ),
  ];

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeading(title: 'A mano'),
          const SizedBox(height: 12),
          for (final task in tasks) ...[
            _QuickTaskCard(
              icon: task.icon,
              title: task.title,
              subtitle: task.subtitle,
              path: task.path,
            ),
            if (task != tasks.last) const SizedBox(height: 10),
          ],
        ],
      );
}

class _QuickTaskCard extends StatelessWidget {
  const _QuickTaskCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.path,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String path;

  @override
  Widget build(BuildContext context) => _RevealIn(
        child: Material(
          color: Colors.white.withValues(alpha: .94),
          borderRadius: BorderRadius.circular(22),
          child: InkWell(
            onTap: () => context.go(path),
            borderRadius: BorderRadius.circular(22),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: const BoxDecoration(
                      color: AppTheme.mint,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: AppTheme.forest),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 2),
                        Text(subtitle,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(fontSize: 14)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppTheme.mutedText),
                ],
              ),
            ),
          ),
        ),
      );
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: Text(title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.ink,
                      fontWeight: FontWeight.w700,
                    )),
          ),
        ],
      );
}

class _SwayingLeaf extends StatefulWidget {
  const _SwayingLeaf({required this.color, required this.disabled});

  final Color color;
  final bool disabled;

  @override
  State<_SwayingLeaf> createState() => _SwayingLeafState();
}

class _SwayingLeafState extends State<_SwayingLeaf> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedRotation(
          turns: widget.disabled || !_hovered ? 0 : .018,
          duration: widget.disabled
              ? Duration.zero
              : const Duration(milliseconds: 240),
          curve: Curves.fastOutSlowIn,
          child: SvgPicture.asset(
            _isotypePath,
            width: 36,
            height: 36,
            colorFilter: ColorFilter.mode(widget.color, BlendMode.srcIn),
          ),
        ),
      );
}

class _LeafLoadingMark extends StatelessWidget {
  const _LeafLoadingMark({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: reduceMotion ? 1 : 0, end: 1),
      duration:
          reduceMotion ? Duration.zero : const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
      builder: (context, progress, child) => ClipRect(
        child: Align(
          alignment: Alignment.centerLeft,
          widthFactor: progress,
          child: child,
        ),
      ),
      child: SvgPicture.asset(_isotypePath, width: size, height: size),
    );
  }
}

class _RevealIn extends StatefulWidget {
  const _RevealIn({required this.child});

  final Widget child;

  @override
  State<_RevealIn> createState() => _RevealInState();
}

class _RevealInState extends State<_RevealIn> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final disabled = MediaQuery.disableAnimationsOf(context);
    return AnimatedSlide(
      offset: _visible || disabled ? Offset.zero : const Offset(0, .035),
      duration: disabled ? Duration.zero : const Duration(milliseconds: 250),
      curve: Curves.fastOutSlowIn,
      child: AnimatedOpacity(
        opacity: _visible || disabled ? 1 : 0,
        duration: disabled ? Duration.zero : const Duration(milliseconds: 250),
        curve: Curves.fastOutSlowIn,
        child: widget.child,
      ),
    );
  }
}

class _FieldWashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppTheme.mint.withValues(alpha: .22);
    final path = Path()
      ..moveTo(size.width * .72, 0)
      ..cubicTo(size.width * .9, size.height * .18, size.width * .68,
          size.height * .35, size.width, size.height * .42)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);

    final lowerWash = Paint()..color = AppTheme.earth.withValues(alpha: .025);
    final lowerPath = Path()
      ..moveTo(0, size.height * .83)
      ..cubicTo(size.width * .22, size.height * .72, size.width * .38,
          size.height * .95, size.width * .6, size.height * .86)
      ..cubicTo(size.width * .78, size.height * .78, size.width * .9,
          size.height * .92, size.width, size.height * .82)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(lowerPath, lowerWash);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

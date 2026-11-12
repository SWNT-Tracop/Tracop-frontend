import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/theme.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../home/presentation/home_screen.dart';
import '../domain/entities/category.dart';
import '../domain/entities/lot.dart' hide Category, Product;
import '../domain/entities/product.dart';
import 'providers/catalog_provider.dart';

final searchCategoriesProvider = FutureProvider<List<Category>>((ref) async {
  final result = await ref.read(catalogRepositoryProvider).getCategories();
  return result.map(
      ok: (value) => value.value, err: (failure) => throw failure);
});
final searchProductsProvider = FutureProvider<List<Product>>((ref) async {
  final result = await ref.read(catalogRepositoryProvider).getProducts();
  return result.map(
      ok: (value) => value.value, err: (failure) => throw failure);
});

class CatalogSearchScreen extends ConsumerStatefulWidget {
  const CatalogSearchScreen({super.key});

  @override
  ConsumerState<CatalogSearchScreen> createState() =>
      _CatalogSearchScreenState();
}

class _CatalogSearchScreenState extends ConsumerState<CatalogSearchScreen> {
  final _searchController = TextEditingController();
  final _minController = TextEditingController();
  final _maxController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _debounce;
  String? _categoryId;
  String? _productId;
  String _sort = 'recent';
  DateTime? _availableFrom;
  DateTime? _availableUntil;
  String? _cursor;
  final List<Lot> _lots = [];
  final List<int> _pageStarts = [0];
  int _currentPage = 0;
  bool _loading = false;
  bool _loadingMore = false;
  bool _hasError = false;
  bool _hasMore = false;
  bool _initialized = false;
  String? _role;
  DateTime? _updatedAt;
  bool _servedFromCache = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final uri = GoRouterState.of(context).uri;
    final params = uri.queryParameters;
    _searchController.text = params['q'] ?? '';
    _categoryId = params['categoryId'];
    _productId = params['productId'];
    _minController.text = params['minPrice'] ?? '';
    _maxController.text = params['maxPrice'] ?? '';
    final authenticatedRole = ref.read(homeUserProvider).valueOrNull?.role ??
        ref.read(authProvider).valueOrNull?.user.role;
    _sort =
        params['sort'] ?? (authenticatedRole == 'buyer' ? 'price' : 'recent');
    _availableFrom = DateTime.tryParse(params['availableFrom'] ?? '');
    _availableUntil = DateTime.tryParse(params['availableUntil'] ?? '');
    WidgetsBinding.instance.addPostFrameCallback((_) => _load(reset: true));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _minController.dispose();
    _maxController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  bool get _hasFilters =>
      _categoryId != null ||
      _productId != null ||
      _minController.text.isNotEmpty ||
      _maxController.text.isNotEmpty ||
      _availableFrom != null ||
      _availableUntil != null;

  Map<String, dynamic> get _query => {
        'limit': 20,
        'sort': _sort,
        if (_searchController.text.trim().isNotEmpty)
          'q': _searchController.text.trim(),
        if (_categoryId != null) 'categoryId': _categoryId,
        if (_productId != null) 'productId': _productId,
        if (int.tryParse(_minController.text) != null)
          'minPrice': int.parse(_minController.text),
        if (int.tryParse(_maxController.text) != null)
          'maxPrice': int.parse(_maxController.text),
        if (_availableFrom != null)
          'availableFrom': _availableFrom!.toUtc().toIso8601String(),
        if (_availableUntil != null)
          'availableUntil': _availableUntil!.toUtc().toIso8601String(),
      };

  void _scheduleSearch() {
    _debounce?.cancel();
    _debounce =
        Timer(const Duration(milliseconds: 350), () => _load(reset: true));
  }

  void _syncUrl() {
    final params = Map<String, String>.fromEntries(_query.entries
        .where((entry) => entry.key != 'limit')
        .map((entry) => MapEntry(entry.key, '${entry.value}')));
    final uri =
        Uri(path: '/buscar', queryParameters: params.isEmpty ? null : params);
    if (GoRouterState.of(context).uri != uri) context.go(uri.toString());
  }

  Future<void> _load({required bool reset}) async {
    if (!mounted) return;
    if (reset) {
      setState(() {
        _loading = true;
        _loadingMore = false;
        _hasError = false;
        _lots.clear();
        _pageStarts
          ..clear()
          ..add(0);
        _currentPage = 0;
        _cursor = null;
      });
      _syncUrl();
    } else {
      setState(() => _loadingMore = true);
    }
    _role = ref.read(homeUserProvider).valueOrNull?.role ??
        ref.read(authProvider).valueOrNull?.user.role;
    final result = await ref.read(catalogRepositoryProvider).searchLots(
          cursor: reset ? null : _cursor,
          limit: 20,
          categoryId: _categoryId,
          productId: _productId,
          q: _searchController.text.trim().isEmpty
              ? null
              : _searchController.text.trim(),
          minPrice: int.tryParse(_minController.text),
          maxPrice: int.tryParse(_maxController.text),
          availableFrom: _availableFrom,
          availableUntil: _availableUntil,
          sort: _sort,
        );
    if (!mounted) return;
    result.map(
      ok: (response) => setState(() {
        final incomingIds = _lots.map((lot) => lot.id).toSet();
        final previousLength = _lots.length;
        _lots.addAll(
            response.value.items.where((lot) => incomingIds.add(lot.id)));
        if (!reset && _lots.length > previousLength) {
          _pageStarts.add(previousLength);
          _currentPage = _pageStarts.length - 1;
        }
        _cursor = response.value.nextCursor;
        _hasMore = _cursor != null;
        _updatedAt = response.value.cachedAt;
        _servedFromCache = response.value.isFromCache;
        _hasError = false;
      }),
      err: (_) => setState(() => _hasError = true),
    );
    setState(() {
      _loading = false;
      _loadingMore = false;
    });
  }

  Future<void> _openFilters({required bool compact}) async {
    final categories = await ref
        .read(searchCategoriesProvider.future)
        .catchError((_) => <Category>[]);
    final products = await ref
        .read(searchProductsProvider.future)
        .catchError((_) => <Product>[]);
    if (!mounted) return;
    final content = _FilterPanel(
      categories: categories,
      products: products,
      categoryId: _categoryId,
      productId: _productId,
      minController: _minController,
      maxController: _maxController,
      available: _availableFrom != null || _availableUntil != null,
      onCategory: (value) => _categoryId = value,
      onProduct: (value) => _productId = value,
      onAvailability: (value) {
        _availableFrom = value ? DateTime.now().toUtc() : null;
        _availableUntil =
            value ? DateTime.now().add(const Duration(days: 30)).toUtc() : null;
      },
    );
    if (compact) {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (context) => SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
                20, 8, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
            child: SingleChildScrollView(child: content),
          ),
        ),
      );
    } else {
      await showDialog<void>(
        context: context,
        builder: (context) => Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520, maxHeight: 680),
            child: SingleChildScrollView(
                padding: const EdgeInsets.all(24), child: content),
          ),
        ),
      );
    }
    if (mounted) _load(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(homeConnectivityProvider, (previous, next) {
      if (previous?.valueOrNull == false && next.valueOrNull == true) {
        _load(reset: true);
      }
    });
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    final categories =
        ref.watch(searchCategoriesProvider).valueOrNull ?? const <Category>[];
    final products =
        ref.watch(searchProductsProvider).valueOrNull ?? const <Product>[];
    final offline = ref.watch(homeConnectivityProvider).valueOrNull == false;
    final activeRole = ref.watch(homeUserProvider).valueOrNull?.role ??
        ref.watch(authProvider).valueOrNull?.user.role ??
        _role;
    final isBuyer = activeRole == 'buyer';
    final isCarrier = activeRole == 'carrier';
    final firstVisible = wide ? _pageStarts[_currentPage] : 0;
    final lastVisible = wide && _currentPage + 1 < _pageStarts.length
        ? _pageStarts[_currentPage + 1]
        : _lots.length;
    final visibleLots = _lots.sublist(firstVisible, lastVisible);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1120),
            child: CustomScrollView(
              key: const PageStorageKey('catalog-search-scroll'),
              controller: _scrollController,
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                      wide ? 40 : 20, 20, wide ? 40 : 20, 12),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Buscar lotes',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(
                                      color: AppTheme.forest,
                                      fontWeight: FontWeight.w700)),
                          const SizedBox(height: 16),
                          Row(children: [
                            Expanded(
                                child: Semantics(
                              label: 'Buscar productos o ubicación',
                              child: TextField(
                                controller: _searchController,
                                textInputAction: TextInputAction.search,
                                onChanged: (_) => _scheduleSearch(),
                                onSubmitted: (_) => _load(reset: true),
                                decoration: InputDecoration(
                                  hintText: 'Producto o ubicación',
                                  prefixIcon: const Icon(Icons.search),
                                  suffixIcon: _searchController.text.isEmpty
                                      ? null
                                      : IconButton(
                                          tooltip: 'Limpiar búsqueda',
                                          onPressed: () {
                                            _searchController.clear();
                                            _load(reset: true);
                                          },
                                          icon: const Icon(Icons.close),
                                        ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(
                                          color: AppTheme.outline)),
                                  enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(
                                          color: AppTheme.outline)),
                                ),
                              ),
                            )),
                            const SizedBox(width: 8),
                            IconButton.filledTonal(
                              tooltip: 'Abrir filtros',
                              onPressed: () => _openFilters(compact: !wide),
                              icon: const Icon(Icons.tune),
                              style: IconButton.styleFrom(
                                  minimumSize: const Size(52, 52)),
                            ),
                          ]),
                          const SizedBox(height: 12),
                          Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                Text('Ordenar:',
                                    style:
                                        Theme.of(context).textTheme.labelLarge),
                                DropdownButton<String>(
                                  value: _sort,
                                  underline: const SizedBox.shrink(),
                                  items: [
                                    DropdownMenuItem(
                                        value: 'recent',
                                        child: Text(isBuyer
                                            ? 'Más recientes'
                                            : 'Más recientes')),
                                    if (isBuyer)
                                      const DropdownMenuItem(
                                          value: 'price',
                                          child: Text('Menor precio')),
                                    const DropdownMenuItem(
                                        value: 'availability',
                                        child: Text('Disponibilidad')),
                                  ],
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() => _sort = value);
                                      _load(reset: true);
                                    }
                                  },
                                ),
                                if (_hasFilters)
                                  TextButton.icon(
                                    onPressed: _clearFilters,
                                    icon: const Icon(Icons.close, size: 18),
                                    label: const Text('Limpiar filtros'),
                                  ),
                              ]),
                          if (offline || _servedFromCache)
                            _OfflineCatalogNotice(
                              updatedAt: _updatedAt,
                              offline: offline,
                            ),
                          if (_activeChips(categories, products)
                              .isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: _activeChips(categories, products)),
                          ],
                          const SizedBox(height: 10),
                          if (activeRole == null)
                            const Text(
                                'No pudimos confirmar tu rol; mostramos la búsqueda general.'),
                          if (isCarrier)
                            const Text(
                                'Prioriza cantidad y ubicación para planear la recogida.',
                                style: TextStyle(color: AppTheme.mutedText)),
                        ]),
                  ),
                ),
                if (_loading && _lots.isEmpty)
                  SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverList.builder(
                          itemCount: 5,
                          itemBuilder: (_, __) => const _LotSkeleton())),
                if (_hasError && _lots.isEmpty)
                  SliverFillRemaining(
                      hasScrollBody: false,
                      child: _ErrorState(onRetry: () => _load(reset: true))),
                if (!_loading && !_hasError && _lots.isEmpty)
                  SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyState(
                          hasQuery:
                              _searchController.text.isNotEmpty || _hasFilters,
                          onClear: _clearFilters)),
                if (_lots.isNotEmpty) ...[
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                        wide ? 40 : 20, 8, wide ? 40 : 20, 8),
                    sliver: SliverToBoxAdapter(
                      child: Semantics(
                          liveRegion: true,
                          label: '${_lots.length} resultados cargados',
                          child: Text(
                              '${_lots.length} lotes cargados${_hasMore ? ' · hay más resultados' : ''}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: AppTheme.mutedText))),
                    ),
                  ),
                  if (wide)
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      sliver: SliverGrid.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                mainAxisExtent: 196),
                        itemCount: visibleLots.length,
                        itemBuilder: (context, index) => _buildCard(
                            context,
                            firstVisible + index,
                            reducedMotion,
                            isBuyer,
                            isCarrier),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverList.builder(
                          itemCount: _lots.length,
                          itemBuilder: (context, index) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildCard(context, index, reducedMotion,
                                  isBuyer, isCarrier))),
                    ),
                  if (_hasMore || (wide && _pageStarts.length > 1))
                    SliverToBoxAdapter(
                        child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                            child: wide
                                ? _WebPages(
                                    pageCount: _pageStarts.length,
                                    currentPage: _currentPage,
                                    hasMore: _hasMore,
                                    onSelect: (page) {
                                      if (page < _pageStarts.length) {
                                        setState(() => _currentPage = page);
                                      } else if (!_loadingMore) {
                                        _load(reset: false);
                                      }
                                    })
                                : FilledButton.tonal(
                                    onPressed: _loadingMore
                                        ? null
                                        : () => _load(reset: false),
                                    child: _loadingMore
                                        ? const SizedBox.square(
                                            dimension: 20,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2))
                                        : const Text('Cargar más')))),
                ],
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, int index, bool reducedMotion,
      bool isBuyer, bool isCarrier) {
    final lot = _lots[index];
    final product = ref
        .watch(searchProductsProvider)
        .valueOrNull
        ?.where((item) => item.id == lot.productId)
        .firstOrNull;
    final productName = product?.name ?? 'Producto agropecuario';
    final location = lot.provider == null
        ? 'Ubicación no informada'
        : '${lot.provider!.municipality}, ${lot.provider!.department}';
    final unitPrice = int.tryParse(lot.unitPrice) ?? 0;
    final price =
        NumberFormat.currency(locale: 'es_CO', symbol: r'$ ', decimalDigits: 0)
            .format(unitPrice);
    final qty = (int.tryParse(lot.quantityMilli) ?? 0) / 1000;
    final availability = lot.status == 'published' ? 'Disponible' : lot.status;
    final card = Card(
      margin: EdgeInsets.zero,
      color: Colors.white,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppTheme.outline)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/lots/${lot.id}',
            extra: {'from': GoRouterState.of(context).uri.toString()}),
        child: Padding(
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (lot.photos.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    height: 148,
                    width: double.infinity,
                    child: Image.network(
                      lot.photos.first.url,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppTheme.mint.withValues(alpha: 0.4),
                        alignment: Alignment.center,
                        child: const Icon(Icons.image_not_supported_outlined,
                            color: AppTheme.forest),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                    child: Text(productName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppTheme.ink))),
                if (isBuyer)
                  Text(price,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.forest, fontWeight: FontWeight.w700)),
              ]),
              const SizedBox(height: 8),
              Text('$qty ${lot.unit}',
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(children: [
                const Icon(Icons.event_available_outlined,
                    size: 18, color: AppTheme.primary),
                const SizedBox(width: 6),
                Expanded(
                    child: Text(
                        '$availability · hasta ${DateFormat('d MMM', 'es_CO').format(lot.availableUntil.toLocal())}',
                        style: const TextStyle(fontSize: 14)))
              ]),
              const SizedBox(height: 6),
              Row(children: [
                Icon(
                    isCarrier
                        ? Icons.local_shipping_outlined
                        : Icons.place_outlined,
                    size: 18,
                    color: AppTheme.mutedText),
                const SizedBox(width: 6),
                Expanded(
                    child: Text(location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 14, color: AppTheme.mutedText))),
                if (!isBuyer)
                  Text(price,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, color: AppTheme.forest))
              ]),
            ])),
      ),
    );
    if (reducedMotion || index >= 8) return card;
    return _StaggeredLotCard(
        key: ValueKey('lot-entry-${lot.id}'), index: index, child: card);
  }

  List<Widget> _activeChips(List<Category> categories, List<Product> products) {
    final chips = <Widget>[];
    final category =
        categories.where((item) => item.id == _categoryId).firstOrNull;
    final product = products.where((item) => item.id == _productId).firstOrNull;
    if (category != null) {
      chips.add(_FilterChip(
          label: category.name,
          onDeleted: () {
            setState(() => _categoryId = null);
            _load(reset: true);
          }));
    }
    if (product != null) {
      chips.add(_FilterChip(
          label: product.name,
          onDeleted: () {
            setState(() => _productId = null);
            _load(reset: true);
          }));
    }
    if (_minController.text.isNotEmpty || _maxController.text.isNotEmpty) {
      chips.add(_FilterChip(
          label:
              'Precio ${_minController.text.isEmpty ? '0' : _minController.text}–${_maxController.text.isEmpty ? '∞' : _maxController.text}',
          onDeleted: () {
            _minController.clear();
            _maxController.clear();
            _load(reset: true);
          }));
    }
    if (_availableFrom != null) {
      chips.add(_FilterChip(
          label: 'Disponible próximamente',
          onDeleted: () {
            _availableFrom = null;
            _availableUntil = null;
            _load(reset: true);
          }));
    }
    return chips;
  }

  void _clearFilters() {
    setState(() {
      _categoryId = null;
      _productId = null;
      _minController.clear();
      _maxController.clear();
      _availableFrom = null;
      _availableUntil = null;
    });
    _load(reset: true);
  }
}

class _StaggeredLotCard extends StatefulWidget {
  const _StaggeredLotCard(
      {required this.index, required this.child, super.key});
  final int index;
  final Widget child;

  @override
  State<_StaggeredLotCard> createState() => _StaggeredLotCardState();
}

class _StaggeredLotCardState extends State<_StaggeredLotCard> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(Duration(milliseconds: widget.index * 35), () {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  Widget build(BuildContext context) => AnimatedOpacity(
        opacity: _visible ? 1 : 0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        child: AnimatedSlide(
          offset: _visible ? Offset.zero : const Offset(0, .035),
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          child: widget.child,
        ),
      );
}

class _FilterPanel extends StatefulWidget {
  const _FilterPanel(
      {required this.categories,
      required this.products,
      required this.categoryId,
      required this.productId,
      required this.minController,
      required this.maxController,
      required this.available,
      required this.onCategory,
      required this.onProduct,
      required this.onAvailability});
  final List<Category> categories;
  final List<Product> products;
  final String? categoryId;
  final String? productId;
  final TextEditingController minController;
  final TextEditingController maxController;
  final bool available;
  final ValueChanged<String?> onCategory;
  final ValueChanged<String?> onProduct;
  final ValueChanged<bool> onAvailability;

  @override
  State<_FilterPanel> createState() => _FilterPanelState();
}

class _FilterPanelState extends State<_FilterPanel> {
  late String? category = widget.categoryId;
  late String? product = widget.productId;
  late bool available = widget.available;

  @override
  Widget build(BuildContext context) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Filtros', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            DropdownButtonFormField<String?>(
                initialValue: category,
                decoration: const InputDecoration(labelText: 'Categoría'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Todas')),
                  ...widget.categories.map((item) =>
                      DropdownMenuItem(value: item.id, child: Text(item.name)))
                ],
                onChanged: (value) => setState(() {
                      category = value;
                      product = null;
                      widget.onCategory(value);
                      widget.onProduct(null);
                    })),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
                initialValue: product,
                decoration: const InputDecoration(labelText: 'Producto'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Todos')),
                  ...widget.products
                      .where((item) =>
                          category == null || item.categoryId == category)
                      .map((item) => DropdownMenuItem(
                          value: item.id, child: Text(item.name)))
                ],
                onChanged: (value) => setState(() {
                      product = value;
                      widget.onProduct(value);
                    })),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                  child: TextField(
                      controller: widget.minController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'Precio mínimo (COP)'))),
              const SizedBox(width: 12),
              Expanded(
                  child: TextField(
                      controller: widget.maxController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'Precio máximo (COP)')))
            ]),
            SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Disponible en los próximos 30 días'),
                value: available,
                onChanged: (value) => setState(() {
                      available = value;
                      widget.onAvailability(value);
                    })),
            const SizedBox(height: 12),
            FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Ver resultados')),
          ]);
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.onDeleted});
  final String label;
  final VoidCallback onDeleted;
  @override
  Widget build(BuildContext context) => InputChip(
      label: Text(label),
      onDeleted: onDeleted,
      deleteButtonTooltipMessage: 'Quitar filtro $label');
}

class _OfflineCatalogNotice extends StatelessWidget {
  const _OfflineCatalogNotice({required this.updatedAt, required this.offline});
  final DateTime? updatedAt;
  final bool offline;
  @override
  Widget build(BuildContext context) {
    final prefix = offline ? 'Sin conexión.' : 'No pudimos actualizar.';
    final message = updatedAt == null
        ? '$prefix No hay resultados guardados para esta búsqueda.'
        : '$prefix Última actualización: ${DateFormat('d MMM, HH:mm', 'es_CO').format(updatedAt!.toLocal())}';
    return Semantics(
      liveRegion: true,
      child: Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3CD),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(children: [
          const Icon(Icons.cloud_off_outlined, size: 19),
          const SizedBox(width: 8),
          Expanded(child: Text(message)),
        ]),
      ),
    );
  }
}

class _LotSkeleton extends StatelessWidget {
  const _LotSkeleton();
  @override
  Widget build(BuildContext context) => Container(
      margin: const EdgeInsets.only(bottom: 12),
      height: 168,
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.outline)),
      child: const Padding(
          padding: EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(width: 170, height: 18, child: _ShimmerBlock()),
            SizedBox(height: 14),
            SizedBox(width: 110, height: 14, child: _ShimmerBlock()),
            SizedBox(height: 14),
            SizedBox(height: 14, child: _ShimmerBlock()),
            SizedBox(height: 12),
            SizedBox(width: 200, height: 14, child: _ShimmerBlock())
          ])));
}

class _ShimmerBlock extends StatelessWidget {
  const _ShimmerBlock();
  @override
  Widget build(BuildContext context) => DecoratedBox(
      decoration: BoxDecoration(
          color: AppTheme.outline.withValues(alpha: .65),
          borderRadius: BorderRadius.circular(8)));
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
      child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.wifi_off_outlined,
                size: 42, color: AppTheme.mutedText),
            const SizedBox(height: 12),
            const Text(
                'No pudimos cargar los lotes. Revisa tu conexión e inténtalo de nuevo.',
                textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.tonal(
                onPressed: onRetry, child: const Text('Reintentar'))
          ])));
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hasQuery, required this.onClear});
  final bool hasQuery;
  final VoidCallback onClear;
  @override
  Widget build(BuildContext context) => Center(
      child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.eco_outlined, size: 48, color: AppTheme.primary),
            const SizedBox(height: 12),
            Text(
                hasQuery
                    ? 'No encontramos lotes con esos criterios.'
                    : 'Todavía no hay lotes disponibles.',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center),
            if (hasQuery) ...[
              const SizedBox(height: 12),
              OutlinedButton(
                  onPressed: onClear,
                  child: const Text('Quitar filtros y buscar de nuevo'))
            ]
          ])));
}

class _WebPages extends StatelessWidget {
  const _WebPages({
    required this.pageCount,
    required this.currentPage,
    required this.hasMore,
    required this.onSelect,
  });
  final int pageCount;
  final int currentPage;
  final bool hasMore;
  final ValueChanged<int> onSelect;
  @override
  Widget build(BuildContext context) {
    final count = pageCount + (hasMore ? 1 : 0);
    return Center(
      child: Wrap(
        spacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (var page = 0; page < count; page++)
            page == currentPage
                ? Semantics(
                    selected: true,
                    label: 'Página ${page + 1}',
                    child: CircleAvatar(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      child: Text('${page + 1}'),
                    ),
                  )
                : OutlinedButton(
                    onPressed: () => onSelect(page),
                    child: Text('${page + 1}'),
                  ),
        ],
      ),
    );
  }
}

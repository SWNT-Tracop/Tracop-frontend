import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../app/theme.dart';
import '../../../core/result/result.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../home/presentation/home_screen.dart';
import '../domain/entities/category.dart' as catalog;
import '../domain/entities/lot.dart' hide Category, Product;
import '../domain/entities/product.dart';
import '../domain/lot_form_rules.dart';
import '../domain/lot_quantity.dart';
import 'lot_detail_screen.dart' show lotDetailProvider;
import 'lot_error_text.dart';
import 'providers/catalog_provider.dart';
import 'providers/lot_management_provider.dart';

class LotFormScreen extends ConsumerStatefulWidget {
  const LotFormScreen({this.lotId, super.key});

  final String? lotId;

  bool get isEditing => lotId != null;

  @override
  ConsumerState<LotFormScreen> createState() => _LotFormScreenState();
}

class _LotFormScreenState extends ConsumerState<LotFormScreen> {
  final _quantity = TextEditingController();
  final _price = TextEditingController();
  final _quality = TextEditingController();
  final _lat = TextEditingController();
  final _lng = TextEditingController();
  final _validationMessageKey = GlobalKey();
  final _productSectionKey = GlobalKey();

  String? _productId;
  String? _unit;
  Product? _createdProduct;
  DateTime? _availableFrom;
  DateTime? _availableUntil;
  int? _existingVersion;
  bool _hydrated = false;
  bool _submitting = false;
  String? _formError;
  Map<String, String> _fieldErrors = {};

  @override
  void initState() {
    super.initState();
    final today = dateOnly(DateTime.now());
    _availableFrom = today;
    _availableUntil = today.add(const Duration(days: 7));
  }

  @override
  void dispose() {
    _quantity.dispose();
    _price.dispose();
    _quality.dispose();
    _lat.dispose();
    _lng.dispose();
    super.dispose();
  }

  void _hydrate(Lot lot) {
    _hydrated = true;
    _productId = lot.productId;
    _unit = lot.unit;
    _existingVersion = lot.version;
    _quantity.text = formatQuantityMilli(lot.quantityMilli);
    _price.text = lot.unitPrice;
    _quality.text = lot.qualityGrade ?? '';
    _availableFrom = dateOnly(lot.availableFrom.toLocal());
    _availableUntil = dateOnly(lot.availableUntil.toLocal());
    _lat.text = lot.locationLat?.toString() ?? '';
    _lng.text = lot.locationLng?.toString() ?? '';
  }

  Future<void> _pickDate({required bool from}) async {
    final now = DateTime.now();
    final today = dateOnly(now);
    final horizon = now.add(const Duration(days: lotMaxHorizonDays));
    var lastDate = dateOnly(horizon);
    if (endOfDay(lastDate).isAfter(horizon)) {
      lastDate = dateOnly(lastDate.subtract(const Duration(days: 1)));
    }
    var initial = (from ? _availableFrom : _availableUntil) ?? today;
    if (initial.isBefore(today)) initial = today;
    if (initial.isAfter(lastDate)) initial = lastDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: today,
      lastDate: lastDate,
      locale: const Locale('es', 'CO'),
      helpText: from ? 'Inicio de disponibilidad' : 'Fin de disponibilidad',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (from) {
        _availableFrom = dateOnly(picked);
        if (_availableUntil!.isBefore(_availableFrom!)) {
          _availableUntil = _availableFrom;
        }
      } else {
        _availableUntil = dateOnly(picked);
      }
      _fieldErrors.remove('availability');
      if (_fieldErrors.isEmpty) _formError = null;
    });
  }

  Map<String, String> _validateFields() {
    final errors = <String, String>{};
    final productsState = ref.read(catalogProductsProvider);
    final products = productsState.valueOrNull ?? const [];
    final currentProduct =
        products.where((item) => item.id == _productId).firstOrNull ??
            (_createdProduct?.id == _productId ? _createdProduct : null);
    if (_productId == null) {
      if (productsState.hasError) {
        errors['product'] = 'No se pudo cargar la lista. Intenta de nuevo.';
      } else if (productsState.isLoading) {
        errors['product'] = 'Espera a que cargue la lista.';
      } else if (products.isEmpty) {
        errors['product'] = 'No hay productos disponibles por ahora.';
      } else {
        errors['product'] = 'Elige el producto que vas a ofrecer.';
      }
    } else if (currentProduct == null && !widget.isEditing) {
      errors['product'] = 'Elige un producto válido.';
    }
    if (parseQuantityMilli(_quantity.text) == null) {
      errors['quantity'] =
          'Escribe una cantidad mayor que cero (máx. 3 decimales).';
    }
    if (parseUnitPrice(_price.text) == null) {
      errors['price'] = 'Escribe un precio entero mayor que cero.';
    }
    if (_quality.text.trim().length > 100) {
      errors['quality'] = 'Usa máximo 100 caracteres.';
    }
    final from = _availableFrom;
    final until = _availableUntil;
    if (from == null || until == null) {
      errors['availability'] = 'Elige las fechas de disponibilidad.';
    } else {
      final dateError = validateAvailability(from, until);
      if (dateError != null) errors['availability'] = dateError;
    }
    final lat = parseCoordinate(_lat.text);
    final lng = parseCoordinate(_lng.text);
    if (lat == null) errors['latitude'] = 'Escribe una latitud válida.';
    if (lng == null) errors['longitude'] = 'Escribe una longitud válida.';
    if (lat != null && lng != null && !isWithinColombia(lat, lng)) {
      errors['latitude'] = 'Revisa la ubicación.';
      errors['longitude'] = 'Las coordenadas deben estar en Colombia.';
    }
    return errors;
  }

  Future<void> _save({required bool publish}) async {
    FocusScope.of(context).unfocus();
    final offline = ref.read(homeConnectivityProvider).valueOrNull == false;
    if (offline) {
      setState(() {
        _fieldErrors = {};
        _formError = 'Conéctate a internet para guardar el lote.';
      });
      _revealValidation();
      return;
    }
    final errors = _validateFields();
    if (errors.isNotEmpty) {
      setState(() {
        _fieldErrors = errors;
        _formError = 'Completa los campos marcados para continuar.';
      });
      _revealValidation();
      return;
    }
    final product = ref
            .read(catalogProductsProvider)
            .valueOrNull
            ?.where((item) => item.id == _productId)
            .firstOrNull ??
        (_createdProduct?.id == _productId ? _createdProduct : null);
    final unit = product?.unit ?? _unit;
    if (unit == null) {
      setState(() {
        _fieldErrors = {'product': 'Elige un producto válido.'};
        _formError = 'Completa los campos marcados para continuar.';
      });
      _revealValidation();
      return;
    }

    final quantityMilli = parseQuantityMilli(_quantity.text)!;
    final unitPrice = parseUnitPrice(_price.text)!;
    final quality = _quality.text.trim();
    final from = dateOnly(_availableFrom!).toUtc();
    final until = endOfDay(_availableUntil!).toUtc();
    final lat = parseCoordinate(_lat.text)!;
    final lng = parseCoordinate(_lng.text)!;

    setState(() {
      _submitting = true;
      _formError = null;
    });

    final repo = ref.read(catalogRepositoryProvider);
    final Result<Lot, DomainFailure> result;
    if (widget.isEditing) {
      result = await repo.updateLot(
        widget.lotId!,
        UpdateLotRequest(
          version: _existingVersion!,
          productId: _productId,
          quantityMilli: '$quantityMilli',
          unit: unit,
          unitPrice: unitPrice,
          qualityGrade: quality.isEmpty ? null : quality,
          availableFrom: from,
          availableUntil: until,
          locationLat: lat,
          locationLng: lng,
        ),
      );
    } else {
      result = await repo.createLot(
        CreateLotRequest(
          id: const Uuid().v7(),
          productId: _productId!,
          quantityMilli: '$quantityMilli',
          unit: unit,
          unitPrice: unitPrice,
          qualityGrade: quality.isEmpty ? null : quality,
          availableFrom: from,
          availableUntil: until,
          locationLat: lat,
          locationLng: lng,
        ),
      );
    }

    Lot? saved;
    switch (result) {
      case Ok(:final value):
        saved = value;
      case Err(:final error):
        if (!mounted) return;
        setState(() {
          _submitting = false;
          _fieldErrors = {};
          _formError = lotErrorText(error);
        });
        _revealValidation();
        return;
    }

    DomainFailure? publishFailure;
    if (publish) {
      final outcome = await repo.publishLot(saved.id, saved.version);
      switch (outcome) {
        case Ok():
          break;
        case Err(:final error):
          publishFailure = error;
      }
    }

    if (!mounted) return;
    ref.invalidate(myLotsProvider);
    ref.invalidate(homeLotsProvider);
    ref.invalidate(lotByIdProvider(saved.id));
    ref.invalidate(lotDetailProvider);
    final message = publishFailure != null
        ? 'Guardado como borrador. No se pudo publicar: ${lotErrorText(publishFailure)}'
        : publish
            ? 'Lote publicado.'
            : widget.isEditing
                ? 'Cambios guardados.'
                : 'Borrador guardado.';
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor:
            publishFailure != null ? const Color(0xFFB3261E) : AppTheme.forest,
        duration: const Duration(seconds: 6),
        action: publishFailure?.code == 'profile_required'
            ? SnackBarAction(
                label: 'Completar perfil',
                textColor: Colors.white,
                onPressed: () => context.go('/perfil/proveedor'),
              )
            : null,
      ));
    context.go('/lotes');
  }

  void _revealValidation() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final target = _validationMessageKey.currentContext;
      if (target == null) return;
      Scrollable.ensureVisible(
        target,
        alignment: 0,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _clearFieldErrors(Iterable<String> fields) {
    setState(() {
      for (final field in fields) {
        _fieldErrors.remove(field);
      }
      if (_fieldErrors.isEmpty) _formError = null;
    });
  }

  Future<void> _createProduct() async {
    final created = await showModalBottomSheet<Product>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _CreateProductSheet(),
    );
    if (created == null || !mounted) return;
    ref.invalidate(catalogProductsProvider);
    setState(() {
      _createdProduct = created;
      _productId = created.id;
      _unit = created.unit;
      _fieldErrors.remove('product');
      if (_fieldErrors.isEmpty) _formError = null;
    });
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/lotes');
    }
  }

  @override
  Widget build(BuildContext context) {
    final existing =
        widget.lotId == null ? null : ref.watch(lotByIdProvider(widget.lotId!));
    final existingLot = existing?.valueOrNull;
    if (existingLot != null && !_hydrated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_hydrated) {
          setState(() => _hydrate(existingLot));
        }
      });
    }

    final role = ref.watch(homeUserProvider).valueOrNull?.role ??
        ref.watch(authProvider).valueOrNull?.user.role;
    final isSeller = role == 'producer' || role == 'supplier';
    final offline = ref.watch(homeConnectivityProvider).valueOrNull == false;
    final products = ref.watch(catalogProductsProvider);

    if (role != null && !isSeller) {
      return _FormScaffold(
        title: 'Nuevo lote',
        onBack: _back,
        child: _BlockedState(onBack: _back),
      );
    }

    if (widget.isEditing && !_hydrated) {
      if (existing!.hasError) {
        return _FormScaffold(
          title: 'Editar lote',
          onBack: _back,
          child: _LoadErrorState(
            onRetry: () => ref.invalidate(lotByIdProvider(widget.lotId!)),
          ),
        );
      }
      return _FormScaffold(
        title: 'Editar lote',
        onBack: _back,
        child: const Padding(
          padding: EdgeInsets.all(48),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (widget.isEditing && existing!.valueOrNull?.status != 'draft') {
      return _FormScaffold(
        title: 'Editar lote',
        onBack: _back,
        child: _NonDraftState(onBack: _back),
      );
    }

    final wide = MediaQuery.sizeOf(context).width >= 760;
    final estimatedSubtotal = _estimatedSubtotal();

    return _FormScaffold(
      title: widget.isEditing ? 'Editar lote' : 'Nuevo lote',
      onBack: _back,
      subtitle: widget.isEditing
          ? 'Ajusta los datos del borrador antes de publicarlo.'
          : 'Completa los datos de tu oferta. Puedes guardarla como borrador.',
      child: Form(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (offline) ...[
              const _OfflineNotice(),
              const SizedBox(height: 16),
            ],
            if (_formError != null) ...[
              AnimatedSwitcher(
                key: _validationMessageKey,
                duration: const Duration(milliseconds: 260),
                switchInCurve: Curves.easeOutCubic,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, -0.08),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: _FormError(
                  key: ValueKey(_formError),
                  message: _formError!,
                ),
              ),
              const SizedBox(height: 16),
            ],
            _SectionCard(
              key: _productSectionKey,
              title: 'Producto',
              subtitle: 'La unidad del lote se toma del producto.',
              highlighted: _fieldErrors.containsKey('product'),
              child: _ProductField(
                products: products,
                productId: _productId,
                enabled: !_submitting,
                isEditing: widget.isEditing,
                errorMessage: _fieldErrors['product'],
                addedProduct: _createdProduct,
                canCreateProduct: isSeller && !_submitting && !offline,
                onCreateProduct: _createProduct,
                onChanged: (value) {
                  final product = products.valueOrNull
                      ?.where((item) => item.id == value)
                      .firstOrNull;
                  setState(() {
                    _productId = value;
                    _unit = product?.unit ?? _unit;
                    _fieldErrors.remove('product');
                    if (_fieldErrors.isEmpty) _formError = null;
                  });
                },
                onRetry: () => ref.invalidate(catalogProductsProvider),
              ),
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Cantidad y precio',
              subtitle: 'El precio se expresa en pesos enteros por unidad.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ResponsiveRow(
                    wide: wide,
                    children: [
                      TextField(
                        controller: _quantity,
                        enabled: !_submitting,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                        ],
                        textInputAction: TextInputAction.next,
                        onChanged: (_) => _clearFieldErrors(['quantity']),
                        decoration: InputDecoration(
                          labelText: 'Cantidad',
                          hintText: '25.5',
                          suffixText: _unit ?? '',
                          helperText: 'Máximo 3 decimales.',
                          errorText: _fieldErrors['quantity'],
                        ),
                      ),
                      TextField(
                        controller: _price,
                        enabled: !_submitting,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        textInputAction: TextInputAction.next,
                        onChanged: (_) => _clearFieldErrors(['price']),
                        decoration: InputDecoration(
                          labelText: 'Precio por unidad',
                          hintText: '3200',
                          prefixText: r'$ ',
                          suffixText: _unit == null ? '' : 'por $_unit',
                          errorText: _fieldErrors['price'],
                        ),
                      ),
                    ],
                  ),
                  if (estimatedSubtotal != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.mint,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calculate_outlined,
                              size: 20, color: AppTheme.forest),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Valor estimado del lote',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: AppTheme.forest),
                            ),
                          ),
                          Text(
                            NumberFormat.currency(
                              locale: 'es_CO',
                              symbol: r'$ ',
                              decimalDigits: 0,
                            ).format(estimatedSubtotal),
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: AppTheme.forest,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Calidad',
              subtitle:
                  'Opcional. Describe el estado o la categoría del producto.',
              child: TextField(
                controller: _quality,
                enabled: !_submitting,
                maxLength: 100,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (_) => _clearFieldErrors(['quality']),
                decoration: InputDecoration(
                  labelText: 'Calidad',
                  hintText: 'Primera, extra, maduro…',
                  errorText: _fieldErrors['quality'],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Disponibilidad',
              subtitle:
                  'Elige el rango en que el lote estará disponible. Máximo $lotMaxHorizonDays días desde hoy.',
              child: _ResponsiveRow(
                wide: wide,
                children: [
                  _DateField(
                    label: 'Desde',
                    value: _availableFrom,
                    enabled: !_submitting,
                    errorText: _fieldErrors['availability'],
                    onTap: () => _pickDate(from: true),
                  ),
                  _DateField(
                    label: 'Hasta',
                    value: _availableUntil,
                    enabled: !_submitting,
                    errorText: _fieldErrors['availability'],
                    onTap: () => _pickDate(from: false),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Ubicación',
              subtitle:
                  'Coordenadas del punto de recogida. Deben estar dentro de Colombia.',
              child: _ResponsiveRow(
                wide: wide,
                children: [
                  TextField(
                    controller: _lat,
                    enabled: !_submitting,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true, signed: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,-]')),
                    ],
                    onChanged: (_) =>
                        _clearFieldErrors(['latitude', 'longitude']),
                    decoration: InputDecoration(
                      labelText: 'Latitud',
                      hintText: '5.5353',
                      errorText: _fieldErrors['latitude'],
                    ),
                  ),
                  TextField(
                    controller: _lng,
                    enabled: !_submitting,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true, signed: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,-]')),
                    ],
                    onChanged: (_) =>
                        _clearFieldErrors(['latitude', 'longitude']),
                    decoration: InputDecoration(
                      labelText: 'Longitud',
                      hintText: '-73.3678',
                      errorText: _fieldErrors['longitude'],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _FormActions(
              submitting: _submitting,
              isEditing: widget.isEditing,
              onCancel: _submitting ? null : _back,
              onSaveDraft: _submitting ? null : () => _save(publish: false),
              onSaveAndPublish: _submitting ? null : () => _save(publish: true),
            ),
            const SizedBox(height: 16),
            Text(
              'Publicar requiere que tu perfil de proveedor esté completo.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 13,
                    color: AppTheme.mutedText,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  int? _estimatedSubtotal() {
    final quantity = parseQuantityMilli(_quantity.text);
    final price = parseUnitPrice(_price.text);
    if (quantity == null || price == null) return null;
    return (quantity * price) ~/ 1000;
  }
}

class _FormScaffold extends StatelessWidget {
  const _FormScaffold({
    required this.title,
    required this.onBack,
    required this.child,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final VoidCallback onBack;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 760;
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 880),
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                  wide ? 40 : 20, wide ? 32 : 16, wide ? 40 : 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton(
                        tooltip: 'Volver',
                        onPressed: onBack,
                        icon: const Icon(Icons.arrow_back_rounded),
                        color: AppTheme.forest,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(
                                    color: AppTheme.forest,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            if (subtitle != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                subtitle!,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color:
                                          AppTheme.ink.withValues(alpha: .72),
                                    ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  child,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.highlighted = false,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final bool highlighted;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: highlighted ? const Color(0xFFB3261E) : AppTheme.outline,
            width: highlighted ? 1.6 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.forest,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 13,
                      color: AppTheme.mutedText,
                    ),
              ),
            ],
            const SizedBox(height: 14),
            child,
          ],
        ),
      );
}

class _ProductField extends StatelessWidget {
  const _ProductField({
    required this.products,
    required this.productId,
    required this.enabled,
    required this.isEditing,
    required this.errorMessage,
    required this.addedProduct,
    required this.canCreateProduct,
    required this.onCreateProduct,
    required this.onChanged,
    required this.onRetry,
  });

  final AsyncValue<List<Product>> products;
  final String? productId;
  final bool enabled;
  final bool isEditing;
  final String? errorMessage;
  final Product? addedProduct;
  final bool canCreateProduct;
  final VoidCallback onCreateProduct;
  final ValueChanged<String?> onChanged;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final fetched = products.valueOrNull ?? const <Product>[];
    final items = [
      ...fetched,
      if (addedProduct != null &&
          !fetched.any((item) => item.id == addedProduct!.id))
        addedProduct!,
    ];
    final selectedMissing =
        productId != null && !items.any((item) => item.id == productId);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (products.hasError) ...[
          Row(
            children: [
              const Expanded(
                child: Text(
                    'No pudimos cargar los productos. Puedes reintentar o crear uno.'),
              ),
              const SizedBox(width: 8),
              TextButton(onPressed: onRetry, child: const Text('Reintentar')),
            ],
          ),
          const SizedBox(height: 8),
        ],
        DropdownButtonFormField<String>(
          key: ValueKey(productId),
          initialValue: productId,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: 'Producto',
            hintText: products.isLoading && items.isEmpty
                ? 'Cargando productos…'
                : 'Selecciona',
            errorText: errorMessage,
          ),
          items: [
            for (final product in items)
              DropdownMenuItem(
                value: product.id,
                child: Text('${product.name} · ${product.unit}'),
              ),
            if (isEditing && selectedMissing)
              DropdownMenuItem(
                value: productId,
                child: const Text('Producto actual'),
              ),
          ],
          onChanged: enabled && items.isNotEmpty ? onChanged : null,
        ),
        if (!products.isLoading && !products.hasError && items.isEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'No hay productos disponibles en el catálogo todavía.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: errorMessage != null
                      ? const Color(0xFFB3261E)
                      : AppTheme.mutedText,
                ),
          ),
        ],
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: canCreateProduct ? onCreateProduct : null,
          icon: const Icon(Icons.add_rounded),
          label: const Text('No encuentro mi producto · Crear producto'),
        ),
      ],
    );
  }
}

class _CreateProductSheet extends ConsumerStatefulWidget {
  const _CreateProductSheet();

  @override
  ConsumerState<_CreateProductSheet> createState() =>
      _CreateProductSheetState();
}

class _CreateProductSheetState extends ConsumerState<_CreateProductSheet> {
  final _name = TextEditingController();
  String? _categoryId;
  String _unit = 'kg';
  bool _saving = false;
  String? _error;

  static const _units = <String, String>{
    'kg': 'Kilogramo (kg)',
    'g': 'Gramo (g)',
    'lb': 'Libra (lb)',
    'und': 'Unidad (und)',
    'docena': 'Docena',
    'arroba': 'Arroba',
    'quintal': 'Quintal',
    'caja': 'Caja',
    'mano': 'Mano',
    'bulto': 'Bulto',
  };

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty || name.length > 120) {
      setState(() => _error = 'Escribe un nombre de hasta 120 caracteres.');
      return;
    }
    if (_categoryId == null) {
      setState(() => _error = 'Elige una categoría.');
      return;
    }
    if (ref.read(homeConnectivityProvider).valueOrNull == false) {
      setState(() => _error = 'Conéctate a internet para crear el producto.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    final result = await ref.read(catalogRepositoryProvider).createProduct(
          CreateProductRequest(
            id: const Uuid().v7(),
            categoryId: _categoryId!,
            name: name,
            unit: _unit,
          ),
        );
    if (!mounted) return;
    switch (result) {
      case Ok(:final value):
        Navigator.of(context).pop(value);
      case Err(:final error):
        setState(() {
          _saving = false;
          _error = _productCreationError(error);
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(catalogCategoriesProvider);
    final items = categories.valueOrNull ?? const <catalog.Category>[];
    final categoryStillExists =
        _categoryId != null && items.any((item) => item.id == _categoryId);
    final selectedCategory = categoryStillExists ? _categoryId : null;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Material(
      color: AppTheme.background,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Crear producto',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppTheme.forest,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Cerrar',
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                  'El producto quedará disponible en el catálogo para todos. Elige una categoría existente.'),
              const SizedBox(height: 18),
              TextField(
                key: const ValueKey('new-product-name'),
                controller: _name,
                enabled: !_saving,
                maxLength: 120,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nombre del producto',
                  hintText: 'Ej. Papa criolla',
                ),
              ),
              const SizedBox(height: 12),
              if (categories.hasError)
                Row(
                  children: [
                    const Expanded(
                        child: Text('No pudimos cargar las categorías.')),
                    TextButton(
                      onPressed: () =>
                          ref.invalidate(catalogCategoriesProvider),
                      child: const Text('Reintentar'),
                    ),
                  ],
                )
              else if (items.isEmpty && !categories.isLoading)
                const Text(
                    'Todavía no hay categorías. Pídele al equipo TRACOP que agregue una antes de crear el producto.'),
              DropdownButtonFormField<String>(
                key: const ValueKey('new-product-category'),
                initialValue: selectedCategory,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Categoría',
                  hintText: categories.isLoading
                      ? 'Cargando categorías…'
                      : 'Selecciona',
                ),
                items: [
                  for (final category in items)
                    DropdownMenuItem(
                      value: category.id,
                      child: Text(category.name),
                    ),
                ],
                onChanged: _saving || items.isEmpty
                    ? null
                    : (value) => setState(() {
                          _categoryId = value;
                          _error = null;
                        }),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _unit,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Unidad de venta'),
                items: [
                  for (final unit in _units.entries)
                    DropdownMenuItem(value: unit.key, child: Text(unit.value)),
                ],
                onChanged: _saving
                    ? null
                    : (value) {
                        if (value != null) setState(() => _unit = value);
                      },
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Semantics(
                  liveRegion: true,
                  child: Text(_error!,
                      style: const TextStyle(color: Color(0xFFB3261E))),
                ),
              ],
              const SizedBox(height: 18),
              FilledButton(
                onPressed: _saving || items.isEmpty ? null : _save,
                child: _saving
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Crear y usar producto'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _productCreationError(DomainFailure failure) => switch (failure.code) {
      'invalid_product' => 'Revisa el nombre del producto.',
      'invalid_unit' => 'Selecciona una unidad válida.',
      'not_found' =>
        'La categoría ya no está disponible. Actualiza e intenta otra vez.',
      'forbidden' => 'Tu cuenta no tiene permiso para crear productos.',
      'network_error' =>
        'Sin conexión. Intenta crear el producto cuando tengas señal.',
      _ when failure.statusCode == 409 =>
        'Ya existe un producto con ese nombre en esta categoría.',
      _ =>
        'No pudimos crear el producto. Verifica los datos e intenta de nuevo.',
    };

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.enabled,
    required this.errorText,
    required this.onTap,
  });

  final String label;
  final DateTime? value;
  final bool enabled;
  final String? errorText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(AppTheme.radiusControl),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            suffixIcon: const Icon(Icons.calendar_today_outlined, size: 20),
            errorText: errorText,
          ),
          child: Text(
            value == null
                ? 'Selecciona una fecha'
                : DateFormat('EEE d MMM y', 'es_CO').format(value!),
            style: TextStyle(
              color: value == null ? AppTheme.mutedText : AppTheme.ink,
            ),
          ),
        ),
      );
}

class _ResponsiveRow extends StatelessWidget {
  const _ResponsiveRow({required this.wide, required this.children});

  final bool wide;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (!wide || children.length < 2) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < children.length; index++) ...[
            if (index > 0) const SizedBox(height: 12),
            children[index],
          ],
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < children.length; index++) ...[
          if (index > 0) const SizedBox(width: 12),
          Expanded(child: children[index]),
        ],
      ],
    );
  }
}

class _FormActions extends StatelessWidget {
  const _FormActions({
    required this.submitting,
    required this.isEditing,
    required this.onCancel,
    required this.onSaveDraft,
    required this.onSaveAndPublish,
  });

  final bool submitting;
  final bool isEditing;
  final VoidCallback? onCancel;
  final VoidCallback? onSaveDraft;
  final VoidCallback? onSaveAndPublish;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 760;
    final buttons = <Widget>[
      OutlinedButton(
        onPressed: submitting ? null : onCancel,
        child: const Text('Cancelar'),
      ),
      FilledButton.tonal(
        onPressed: onSaveDraft,
        child: submitting
            ? const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(isEditing ? 'Guardar cambios' : 'Guardar borrador'),
      ),
      FilledButton(
        onPressed: onSaveAndPublish,
        child: const Text('Guardar y publicar'),
      ),
    ];
    if (!wide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          buttons[2],
          const SizedBox(height: 10),
          buttons[1],
          const SizedBox(height: 10),
          buttons[0],
        ],
      );
    }
    return Wrap(
      alignment: WrapAlignment.end,
      spacing: 12,
      runSpacing: 12,
      children: buttons,
    );
  }
}

class _OfflineNotice extends StatelessWidget {
  const _OfflineNotice();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3CD),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(Icons.cloud_off_outlined,
                color: Color(0xFF704E00), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Sin conexión. Puedes preparar los datos, pero guardar requiere señal.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF553B00),
                      fontSize: 14,
                    ),
              ),
            ),
          ],
        ),
      );
}

class _FormError extends StatelessWidget {
  const _FormError({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) => Semantics(
        liveRegion: true,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFFDECEA),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Icon(Icons.error_outline,
                  color: Color(0xFFB3261E), size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF7F1D1D),
                        fontSize: 14,
                      ),
                ),
              ),
            ],
          ),
        ),
      );
}

class _BlockedState extends StatelessWidget {
  const _BlockedState({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Icon(Icons.storefront_outlined,
                size: 48, color: AppTheme.primary),
            const SizedBox(height: 16),
            Text(
              'Solo productores y proveedores pueden crear lotes.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.forest,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: onBack,
              child: const Text('Volver a mis lotes'),
            ),
          ],
        ),
      );
}

class _LoadErrorState extends StatelessWidget {
  const _LoadErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Icon(Icons.cloud_off_outlined,
                size: 48, color: AppTheme.mutedText),
            const SizedBox(height: 16),
            Text(
              'No pudimos cargar el lote.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.forest,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Revisa tu conexión e intenta de nuevo.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.tonalIcon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
}

class _NonDraftState extends StatelessWidget {
  const _NonDraftState({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Icon(Icons.lock_outline, size: 48, color: AppTheme.primary),
            const SizedBox(height: 16),
            Text(
              'Este lote ya no está en borrador.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.forest,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Solo los borradores se pueden editar. Puedes cancelarlo o consultarlo desde Mis lotes.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: onBack,
              child: const Text('Volver a mis lotes'),
            ),
          ],
        ),
      );
}

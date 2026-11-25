import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../app/back_guard.dart';
import '../../../app/motion.dart';
import '../../../app/theme.dart';
import '../../../core/i18n/strings.dart';
import '../../../shared/widgets/option_selectors.dart';
import '../../../core/result/result.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../home/presentation/home_screen.dart';
import '../domain/entities/category.dart' as catalog;
import '../domain/entities/lot.dart' hide Category, Product;
import '../domain/entities/product.dart';
import '../domain/entities/product_proposal.dart';
import '../domain/lot_form_rules.dart';
import '../domain/lot_quantity.dart';
import 'lot_detail_screen.dart' show lotDetailProvider;
import 'lot_error_text.dart';
import 'providers/catalog_provider.dart';
import 'providers/lot_management_provider.dart';
import 'providers/product_proposal_provider.dart';

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
  String? _draftLotId;
  DateTime? _availableFrom;
  DateTime? _availableUntil;
  int? _existingVersion;
  bool _hydrated = false;
  bool _submitting = false;
  bool _photoBusy = false;
  String? _formError;
  String? _photoError;
  List<LotPhoto> _photos = [];
  final List<_PendingLotPhoto> _pendingPhotos = [];
  final _imagePicker = ImagePicker();
  Map<String, String> _fieldErrors = {};
  String? _baseline;
  (double, double)? _profilePoint;
  bool _usingProfilePoint = false;

  bool get isEditing => widget.isEditing || _draftLotId != null;
  String? get _activeLotId => widget.lotId ?? _draftLotId;

  // Huella de lo escrito para saber si hay cambios sin guardar.
  String get _signature => [
        _productId,
        _quantity.text,
        _price.text,
        _quality.text,
        _availableFrom,
        _availableUntil,
        _lat.text,
        _lng.text,
        _pendingPhotos.length,
      ].join('|');

  bool get _dirty =>
      !_submitting && _baseline != null && _signature != _baseline;

  @override
  void initState() {
    super.initState();
    final today = dateOnly(DateTime.now());
    _availableFrom = today;
    _availableUntil = today.add(const Duration(days: 7));
    _baseline = _signature;
    backGuard.value = _allowLeave;
    _loadProfilePoint();
  }

  Future<bool> _allowLeave() async => !_dirty || await _confirmLeave();

  // El punto del perfil evita escribir coordenadas a mano en cada lote.
  Future<void> _loadProfilePoint() async {
    try {
      final result =
          await ref.read(authRepositoryProvider).getStoredProviderProfile();
      final profile = result.map(ok: (ok) => ok.value, err: (_) => null);
      if (profile == null || !mounted) return;
      setState(() {
        _profilePoint = (profile.lat, profile.lng);
        final pristine = _signature == _baseline;
        if (widget.lotId == null && _lat.text.isEmpty && _lng.text.isEmpty) {
          _applyProfilePoint();
          if (pristine) _baseline = _signature;
        }
      });
    } catch (_) {
      // Sin perfil guardado se mantiene el ingreso manual.
    }
  }

  void _applyProfilePoint() {
    final point = _profilePoint;
    if (point == null) return;
    _lat.text = '${point.$1}';
    _lng.text = '${point.$2}';
    _usingProfilePoint = true;
    _fieldErrors.remove('latitude');
    _fieldErrors.remove('longitude');
    if (_fieldErrors.isEmpty) _formError = null;
  }

  bool get _matchesProfilePoint {
    final point = _profilePoint;
    return point != null &&
        parseCoordinate(_lat.text) == point.$1 &&
        parseCoordinate(_lng.text) == point.$2;
  }

  @override
  void dispose() {
    if (backGuard.value == _allowLeave) backGuard.value = null;
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
    _photos = lot.photos;
    _usingProfilePoint = false;
    _baseline = _signature;
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
    } else if (currentProduct == null && !isEditing) {
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
    final wasEditing = isEditing;
    final offline = ref.read(homeConnectivityProvider).valueOrNull == false;
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
    if (wasEditing) {
      result = await repo.updateLot(
        _activeLotId!,
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

    if (!wasEditing && _draftLotId == null) {
      _draftLotId = saved.id;
      _existingVersion = saved.version;
    }

    for (final pending in List<_PendingLotPhoto>.from(_pendingPhotos)) {
      final photoResult = await repo.uploadLotPhoto(
        lotId: saved.id,
        photoId: pending.id,
        filename: pending.file.name,
        bytes: pending.bytes,
      );
      if (photoResult case Ok(:final value)) {
        if (!mounted) return;
        setState(() {
          _photos = value;
          _pendingPhotos.remove(pending);
          _photoError = null;
        });
      } else if (photoResult case Err(:final error)) {
        if (!mounted) return;
        setState(() {
          _submitting = false;
          _photoError = _photoErrorText(error);
          _draftLotId = saved!.id;
          _existingVersion = saved.version;
        });
        _invalidateLotViews(saved.id);
        return;
      }
    }

    DomainFailure? publishFailure;
    var queuedForSync = offline || saved.isFromCache;
    if (publish) {
      final outcome = await repo.publishLot(saved.id, saved.version);
      switch (outcome) {
        case Ok(:final value):
          queuedForSync = queuedForSync || value.isFromCache;
        case Err(:final error):
          publishFailure = error;
      }
    }

    if (!mounted) return;
    setState(() => _photoError = null);
    ref.read(localLotModifiedAtProvider.notifier).state = {
      ...ref.read(localLotModifiedAtProvider),
      saved.id: DateTime.now(),
    };
    _invalidateLotViews(saved.id);
    final message = queuedForSync
        ? (publish
            ? 'Lote guardado localmente y pendiente de publicación.'
            : 'Lote guardado en este dispositivo. Pendiente de sincronización.')
        : publishFailure != null
            ? 'Guardado como borrador. No se pudo publicar: ${lotErrorText(publishFailure)}'
            : publish
                ? 'Lote publicado correctamente.'
                : wasEditing
                    ? 'Cambios guardados correctamente.'
                    : 'Borrador guardado correctamente.';
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final confirmation = SnackBar(
      content: Text(message),
      backgroundColor:
          publishFailure != null ? AppTheme.dangerStrong : AppTheme.forest,
      duration: AppMotion.snackBar,
      behavior: SnackBarBehavior.floating,
      action: publishFailure?.code == 'profile_required'
          ? SnackBarAction(
              label: LotFormStrings.completeProfile,
              textColor: Colors.white,
              onPressed: () => router.go('/perfil/proveedor'),
            )
          : null,
    );
    context.go('/lotes');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(confirmation);
    });
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

  void _invalidateLotViews(String lotId) {
    ref.invalidate(lotByIdProvider(lotId));
    ref.invalidate(lotDetailProvider(lotId));
    ref.invalidate(myLotsProvider);
    ref.invalidate(homeLotsProvider);
  }

  Future<void> _choosePhotoSource() async {
    if (_submitting || _photoBusy) return;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      useSafeArea: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Elegir de la galería'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            if (kIsWeb ||
                defaultTargetPlatform == TargetPlatform.android ||
                defaultTargetPlatform == TargetPlatform.iOS)
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Tomar una foto'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
          ],
        ),
      ),
    );
    if (source != null && mounted) await _pickPhotos(source);
  }

  Future<void> _pickPhotos(ImageSource source) async {
    const maxPhotoCount = 5;
    const maxPhotoBytes = 5 * 1024 * 1024;
    final remaining = maxPhotoCount - _photos.length - _pendingPhotos.length;
    if (remaining <= 0) return;

    try {
      final List<XFile> files;
      if (source == ImageSource.gallery) {
        files = await _imagePicker.pickMultiImage(
          limit: remaining,
          maxWidth: 2560,
          maxHeight: 2560,
          imageQuality: 85,
        );
      } else {
        final file = await _imagePicker.pickImage(
          source: ImageSource.camera,
          maxWidth: 2560,
          maxHeight: 2560,
          imageQuality: 85,
        );
        files = file == null ? const [] : [file];
      }
      if (files.isEmpty || !mounted) return;

      final selected = <_PendingLotPhoto>[];
      String? selectionError;
      for (final file in files.take(remaining)) {
        if (await file.length() > maxPhotoBytes) {
          selectionError =
              'Cada foto debe pesar máximo 5 MB. Las demás sí se agregaron.';
          continue;
        }
        final bytes = await file.readAsBytes();
        selected.add(_PendingLotPhoto(
          id: const Uuid().v7(),
          file: file,
          bytes: bytes,
        ));
      }
      if (!mounted) return;
      setState(() {
        _pendingPhotos.addAll(selected);
        _photoError = selectionError;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _photoError =
          'No pudimos abrir la cámara o la galería. Revisa los permisos e intenta de nuevo.');
    }
  }

  Future<void> _removeSavedPhoto(LotPhoto photo) async {
    final lotId = _activeLotId;
    if (lotId == null ||
        _photoBusy ||
        _submitting ||
        ref.read(homeConnectivityProvider).valueOrNull == false) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quitar foto'),
        content: const Text('La foto dejará de aparecer en este lote.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Quitar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _photoBusy = true;
      _photoError = null;
    });
    final result = await ref
        .read(catalogRepositoryProvider)
        .deleteLotPhoto(lotId, photo.id);
    if (!mounted) return;
    switch (result) {
      case Ok(:final value):
        setState(() {
          _photos = value;
          _photoBusy = false;
        });
        _invalidateLotViews(lotId);
      case Err(:final error):
        setState(() {
          _photoBusy = false;
          _photoError = _photoErrorText(error);
        });
    }
  }

  Future<void> _moveSavedPhoto(int index, int offset) async {
    final lotId = _activeLotId;
    final destination = index + offset;
    if (lotId == null ||
        _photoBusy ||
        _submitting ||
        ref.read(homeConnectivityProvider).valueOrNull == false ||
        destination < 0 ||
        destination >= _photos.length) {
      return;
    }
    final ordered = List<LotPhoto>.from(_photos);
    final item = ordered.removeAt(index);
    ordered.insert(destination, item);
    setState(() {
      _photoBusy = true;
      _photos = ordered;
      _photoError = null;
    });
    final result = await ref.read(catalogRepositoryProvider).reorderLotPhotos(
          lotId,
          ordered.map((photo) => photo.id).toList(growable: false),
        );
    if (!mounted) return;
    switch (result) {
      case Ok(:final value):
        setState(() {
          _photos = value;
          _photoBusy = false;
        });
        _invalidateLotViews(lotId);
      case Err(:final error):
        setState(() {
          _photos = List<LotPhoto>.from(_photos)
            ..remove(item)
            ..insert(index, item);
          _photoBusy = false;
          _photoError = _photoErrorText(error);
        });
    }
  }

  Widget _photosSection({required bool offline}) {
    final count = _photos.length + _pendingPhotos.length;
    final canAdd = !offline && !_submitting && !_photoBusy && count < 5;
    return _SectionCard(
      title: 'Fotos del lote',
      subtitle:
          'Agrega fotos desde la galería o la cámara; se cargarán al guardar el lote.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_photos.isEmpty && _pendingPhotos.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              decoration: BoxDecoration(
                color: AppTheme.mint.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.outline),
              ),
              child: const Column(
                children: [
                  Icon(Icons.add_photo_alternate_outlined,
                      size: 30, color: AppTheme.forest),
                  SizedBox(height: 8),
                  Text('Aún no agregas fotos'),
                ],
              ),
            ),
          if (_photos.isNotEmpty || _pendingPhotos.isNotEmpty) ...[
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (var index = 0; index < _photos.length; index++)
                  _savedPhotoTile(_photos[index], index, offline: offline),
                for (final pending in _pendingPhotos)
                  _pendingPhotoTile(pending),
              ],
            ),
            const SizedBox(height: 12),
          ],
          OutlinedButton.icon(
            onPressed: canAdd ? _choosePhotoSource : null,
            icon: const Icon(Icons.add_a_photo_outlined),
            label: Text(
                count >= 5 ? 'Llegaste al máximo de fotos' : 'Agregar fotos'),
          ),
          const SizedBox(height: 8),
          Text(
            '$count de 5 · JPG, PNG o WebP · máximo 5 MB por foto',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppTheme.mutedText),
          ),
          if (offline) ...[
            const SizedBox(height: 8),
            const Text('Conéctate para cargar y guardar las fotos.'),
          ],
          if (_photoError != null) ...[
            const SizedBox(height: 10),
            Semantics(
              liveRegion: true,
              child: Text(
                _photoError!,
                style: const TextStyle(color: AppTheme.dangerStrong),
              ),
            ),
          ],
          if (_photoBusy) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(),
          ],
        ],
      ),
    );
  }

  Widget _savedPhotoTile(LotPhoto photo, int index, {required bool offline}) =>
      _PhotoTile(
        key: ValueKey('lot-photo-${photo.id}'),
        image: Image.network(
          photo.url,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const _PhotoPlaceholder(),
        ),
        label: index == 0 ? 'Portada' : 'Foto ${index + 1}',
        onRemove: offline || _photoBusy || _submitting
            ? null
            : () => _removeSavedPhoto(photo),
        onMoveBack: offline || index == 0 || _photoBusy || _submitting
            ? null
            : () => _moveSavedPhoto(index, -1),
        onMoveForward:
            offline || index == _photos.length - 1 || _photoBusy || _submitting
                ? null
                : () => _moveSavedPhoto(index, 1),
      );

  Widget _pendingPhotoTile(_PendingLotPhoto photo) => _PhotoTile(
        key: ValueKey('pending-lot-photo-${photo.id}'),
        image: Image.memory(photo.bytes, fit: BoxFit.cover),
        label: 'Pendiente de guardar',
        onRemove: _submitting || _photoBusy
            ? null
            : () => setState(() => _pendingPhotos.remove(photo)),
      );

  Future<void> _createProduct() async {
    final proposal = await showModalBottomSheet<ProductProposal>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _CreateProductSheet(),
    );
    if (proposal == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content:
          Text('Propuesta enviada. Quedará disponible cuando sea aprobada.'),
    ));
    context.push('/catalogo/propuestas');
  }

  void _leave() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/lotes');
    }
  }

  Future<void> _back() async {
    if (_dirty && !await _confirmLeave()) return;
    if (mounted) _leave();
  }

  Future<bool> _confirmLeave() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(LotFormStrings.leaveTitle),
        content: const Text(LotFormStrings.leaveBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(LotFormStrings.keepEditing),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style:
                FilledButton.styleFrom(backgroundColor: AppTheme.dangerStrong),
            child: const Text(LotFormStrings.leave),
          ),
        ],
      ),
    );
    if (leave == true) _baseline = _signature;
    return leave == true;
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

    if (widget.lotId != null && !_hydrated) {
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

    if (widget.lotId != null && existing!.valueOrNull?.status != 'draft') {
      return _FormScaffold(
        title: 'Editar lote',
        onBack: _back,
        child: _NonDraftState(onBack: _back),
      );
    }

    // Atras del sistema pide confirmar si hay cambios sin guardar.
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop && await _confirmLeave() && mounted) _leave();
      },
      child: _buildForm(products, isSeller, offline),
    );
  }

  Widget _buildForm(
      AsyncValue<List<Product>> products, bool isSeller, bool offline) {
    final wide = MediaQuery.sizeOf(context).width >= 760;
    final estimatedSubtotal = _estimatedSubtotal();
    return _FormScaffold(
      title: isEditing ? 'Editar lote' : 'Nuevo lote',
      onBack: _back,
      subtitle: isEditing
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
                isEditing: isEditing,
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
            _photosSection(offline: offline),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_usingProfilePoint && _matchesProfilePoint) ...[
                    Row(children: [
                      const Icon(Icons.place_outlined,
                          size: 18, color: AppTheme.forest),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(LotFormStrings.profilePointUsed,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppTheme.forest)),
                      ),
                    ]),
                    const SizedBox(height: 12),
                  ],
                  if (_profilePoint != null && !_matchesProfilePoint) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: _submitting
                            ? null
                            : () => setState(_applyProfilePoint),
                        icon: const Icon(Icons.my_location_outlined),
                        label: const Text(LotFormStrings.useProfilePoint),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  _locationFields(wide),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _FormActions(
              submitting: _submitting,
              isEditing: isEditing,
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

  Widget _locationFields(bool wide) => _ResponsiveRow(
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
            onChanged: (_) => _clearFieldErrors(['latitude', 'longitude']),
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
            onChanged: (_) => _clearFieldErrors(['latitude', 'longitude']),
            decoration: InputDecoration(
              labelText: 'Longitud',
              hintText: '-73.3678',
              errorText: _fieldErrors['longitude'],
            ),
          ),
        ],
      );

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
            color: highlighted ? AppTheme.dangerStrong : AppTheme.outline,
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

class _PendingLotPhoto {
  const _PendingLotPhoto({
    required this.id,
    required this.file,
    required this.bytes,
  });

  final String id;
  final XFile file;
  final Uint8List bytes;
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({
    required this.image,
    required this.label,
    required this.onRemove,
    this.onMoveBack,
    this.onMoveForward,
    super.key,
  });

  final Widget image;
  final String label;
  final VoidCallback? onRemove;
  final VoidCallback? onMoveBack;
  final VoidCallback? onMoveForward;

  @override
  Widget build(BuildContext context) => Container(
        width: 168,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(height: 88, child: image),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (onMoveBack != null || onMoveForward != null) ...[
                  IconButton(
                    tooltip: 'Mover antes',
                    onPressed: onMoveBack,
                    icon: const Icon(Icons.chevron_left_rounded, size: 20),
                  ),
                  IconButton(
                    tooltip: 'Mover después',
                    onPressed: onMoveForward,
                    icon: const Icon(Icons.chevron_right_rounded, size: 20),
                  ),
                ],
                IconButton(
                  tooltip: 'Quitar foto',
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline_rounded,
                      size: 20, color: AppTheme.dangerStrong),
                ),
              ],
            ),
          ],
        ),
      );
}

class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder();

  @override
  Widget build(BuildContext context) => Container(
        color: AppTheme.mint.withValues(alpha: 0.4),
        alignment: Alignment.center,
        child: const Icon(Icons.image_not_supported_outlined,
            color: AppTheme.forest),
      );
}

String _photoErrorText(DomainFailure failure) => switch (failure.code) {
      'photo_limit' => 'Este lote ya tiene el máximo de 5 fotos.',
      'photo_size_invalid' => 'La foto supera el tamaño permitido de 5 MB.',
      'photo_format_invalid' => 'Usa una foto JPG, PNG o WebP.',
      'photo_processing' =>
        'La foto sigue procesándose. Actualiza el lote en un momento.',
      'forbidden' => 'No tienes permiso para modificar las fotos de este lote.',
      'not_found' =>
        'No encontramos el lote o la foto. Actualiza e intenta otra vez.',
      'storage_unavailable' ||
      'storage_upload_failed' =>
        'No se pudo cargar la foto. Revisa tu conexión e intenta de nuevo.',
      _ => 'No pudimos guardar la foto. Intenta de nuevo.',
    };

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
        SearchableSheetSelector<String>(
          key: const ValueKey('lot-product-selector'),
          label: 'Producto',
          value: productId,
          hint: products.isLoading && items.isEmpty
              ? 'Cargando productos…'
              : 'Selecciona',
          errorText: errorMessage,
          enabled: enabled && items.isNotEmpty,
          options: [
            for (final product in items)
              SelectorOption(
                  value: product.id,
                  label: '${product.name} · ${product.unit}'),
            if (isEditing && selectedMissing)
              SelectorOption(value: productId!, label: 'Producto actual'),
          ],
          onChanged: onChanged,
        ),
        if (!products.isLoading && !products.hasError && items.isEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'No hay productos disponibles en el catálogo todavía.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: errorMessage != null
                      ? AppTheme.dangerStrong
                      : AppTheme.mutedText,
                ),
          ),
        ],
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: canCreateProduct ? onCreateProduct : null,
          icon: const Icon(Icons.add_rounded),
          label: const Text('No encuentro mi producto · Proponer producto'),
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
    setState(() {
      _saving = true;
      _error = null;
    });
    final result = await ref.read(productProposalRepositoryProvider).create(
          CreateProductProposalRequest(
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
                      'Proponer producto',
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
                  'La propuesta será revisada antes de aparecer en el catálogo.'),
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
              SearchableSheetSelector<String>(
                key: const ValueKey('new-product-category'),
                label: 'Categoría',
                value: selectedCategory,
                hint: categories.isLoading
                    ? 'Cargando categorías…'
                    : 'Selecciona',
                enabled: !_saving && items.isNotEmpty,
                options: items
                    .map((category) => SelectorOption(
                        value: category.id, label: category.name))
                    .toList(growable: false),
                onChanged: (value) => setState(() {
                  _categoryId = value;
                  _error = null;
                }),
              ),
              const SizedBox(height: 12),
              Text('Unidad de venta',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              OptionCardGrid<String>(
                value: _unit,
                options: _units.entries
                    .map((unit) =>
                        SelectorOption(value: unit.key, label: unit.value))
                    .toList(growable: false),
                onChanged:
                    _saving ? (_) {} : (value) => setState(() => _unit = value),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Semantics(
                  liveRegion: true,
                  child: Text(_error!,
                      style: const TextStyle(color: AppTheme.dangerStrong)),
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
                    : const Text('Enviar propuesta'),
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
          color: AppTheme.warningSurface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(Icons.cloud_off_outlined,
                color: AppTheme.warningIcon, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Sin conexión. El lote se guardará localmente y se sincronizará después.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.warningText,
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
            color: AppTheme.dangerSurface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Icon(Icons.error_outline,
                  color: AppTheme.dangerStrong, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.dangerText,
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

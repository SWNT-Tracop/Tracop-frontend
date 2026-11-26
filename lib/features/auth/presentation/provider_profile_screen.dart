import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';

import '../../../app/messenger.dart';
import '../../../app/motion.dart';
import '../../../app/theme.dart';
import '../../../core/config/colombia_locations.dart';
import '../../../core/i18n/strings.dart';
import '../../../core/result/result.dart';
import '../../../shared/widgets/option_selectors.dart';
import '../../home/presentation/home_screen.dart';
import '../domain/entities/auth_session.dart';
import 'providers/auth_provider.dart';
import '../../../shared/widgets/pickup_point_picker.dart';

typedef _S = ProviderProfileStrings;

const _storageTimeout = Duration(milliseconds: 250);
const _minNameLength = 2;
const _maxNameLength = 100;
const _maxDescriptionLength = 1000;
const _lastStep = 3;
const _producerTypeIcons = [
  Icons.agriculture_outlined,
  Icons.groups_outlined,
  Icons.store_outlined
];

class ProviderProfileScreen extends ConsumerStatefulWidget {
  const ProviderProfileScreen({this.onboarding = false, super.key});
  final bool onboarding;
  @override
  ConsumerState<ProviderProfileScreen> createState() =>
      _ProviderProfileScreenState();
}

class _ProviderProfileScreenState extends ConsumerState<ProviderProfileScreen> {
  final _displayName = TextEditingController(),
      _description = TextEditingController();
  final _lat = TextEditingController(), _lng = TextEditingController();
  final _storage = const FlutterSecureStorage();
  String? _department, _municipality, _error;
  int _step = 0;
  bool _loading = true,
      _saving = false,
      _success = false,
      _draftRestored = false;
  String _producerType = _S.producerTypes.first;
  String get _draftKey =>
      'provider_profile_draft_v1_${ref.read(authProvider).valueOrNull?.user.id ?? 'unknown'}';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _displayName.dispose();
    _description.dispose();
    _lat.dispose();
    _lng.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final raw = await _storage
          .read(key: _draftKey)
          .timeout(_storageTimeout, onTimeout: () => null);
      if (raw != null) {
        final draft = jsonDecode(raw) as Map<String, dynamic>;
        _displayName.text = draft['displayName'] as String? ?? '';
        _description.text = draft['description'] as String? ?? '';
        _lat.text = draft['lat'] as String? ?? '';
        _lng.text = draft['lng'] as String? ?? '';
        _department = draft['department'] as String?;
        _municipality = draft['municipality'] as String?;
        _producerType = draft['producerType'] as String? ?? _producerType;
        _step = (draft['step'] as int? ?? 0).clamp(0, _lastStep);
        _draftRestored = _displayName.text.isNotEmpty || _step > 0;
      }
    } catch (_) {}
    final result =
        await ref.read(authRepositoryProvider).getStoredProviderProfile();
    result.map(
        ok: (value) {
          final profile = value.value;
          if (profile != null && _displayName.text.isEmpty) {
            _displayName.text = profile.displayName;
            _municipality = profile.municipality;
            _department = profile.department;
            _lat.text = profile.lat.toString();
            _lng.text = profile.lng.toString();
            _description.text = profile.description;
          }
        },
        err: (_) {});
    final (department, municipality) =
        ColombiaLocations.resolve(_department, _municipality);
    _department = department;
    _municipality = municipality;
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _saveDraft() async {
    try {
      await _storage
          .write(
              key: _draftKey,
              value: jsonEncode({
                'displayName': _displayName.text,
                'department': _department,
                'municipality': _municipality,
                'lat': _lat.text,
                'lng': _lng.text,
                'description': _description.text,
                'producerType': _producerType,
                'step': _step
              }))
          .timeout(_storageTimeout);
    } catch (_) {}
  }

  void _changed() {
    _saveDraft();
    if (_error != null) setState(() => _error = null);
  }

  String? _validateStep() {
    if (_step == 0 && _displayName.text.trim().length < _minNameLength) {
      return _S.nameRequired;
    }
    if (_step == 1 && (_department == null || _municipality == null)) {
      return _S.locationRequired;
    }
    if (_step == 2) {
      final lat = _coordinate(_lat.text), lng = _coordinate(_lng.text);
      if (lat == null || lng == null) return _S.pointRequired;
      if (!ColombiaBounds.contains(lat, lng)) return _S.pointOutside;
    }
    if (_step == _lastStep &&
        _description.text.length > _maxDescriptionLength) {
      return _S.descriptionTooLong(_maxDescriptionLength);
    }
    return null;
  }

  double? _coordinate(String value) {
    final n = double.tryParse(value.trim().replaceAll(',', '.'));
    return n != null && n.isFinite ? n : null;
  }

  void _goToStep(int step) {
    FocusScope.of(context).unfocus();
    setState(() {
      _step = step;
      _error = null;
    });
    _saveDraft();
  }

  Future<void> _next() async {
    FocusScope.of(context).unfocus();
    final invalid = _validateStep();
    if (invalid != null) {
      setState(() => _error = invalid);
      HapticFeedback.mediumImpact();
      return;
    }
    if (_step < _lastStep) {
      _goToStep(_step + 1);
      return;
    }
    await _save();
  }

  void _leave() {
    if (!_success && _displayName.text.trim().isNotEmpty) {
      showAppNotice(_S.draftKept, icon: Icons.save_outlined);
    }
    context.go(widget.onboarding ? '/' : '/perfil');
  }

  Future<void> _save() async {
    final offline = ref.read(homeConnectivityProvider).valueOrNull == false;
    if (offline) {
      setState(() => _error = _S.offlineSave);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final result = await ref.read(authRepositoryProvider).upsertProviderProfile(
        UpsertProviderProfileRequest(
            displayName: _displayName.text.trim(),
            municipality: _municipality!,
            department: _department!,
            lat: _coordinate(_lat.text)!,
            lng: _coordinate(_lng.text)!,
            description: _description.text.trim()));
    if (!mounted) return;
    switch (result) {
      case Ok():
        try {
          await _storage.delete(key: _draftKey).timeout(_storageTimeout);
        } catch (_) {}
        setState(() {
          _saving = false;
          _success = true;
        });
      case Err(:final error):
        setState(() {
          _saving = false;
          _error = _S.error(error.code);
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(authProvider).valueOrNull?.user.role;
    final offline = ref.watch(homeConnectivityProvider).valueOrNull == false;
    if (role != null && role != 'producer' && role != 'supplier') {
      return const Scaffold(body: Center(child: Text(_S.onlyProducers)));
    }
    if (_success) return _successScreen();
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    const total = _lastStep + 1;
    // Atras del sistema regresa un paso antes de salir del formulario.
    return PopScope(
      canPop: _step == 0 && !_saving,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _step > 0 && !_saving) _goToStep(_step - 1);
      },
      child: Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
              title: const Text(_S.title),
              leading: IconButton(
                  tooltip: CommonStrings.back,
                  onPressed: _saving ? null : _leave,
                  icon: const Icon(Icons.arrow_back))),
          body: SafeArea(
              child: Column(children: [
            Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(_S.stepOf(_step + 1, total, _S.steps[_step]),
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 10),
                      TweenAnimationBuilder<double>(
                          tween: Tween(end: (_step + 1) / total),
                          duration: AppMotion.of(context, AppMotion.medium),
                          builder: (context, v, _) => LinearProgressIndicator(
                              value: v,
                              minHeight: 6,
                              borderRadius: BorderRadius.circular(6))),
                      if (offline)
                        const Padding(
                            padding: EdgeInsets.only(top: 12),
                            child: _Notice(
                                icon: Icons.cloud_off_outlined,
                                text: _S.offline)),
                      if (_draftRestored)
                        Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: _Notice(
                                icon: Icons.restore_outlined,
                                text: _S.draftRestored,
                                onClose: () =>
                                    setState(() => _draftRestored = false))),
                    ])),
            Expanded(
                child: AnimatedSwitcher(
                    duration: AppMotion.of(context, AppMotion.medium),
                    transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                            position: Tween(
                                    begin: const Offset(.04, 0),
                                    end: Offset.zero)
                                .animate(animation),
                            child: child)),
                    child: SingleChildScrollView(
                        key: ValueKey(_step),
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                        child: _stepContent()))),
            if (_error != null)
              Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Semantics(
                      liveRegion: true,
                      child: Text(_error!,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.error)))),
            Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  if (_step > 0)
                    Expanded(
                        child: OutlinedButton(
                            onPressed:
                                _saving ? null : () => _goToStep(_step - 1),
                            child: const Text(CommonStrings.previous))),
                  if (_step > 0) const SizedBox(width: 12),
                  Expanded(
                      child: FilledButton(
                          onPressed: _saving ? null : _next,
                          child: _saving
                              ? const SizedBox.square(
                                  dimension: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2))
                              : Text(_step == _lastStep
                                  ? _S.saveProfile
                                  : CommonStrings.next)))
                ]))
          ]))),
    );
  }

  Widget _stepContent() => switch (_step) {
        0 => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const _StepIntro(
                icon: Icons.storefront_outlined,
                title: _S.nameTitle,
                body: _S.nameBody),
            const SizedBox(height: 20),
            TextField(
                controller: _displayName,
                maxLength: _maxNameLength,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: _S.nameLabel),
                onChanged: (_) => _changed(),
                onSubmitted: (_) => _next()),
            const SizedBox(height: 20),
            Text(_S.producerTypeTitle,
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 10),
            OptionCircleSelector<String>(
                value: _producerType,
                onChanged: (v) {
                  setState(() => _producerType = v);
                  _saveDraft();
                },
                options: [
                  for (var i = 0; i < _S.producerTypes.length; i++)
                    SelectorOption(
                        value: _S.producerTypes[i],
                        label: _S.producerTypes[i],
                        icon: _producerTypeIcons[i]),
                ])
          ]),
        1 => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const _StepIntro(
                icon: Icons.map_outlined,
                title: _S.locationTitle,
                body: _S.locationBody),
            const SizedBox(height: 20),
            SearchableSheetSelector<String>(
                label: _S.department,
                hint: _S.departmentHint,
                options: ColombiaLocations.departments
                    .map((department) => SelectorOption(
                        value: department.name, label: department.name))
                    .toList(),
                value: _department,
                onChanged: (value) {
                  setState(() {
                    if (value != _department) _municipality = null;
                    _department = value;
                    _error = null;
                  });
                  _saveDraft();
                }),
            const SizedBox(height: 12),
            SearchableSheetSelector<String>(
                label: _S.municipality,
                hint: _department == null
                    ? _S.municipalityLocked
                    : _S.municipalityHint,
                options: (ColombiaLocations.department(_department)
                            ?.municipalities ??
                        const <ColombiaMunicipality>[])
                    .map((municipality) => SelectorOption(
                        value: municipality.name, label: municipality.name))
                    .toList(),
                value: _municipality,
                enabled: _department != null,
                onChanged: (value) {
                  setState(() {
                    _municipality = value;
                    _error = null;
                  });
                  _saveDraft();
                })
          ]),
        2 => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const _StepIntro(
                icon: Icons.location_on_outlined,
                title: _S.pointTitle,
                body: _S.pointBody),
            const SizedBox(height: 16),
            PickupPointPicker(
                lat: _coordinate(_lat.text),
                lng: _coordinate(_lng.text),
                onSelect: _mapSelection,
                reference: switch (_municipalityCentre()) {
                  final centre? => PickupReference(
                      label: _S.useMunicipalityCentre(centre.name),
                      lat: centre.lat,
                      lng: centre.lng),
                  null => null,
                }),
            const SizedBox(height: 8),
            const Row(children: [
              Icon(Icons.lock_outline, size: 18),
              SizedBox(width: 8),
              Expanded(child: Text(_S.privacy))
            ]),
          ]),
        _ => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const _StepIntro(
                icon: Icons.shopping_basket_outlined,
                title: _S.offerTitle,
                body: _S.offerBody),
            const SizedBox(height: 18),
            TextField(
                controller: _description,
                maxLength: _maxDescriptionLength,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                    labelText: _S.descriptionLabel,
                    hintText: _S.descriptionHint),
                onChanged: (_) => _changed()),
            Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _S.descriptionChips
                    .map((chip) => ActionChip(
                        label: Text(chip),
                        onPressed: () {
                          final text = _description.text.trim();
                          _description.text = text.isEmpty
                              ? chip
                              : '$text${_S.chipSeparator}$chip';
                          _description.selection = TextSelection.collapsed(
                              offset: _description.text.length);
                          setState(() {});
                          _saveDraft();
                        }))
                    .toList()),
            const SizedBox(height: 24),
            Card(
                child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_S.reviewTitle,
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 6),
                          _ReviewRow(
                              label: _S.reviewOperation,
                              value:
                                  '${_displayName.text.trim()} · $_producerType',
                              onEdit: () => _goToStep(0)),
                          _ReviewRow(
                              label: _S.reviewLocation,
                              value:
                                  '${_municipality ?? CommonStrings.empty}, ${_department ?? CommonStrings.empty}',
                              onEdit: () => _goToStep(1)),
                          _ReviewRow(
                              label: _S.reviewPoint,
                              value: '${_lat.text}, ${_lng.text}',
                              onEdit: () => _goToStep(2)),
                          _ReviewRow(
                              label: _S.reviewDescription,
                              value: _description.text.trim().isEmpty
                                  ? _S.noDescription
                                  : _description.text.trim()),
                        ])))
          ]),
      };

  ColombiaMunicipality? _municipalityCentre() =>
      ColombiaLocations.municipality(_department, _municipality);

  void _mapSelection(double lat, double lng) {
    setState(() {
      _lat.text = lat.toStringAsFixed(ColombiaBounds.coordinateDecimals);
      _lng.text = lng.toStringAsFixed(ColombiaBounds.coordinateDecimals);
      _error = null;
    });
    _saveDraft();
    HapticFeedback.selectionClick();
  }

  Widget _successScreen() => Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
          child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                TweenAnimationBuilder<double>(
                    tween: Tween(begin: .5, end: 1),
                    duration: AppMotion.of(context, AppMotion.medium),
                    builder: (context, scale, child) =>
                        Transform.scale(scale: scale, child: child),
                    child: const CircleAvatar(
                        radius: 48,
                        backgroundColor: AppTheme.mint,
                        child: Icon(Icons.check_rounded,
                            size: 52, color: AppTheme.forest))),
                const SizedBox(height: 24),
                Text(_S.savedTitle,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                const Text(_S.savedBody),
                const SizedBox(height: 24),
                SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                        onPressed: () => context.go('/lotes/nuevo'),
                        icon: const Icon(Icons.add),
                        label: const Text(_S.firstLot))),
                TextButton(
                    onPressed: () =>
                        context.go(widget.onboarding ? '/' : '/perfil'),
                    child:
                        Text(widget.onboarding ? _S.goHome : _S.backToAccount))
              ]))));
}

class _StepIntro extends StatelessWidget {
  const _StepIntro(
      {required this.icon, required this.title, required this.body});
  final IconData icon;
  final String title, body;
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: AppTheme.forest, size: 32),
        const SizedBox(height: 10),
        Text(title,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(body)
      ]);
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.label, required this.value, this.onEdit});
  final String label, value;
  final VoidCallback? onEdit;
  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(
            child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text('$label: $value'))),
        if (onEdit != null)
          IconButton(
              tooltip: _S.editSection(label.toLowerCase()),
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined, size: 20)),
      ]);
}

// Mapa esquematico: el pin se ubica donde quedo el punto elegido.
class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.text, this.onClose});
  final IconData icon;
  final String text;
  final VoidCallback? onClose;
  @override
  Widget build(BuildContext context) => Container(
      padding: EdgeInsets.fromLTRB(12, 12, onClose == null ? 12 : 0, 12),
      decoration: BoxDecoration(
          color: AppTheme.warningSurface,
          borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        Icon(icon, color: AppTheme.warningIcon),
        const SizedBox(width: 8),
        Expanded(
            child: Text(text,
                style: const TextStyle(color: AppTheme.warningText))),
        if (onClose != null)
          IconButton(
              tooltip: CommonStrings.understood,
              onPressed: onClose,
              icon: const Icon(Icons.close, size: 18)),
      ]));
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/result/result.dart';
import '../../home/presentation/home_screen.dart';
import '../domain/entities/auth_session.dart';
import 'providers/auth_provider.dart';

class ProviderProfileScreen extends ConsumerStatefulWidget {
  const ProviderProfileScreen({this.onboarding = false, super.key});

  final bool onboarding;

  @override
  ConsumerState<ProviderProfileScreen> createState() =>
      _ProviderProfileScreenState();
}

class _ProviderProfileScreenState extends ConsumerState<ProviderProfileScreen> {
  final _displayName = TextEditingController();
  final _municipality = TextEditingController();
  final _department = TextEditingController();
  final _lat = TextEditingController();
  final _lng = TextEditingController();
  final _description = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _displayName.dispose();
    _municipality.dispose();
    _department.dispose();
    _lat.dispose();
    _lng.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final result =
        await ref.read(authRepositoryProvider).getStoredProviderProfile();
    if (!mounted) return;
    result.map(
      ok: (value) {
        final profile = value.value;
        if (profile != null) {
          _displayName.text = profile.displayName;
          _municipality.text = profile.municipality;
          _department.text = profile.department;
          _lat.text = profile.lat.toString();
          _lng.text = profile.lng.toString();
          _description.text = profile.description;
        }
      },
      err: (_) {},
    );
    setState(() => _loading = false);
  }

  String? _validate() {
    if (_displayName.text.trim().length < 2 ||
        _displayName.text.trim().length > 100) {
      return 'El nombre público debe tener entre 2 y 100 caracteres.';
    }
    if (_municipality.text.trim().isEmpty ||
        _municipality.text.trim().length > 100) {
      return 'Escribe el municipio donde está tu operación.';
    }
    if (_department.text.trim().isEmpty ||
        _department.text.trim().length > 100) {
      return 'Escribe el departamento.';
    }
    final lat = _parseCoordinate(_lat.text);
    final lng = _parseCoordinate(_lng.text);
    if (lat == null || lng == null) {
      return 'Ingresa una latitud y longitud válidas.';
    }
    if (lat < -4.3 || lat > 13.7 || lng < -81.8 || lng > -66.9) {
      return 'La ubicación debe estar dentro de Colombia.';
    }
    if (_description.text.length > 1000) {
      return 'La descripción no puede superar 1000 caracteres.';
    }
    return null;
  }

  double? _parseCoordinate(String raw) {
    final value = double.tryParse(raw.trim().replaceAll(',', '.'));
    return value != null && value.isFinite ? value : null;
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    final offline = ref.read(homeConnectivityProvider).valueOrNull == false;
    final validation = _validate();
    if (validation != null) {
      setState(() => _error = validation);
      return;
    }
    if (offline) {
      setState(() => _error =
          'Necesitas conexión para guardar el perfil. Intenta cuando tengas señal.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final result = await ref.read(authRepositoryProvider).upsertProviderProfile(
          UpsertProviderProfileRequest(
            displayName: _displayName.text.trim(),
            municipality: _municipality.text.trim(),
            department: _department.text.trim(),
            lat: _parseCoordinate(_lat.text)!,
            lng: _parseCoordinate(_lng.text)!,
            description: _description.text.trim(),
          ),
        );
    if (!mounted) return;
    switch (result) {
      case Ok():
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Perfil de proveedor guardado.'),
          backgroundColor: AppTheme.forest,
        ));
        context.go(widget.onboarding ? '/' : '/perfil');
      case Err(:final error):
        setState(() {
          _saving = false;
          _error = _profileErrorText(error);
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(authProvider).valueOrNull?.user.role;
    final offline = ref.watch(homeConnectivityProvider).valueOrNull == false;
    if (role != null && role != 'producer' && role != 'supplier') {
      return const Scaffold(
        body: Center(
            child: Text('Esta sección es para productores y proveedores.')),
      );
    }
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                    children: [
                      IconButton(
                        alignment: Alignment.centerLeft,
                        tooltip: 'Volver',
                        onPressed: () =>
                            context.go(widget.onboarding ? '/' : '/perfil'),
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                      Text(
                        'Perfil de proveedor',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              color: AppTheme.forest,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(widget.onboarding
                          ? 'Completa estos datos para que compradores conozcan tu oferta. Puedes hacerlo ahora o más tarde; los necesitas para publicar lotes.'
                          : 'Estos datos ayudan a los compradores a conocer tu operación. La ubicación exacta se usa para coordinar recogidas.'),
                      if (offline) ...[
                        const SizedBox(height: 16),
                        const _ProfileOfflineNotice(),
                      ],
                      const SizedBox(height: 20),
                      _ProfileSection(
                        title: 'Tu operación',
                        child: Column(
                          children: [
                            TextField(
                              key: const ValueKey('displayName'),
                              controller: _displayName,
                              enabled: !_saving,
                              maxLength: 100,
                              textCapitalization: TextCapitalization.words,
                              decoration: const InputDecoration(
                                labelText: 'Nombre público *',
                                hintText: 'Finca o nombre de tu negocio',
                              ),
                            ),
                            const SizedBox(height: 12),
                            _ProfileResponsiveRow(
                              children: [
                                TextField(
                                  key: const ValueKey('municipality'),
                                  controller: _municipality,
                                  enabled: !_saving,
                                  maxLength: 100,
                                  textCapitalization: TextCapitalization.words,
                                  decoration: const InputDecoration(
                                    labelText: 'Municipio *',
                                  ),
                                ),
                                TextField(
                                  key: const ValueKey('department'),
                                  controller: _department,
                                  enabled: !_saving,
                                  maxLength: 100,
                                  textCapitalization: TextCapitalization.words,
                                  decoration: const InputDecoration(
                                    labelText: 'Departamento *',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _ProfileSection(
                        title: 'Ubicación de recogida',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                                'La ubicación exacta no se muestra a compradores.'),
                            const SizedBox(height: 12),
                            _ProfileResponsiveRow(
                              children: [
                                TextField(
                                  key: const ValueKey('latitude'),
                                  controller: _lat,
                                  enabled: !_saving,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true, signed: true),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                        RegExp(r'[0-9.,-]')),
                                  ],
                                  decoration: const InputDecoration(
                                    labelText: 'Latitud *',
                                    hintText: '5.5353',
                                  ),
                                ),
                                TextField(
                                  key: const ValueKey('longitude'),
                                  controller: _lng,
                                  enabled: !_saving,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true, signed: true),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                        RegExp(r'[0-9.,-]')),
                                  ],
                                  decoration: const InputDecoration(
                                    labelText: 'Longitud *',
                                    hintText: '-73.3678',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Puedes consultar las coordenadas del punto de recogida en un mapa. Deben estar dentro de Colombia.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppTheme.mutedText,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _ProfileSection(
                        title: 'Sobre tu oferta',
                        child: TextField(
                          controller: _description,
                          enabled: !_saving,
                          maxLength: 1000,
                          maxLines: 4,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: const InputDecoration(
                            labelText: 'Descripción (opcional)',
                            hintText:
                                'Cuéntales a los compradores sobre tus productos o cosechas.',
                            alignLabelWithHint: true,
                          ),
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        Semantics(
                          liveRegion: true,
                          child: Text(_error!,
                              style: const TextStyle(color: Color(0xFFB3261E))),
                        ),
                      ],
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: _saving || offline ? null : _save,
                        child: _saving
                            ? const SizedBox.square(
                                dimension: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Guardar perfil'),
                      ),
                      if (widget.onboarding) ...[
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _saving ? null : () => context.go('/'),
                          child: const Text('Lo haré más tarde'),
                        ),
                      ],
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

String _profileErrorText(DomainFailure failure) => switch (failure.code) {
      'invalid_profile' =>
        'Revisa el nombre público, municipio, departamento y descripción.',
      'invalid_coordinates' => 'La ubicación debe estar dentro de Colombia.',
      'forbidden' =>
        'Solo productores y proveedores pueden guardar este perfil.',
      'network_error' =>
        'Sin conexión. Intenta guardar el perfil cuando tengas señal.',
      _ =>
        'No pudimos guardar el perfil. Verifica los datos e intenta de nuevo.',
    };

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppTheme.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.forest,
                      fontWeight: FontWeight.w700,
                    )),
            const SizedBox(height: 14),
            child,
          ],
        ),
      );
}

class _ProfileResponsiveRow extends StatelessWidget {
  const _ProfileResponsiveRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.sizeOf(context).width < 600) {
      return Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            children[i],
          ],
        ],
      );
    }
    return Row(
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          Expanded(child: children[i]),
        ],
      ],
    );
  }
}

class _ProfileOfflineNotice extends StatelessWidget {
  const _ProfileOfflineNotice();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3CD),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Text(
          'Sin conexión. Puedes completar los datos, pero guardar requiere señal.',
          style: TextStyle(color: Color(0xFF553B00)),
        ),
      );
}

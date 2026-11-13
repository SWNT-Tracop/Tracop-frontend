import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/result/result.dart';
import '../../../shared/widgets/option_selectors.dart';
import '../../home/presentation/home_screen.dart';
import '../domain/entities/auth_session.dart';
import 'providers/auth_provider.dart';

const _departments = <String, List<String>>{
  'Boyacá': [
    'Tunja',
    'Duitama',
    'Sogamoso',
    'Chiquinquirá',
    'Villa de Leyva',
    'Paipa',
    'Tibasosa'
  ],
  'Cundinamarca': [
    'Bogotá',
    'Fusagasugá',
    'Zipaquirá',
    'Facatativá',
    'Chía',
    'Ubaté',
    'La Mesa',
    'Girardot'
  ],
  'Antioquia': ['Medellín', 'Rionegro', 'La Ceja', 'Marinilla', 'Apartadó'],
  'Santander': ['Bucaramanga', 'Floridablanca', 'Piedecuesta', 'San Gil'],
  'Valle del Cauca': ['Cali', 'Palmira', 'Tuluá', 'Buga'],
  'Nariño': ['Pasto', 'Ipiales', 'Tumaco'],
};

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
      _manualCoordinates = false,
      _success = false;
  String _producerType = 'Finca familiar';
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
          .timeout(const Duration(milliseconds: 250), onTimeout: () => null);
      if (raw != null) {
        final draft = jsonDecode(raw) as Map<String, dynamic>;
        _displayName.text = draft['displayName'] as String? ?? '';
        _description.text = draft['description'] as String? ?? '';
        _lat.text = draft['lat'] as String? ?? '';
        _lng.text = draft['lng'] as String? ?? '';
        _department = draft['department'] as String?;
        _municipality = draft['municipality'] as String?;
        _producerType = draft['producerType'] as String? ?? _producerType;
        _step = (draft['step'] as int? ?? 0).clamp(0, 3);
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
          .timeout(const Duration(milliseconds: 250));
    } catch (_) {}
  }

  void _changed() {
    _saveDraft();
    if (_error != null) setState(() => _error = null);
  }

  String? _validateStep() {
    if (_step == 0 && _displayName.text.trim().length < 2) {
      return 'Escribe el nombre de tu finca o negocio.';
    }
    if (_step == 1 && (_department == null || _municipality == null)) {
      return 'Elige primero el departamento y luego el municipio.';
    }
    if (_step == 2) {
      final lat = _coordinate(_lat.text), lng = _coordinate(_lng.text);
      if (lat == null || lng == null) {
        return 'Elige el punto de recogida en el mapa o usa la opción manual.';
      }
      if (lat < -4.3 || lat > 13.7 || lng < -81.8 || lng > -66.9) {
        return 'Elige un punto dentro de Colombia.';
      }
    }
    if (_step == 3 && _description.text.length > 1000) {
      return 'La descripción no puede superar 1000 caracteres.';
    }
    return null;
  }

  double? _coordinate(String value) {
    final n = double.tryParse(value.trim().replaceAll(',', '.'));
    return n != null && n.isFinite ? n : null;
  }

  Future<void> _next() async {
    FocusScope.of(context).unfocus();
    final invalid = _validateStep();
    if (invalid != null) {
      setState(() => _error = invalid);
      HapticFeedback.mediumImpact();
      return;
    }
    if (_step < 3) {
      setState(() {
        _step++;
        _error = null;
      });
      await _saveDraft();
      return;
    }
    await _save();
  }

  Future<void> _save() async {
    final offline = ref.read(homeConnectivityProvider).valueOrNull == false;
    if (offline) {
      setState(() => _error =
          'Guardamos tu borrador en este dispositivo. Conéctate para enviar el perfil.');
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
          await _storage
              .delete(key: _draftKey)
              .timeout(const Duration(milliseconds: 250));
        } catch (_) {}
        setState(() {
          _saving = false;
          _success = true;
        });
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
          body: Center(child: Text('Esta sección es solo para productores.')));
    }
    if (_success) return _successScreen();
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final steps = [
      'Tu operación',
      'Ubicación',
      'Punto de recogida',
      'Sobre tu oferta'
    ];
    return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
            title: const Text('Perfil de proveedor'),
            leading: IconButton(
                tooltip: 'Volver',
                onPressed: () =>
                    context.go(widget.onboarding ? '/' : '/perfil'),
                icon: const Icon(Icons.arrow_back))),
        body: SafeArea(
            child: Column(children: [
          Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Paso ${_step + 1} de 4 · ${steps[_step]}',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),
                    TweenAnimationBuilder<double>(
                        tween: Tween(end: (_step + 1) / 4),
                        duration: MediaQuery.disableAnimationsOf(context)
                            ? Duration.zero
                            : const Duration(milliseconds: 300),
                        builder: (context, v, _) => LinearProgressIndicator(
                            value: v,
                            minHeight: 6,
                            borderRadius: BorderRadius.circular(6))),
                    if (offline)
                      const Padding(
                          padding: EdgeInsets.only(top: 12),
                          child: _OfflineNotice())
                  ])),
          Expanded(
              child: AnimatedSwitcher(
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 280),
                  transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                          position: Tween(
                                  begin: const Offset(.04, 0), end: Offset.zero)
                              .animate(animation),
                          child: child)),
                  child: SingleChildScrollView(
                      key: ValueKey(_step),
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
                          onPressed: _saving
                              ? null
                              : () => setState(() {
                                    _step--;
                                    _error = null;
                                  }),
                          child: const Text('Atrás'))),
                if (_step > 0) const SizedBox(width: 12),
                Expanded(
                    child: FilledButton(
                        onPressed: _saving ? null : _next,
                        child: _saving
                            ? const SizedBox.square(
                                dimension: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : Text(
                                _step == 3 ? 'Guardar perfil' : 'Siguiente')))
              ]))
        ])));
  }

  Widget _stepContent() => switch (_step) {
        0 => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const _StepIntro(
                icon: Icons.storefront_outlined,
                title: '¿Cómo se llama tu operación?',
                body:
                    'Este nombre lo verán las personas que buscan tus productos.'),
            const SizedBox(height: 20),
            TextField(
                controller: _displayName,
                maxLength: 100,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                    labelText: 'Nombre de la finca o negocio'),
                onChanged: (_) => _changed()),
            const SizedBox(height: 20),
            Text('¿Cómo produces?',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 10),
            OptionCircleSelector<String>(
                value: _producerType,
                onChanged: (v) {
                  setState(() => _producerType = v);
                  _saveDraft();
                },
                options: const [
                  SelectorOption(
                      value: 'Finca familiar',
                      label: 'Finca familiar',
                      icon: Icons.agriculture_outlined),
                  SelectorOption(
                      value: 'Asociación',
                      label: 'Asociación',
                      icon: Icons.groups_outlined),
                  SelectorOption(
                      value: 'Negocio',
                      label: 'Negocio',
                      icon: Icons.store_outlined)
                ])
          ]),
        1 => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const _StepIntro(
                icon: Icons.map_outlined,
                title: '¿Dónde está tu operación?',
                body: 'Elige departamento y municipio de la lista.'),
            const SizedBox(height: 20),
            SearchableSheetSelector<String>(
                label: 'Departamento',
                hint: 'Seleccionar departamento',
                options: _departments.keys
                    .map((name) => SelectorOption(value: name, label: name))
                    .toList(),
                value: _department,
                onChanged: (value) {
                  setState(() {
                    _department = value;
                    _municipality = null;
                    _error = null;
                  });
                  _saveDraft();
                }),
            const SizedBox(height: 12),
            SearchableSheetSelector<String>(
                label: 'Municipio',
                hint: _department == null
                    ? 'Elige primero el departamento'
                    : 'Seleccionar municipio',
                options: (_departments[_department] ?? const <String>[])
                    .map((name) => SelectorOption(value: name, label: name))
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
                title: 'Marca el punto de recogida',
                body:
                    'Pon un punto aproximado donde podemos recoger tus productos.'),
            const SizedBox(height: 16),
            _LocationPickerMap(onSelect: (lat, lng) => _mapSelection(lat, lng)),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
                onPressed: () => _mapSelection(5.5353, -73.3678),
                icon: const Icon(Icons.my_location),
                label: const Text('Usar ubicación de referencia')),
            TextButton.icon(
                onPressed: _useGps,
                icon: const Icon(Icons.gps_fixed),
                label: const Text('Usar mi ubicación GPS')),
            const Row(children: [
              Icon(Icons.lock_outline, size: 18),
              SizedBox(width: 8),
              Expanded(
                  child:
                      Text('La ubicación exacta no se muestra a compradores.'))
            ]),
            const SizedBox(height: 10),
            TextButton(
                onPressed: () =>
                    setState(() => _manualCoordinates = !_manualCoordinates),
                child: Text(_manualCoordinates
                    ? 'Ocultar ingreso manual'
                    : 'Ingresar coordenadas manualmente')),
            if (_manualCoordinates) ...[
              TextField(
                  controller: _lat,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true, signed: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,-]'))
                  ],
                  decoration: const InputDecoration(labelText: 'Latitud'),
                  onChanged: (_) => _changed()),
              TextField(
                  controller: _lng,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true, signed: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,-]'))
                  ],
                  decoration: const InputDecoration(labelText: 'Longitud'),
                  onChanged: (_) => _changed())
            ],
            if (_lat.text.isNotEmpty && _lng.text.isNotEmpty)
              Text('Punto: ${_lat.text}, ${_lng.text}',
                  style: Theme.of(context).textTheme.bodySmall)
          ]),
        _ => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const _StepIntro(
                icon: Icons.shopping_basket_outlined,
                title: 'Cuéntales sobre tu oferta',
                body:
                    'Agrega detalles que ayuden a conocer lo que produces. Es opcional.'),
            const SizedBox(height: 18),
            TextField(
                controller: _description,
                maxLength: 1000,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                    labelText: 'Descripción (opcional)',
                    hintText: 'Productos, cosechas o forma de entrega'),
                onChanged: (_) => _changed()),
            Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  'Producción orgánica',
                  'Entrega en finca',
                  'Cosecha propia'
                ]
                    .map((chip) => ActionChip(
                        label: Text(chip),
                        onPressed: () {
                          final text = _description.text.trim();
                          _description.text =
                              text.isEmpty ? chip : '$text · $chip';
                          _description.selection = TextSelection.collapsed(
                              offset: _description.text.length);
                          setState(() {});
                          _saveDraft();
                        }))
                    .toList()),
            const SizedBox(height: 24),
            Card(
                child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Revisa tu perfil',
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 10),
                          Text('Operación: ${_displayName.text.trim()}'),
                          Text('Tipo: $_producerType'),
                          Text(
                              'Ubicación: ${_municipality ?? '—'}, ${_department ?? '—'}'),
                          Text('Punto: ${_lat.text}, ${_lng.text}'),
                          Text(
                              'Descripción: ${_description.text.trim().isEmpty ? 'Sin descripción' : _description.text.trim()}')
                        ])))
          ]),
      };

  void _mapSelection(double lat, double lng) {
    setState(() {
      _lat.text = lat.toStringAsFixed(4);
      _lng.text = lng.toStringAsFixed(4);
      _error = null;
    });
    _saveDraft();
    HapticFeedback.selectionClick();
  }

  Future<void> _useGps() async {
    setState(() => _error =
        'El GPS del dispositivo no está habilitado en esta versión. Puedes marcar el mapa o ingresar el punto manualmente.');
  }

  Widget _successScreen() => Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
          child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                TweenAnimationBuilder<double>(
                    tween: Tween(begin: .5, end: 1),
                    duration: const Duration(milliseconds: 350),
                    builder: (context, scale, child) =>
                        Transform.scale(scale: scale, child: child),
                    child: const CircleAvatar(
                        radius: 48,
                        backgroundColor: AppTheme.mint,
                        child: Icon(Icons.check_rounded,
                            size: 52, color: AppTheme.forest))),
                const SizedBox(height: 24),
                Text('¡Perfil guardado!',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                const Text('Ya puedes empezar a ofrecer tus productos.'),
                const SizedBox(height: 24),
                SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                        onPressed: () => context.go('/lotes/nuevo'),
                        icon: const Icon(Icons.add),
                        label: const Text('Publicar mi primer lote'))),
                TextButton(
                    onPressed: () =>
                        context.go(widget.onboarding ? '/' : '/perfil'),
                    child: const Text('Volver a mi cuenta'))
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

class _LocationPickerMap extends StatelessWidget {
  const _LocationPickerMap({required this.onSelect});
  final void Function(double lat, double lng) onSelect;
  @override
  Widget build(BuildContext context) => Semantics(
      label: 'Mapa de Colombia. Toca para elegir un punto',
      child: GestureDetector(
          onTapDown: (details) {
            final box = context.findRenderObject() as RenderBox;
            final point = box.globalToLocal(details.globalPosition);
            final lat = 13.7 - (point.dy / box.size.height) * 18;
            final lng = -81.8 + (point.dx / box.size.width) * 14.9;
            onSelect(lat.clamp(-4.3, 13.7), lng.clamp(-81.8, -66.9));
          },
          child: Container(
              height: 190,
              decoration: BoxDecoration(
                  color: const Color(0xFFE5EFE7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.outline)),
              child: Stack(alignment: Alignment.center, children: [
                CustomPaint(size: Size.infinite, painter: _MapPainter()),
                const Icon(Icons.location_pin,
                    color: AppTheme.forest, size: 40),
                Positioned(
                    left: 14,
                    top: 12,
                    child: Text('COLOMBIA',
                        style: TextStyle(
                            color: AppTheme.forest.withValues(alpha: .8),
                            fontWeight: FontWeight.w700))),
                Positioned(
                    right: 8,
                    bottom: 6,
                    child: Text('Mapa esquemático',
                        style: Theme.of(context).textTheme.labelSmall))
              ]))));
}

class _MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0xFFBDD7C5)
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(size.width * .43, size.height * .08)
      ..lineTo(size.width * .55, size.height * .13)
      ..lineTo(size.width * .61, size.height * .3)
      ..lineTo(size.width * .56, size.height * .48)
      ..lineTo(size.width * .62, size.height * .68)
      ..lineTo(size.width * .51, size.height * .95)
      ..lineTo(size.width * .4, size.height * .76)
      ..lineTo(size.width * .35, size.height * .52)
      ..lineTo(size.width * .39, size.height * .31)
      ..close();
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _OfflineNotice extends StatelessWidget {
  const _OfflineNotice();
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: const Color(0xFFFFF3CD),
          borderRadius: BorderRadius.circular(14)),
      child: const Row(children: [
        Icon(Icons.cloud_off_outlined),
        SizedBox(width: 8),
        Expanded(
            child: Text(
                'Sin conexión. El borrador queda guardado en este dispositivo.'))
      ]));
}

String _profileErrorText(DomainFailure failure) => switch (failure.code) {
      'invalid_profile' =>
        'Revisa el nombre, municipio, departamento y descripción.',
      'invalid_coordinates' => 'Elige un punto dentro de Colombia.',
      'forbidden' => 'Solo productores pueden guardar este perfil.',
      'network_error' =>
        'Sin conexión. El borrador sigue guardado; intenta de nuevo cuando tengas señal.',
      _ =>
        'No pudimos guardar el perfil. Verifica los datos e intenta de nuevo.'
    };

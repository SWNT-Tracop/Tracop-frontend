import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../app/theme.dart';
import '../../core/config/colombia_locations.dart';
import '../../core/i18n/strings.dart';
import '../../core/location/device_location.dart';
import '../../features/home/presentation/home_screen.dart'
    show homeConnectivityProvider;

typedef _S = ProviderProfileStrings;

/// A point the picker can jump to: the municipality centre in the provider profile, or the
/// profile point when publishing a lot.
class PickupReference {
  const PickupReference(
      {required this.label, required this.lat, required this.lng});
  final String label;
  final double lat, lng;
}

/// Pickup point on a real map (OpenStreetMap), with a reference point and the phone GPS.
/// Nobody types coordinates: the person taps the map, the reference or "my location".
class PickupPointPicker extends ConsumerStatefulWidget {
  const PickupPointPicker({
    required this.lat,
    required this.lng,
    required this.onSelect,
    this.reference,
    this.enabled = true,
    this.errorText,
    super.key,
  });

  final double? lat, lng;
  final void Function(double lat, double lng) onSelect;
  final PickupReference? reference;
  final bool enabled;
  final String? errorText;

  @override
  ConsumerState<PickupPointPicker> createState() => _PickupPointPickerState();
}

class _PickupPointPickerState extends ConsumerState<PickupPointPicker> {
  final _map = MapController();
  bool _locating = false;
  DeviceLocationProblem? _problem;
  String? _message;

  @override
  void dispose() {
    _map.dispose();
    super.dispose();
  }

  LatLng? get _point => widget.lat == null || widget.lng == null
      ? null
      : LatLng(widget.lat!, widget.lng!);

  LatLng get _center {
    final reference = widget.reference;
    return _point ??
        (reference == null
            ? const LatLng(ColombiaBounds.defaultLat, ColombiaBounds.defaultLng)
            : LatLng(reference.lat, reference.lng));
  }

  double get _zoom => _point != null || widget.reference != null ? 14 : 6;

  void _select(double lat, double lng, {bool move = false}) {
    setState(() {
      _message = null;
      _problem = null;
    });
    widget.onSelect(lat, lng);
    if (!move) return;
    try {
      _map.move(LatLng(lat, lng), 15);
    } catch (_) {
      // The map is not on screen yet; it opens on the chosen point.
    }
  }

  Future<void> _useGps() async {
    setState(() {
      _locating = true;
      _problem = null;
      _message = null;
    });
    final result = await ref.read(deviceLocatorProvider)();
    if (!mounted) return;
    setState(() => _locating = false);
    switch (result) {
      case DeviceLocationFound(:final lat, :final lng)
          when ColombiaBounds.contains(lat, lng):
        _select(lat, lng, move: true);
      case DeviceLocationFound():
        setState(() => _message = _S.gpsOutside);
      case DeviceLocationFailed(:final problem):
        setState(() {
          _problem = problem;
          _message = switch (problem) {
            DeviceLocationProblem.serviceDisabled => _S.gpsServiceDisabled,
            DeviceLocationProblem.permissionDenied => _S.gpsPermissionDenied,
            DeviceLocationProblem.deniedForever => _S.gpsDeniedForever,
            DeviceLocationProblem.unavailable => _S.gpsUnavailable,
          };
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final offline = ref.watch(homeConnectivityProvider).valueOrNull == false;
    final reference = widget.reference;
    final error = _message ?? widget.errorText;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _PickupMap(
          controller: _map,
          center: _center,
          zoom: _zoom,
          point: _point,
          onSelect: widget.enabled ? _select : null),
      if (offline) ...[
        const SizedBox(height: 8),
        Text(_S.mapOffline, style: Theme.of(context).textTheme.bodySmall),
      ],
      const SizedBox(height: 12),
      if (reference != null)
        FilledButton.tonalIcon(
            onPressed: widget.enabled
                ? () => _select(reference.lat, reference.lng, move: true)
                : null,
            icon: const Icon(Icons.location_city),
            label: Text(reference.label)),
      TextButton.icon(
          onPressed: widget.enabled && !_locating ? _useGps : null,
          icon: _locating
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.gps_fixed),
          label: Text(_locating ? _S.gpsLocating : _S.useGps)),
      if (_problem == DeviceLocationProblem.serviceDisabled ||
          _problem == DeviceLocationProblem.deniedForever)
        TextButton(
            onPressed: () => openLocationSettings(_problem!),
            child: const Text(_S.openSettings)),
      if (error != null)
        Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(error,
                style: TextStyle(color: Theme.of(context).colorScheme.error))),
      if (_point != null && error == null) ...[
        const SizedBox(height: 6),
        Text(_S.pointChosen, style: Theme.of(context).textTheme.bodySmall),
      ],
    ]);
  }
}

class _PickupMap extends StatelessWidget {
  const _PickupMap(
      {required this.controller,
      required this.center,
      required this.zoom,
      required this.point,
      required this.onSelect});
  final MapController controller;
  final LatLng center;
  final double zoom;
  final LatLng? point;
  final void Function(double lat, double lng)? onSelect;

  static const _height = 280.0;
  static const _pinSize = 44.0;

  @override
  Widget build(BuildContext context) => Semantics(
      label: _S.mapLabel,
      child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
              height: _height,
              child: FlutterMap(
                  mapController: controller,
                  options: MapOptions(
                      initialCenter: center,
                      initialZoom: zoom,
                      minZoom: 5,
                      maxZoom: 18,
                      cameraConstraint: CameraConstraint.contain(
                          bounds: LatLngBounds(
                              const LatLng(
                                  ColombiaBounds.minLat, ColombiaBounds.minLng),
                              const LatLng(ColombiaBounds.maxLat,
                                  ColombiaBounds.maxLng))),
                      interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
                      onTap: onSelect == null
                          ? null
                          : (_, tapped) => onSelect!(
                              tapped.latitude.clamp(
                                  ColombiaBounds.minLat, ColombiaBounds.maxLat),
                              tapped.longitude.clamp(ColombiaBounds.minLng,
                                  ColombiaBounds.maxLng))),
                  children: [
                    TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.tracop_mobile'),
                    if (point case final selected?)
                      MarkerLayer(markers: [
                        Marker(
                            point: selected,
                            width: _pinSize,
                            height: _pinSize,
                            alignment: Alignment.topCenter,
                            child: const Icon(Icons.location_pin,
                                color: AppTheme.forest, size: _pinSize)),
                      ]),
                    Align(
                        alignment: Alignment.bottomRight,
                        child: Container(
                            margin: const EdgeInsets.all(6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            color: Colors.white.withValues(alpha: .8),
                            child: Text(_S.mapAttribution,
                                style:
                                    Theme.of(context).textTheme.labelSmall))),
                  ]))));
}

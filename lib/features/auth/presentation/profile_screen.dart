import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../home/presentation/home_screen.dart'
    show homeConnectivityProvider, homeUserProvider;
import '../domain/entities/auth_session.dart';
import '../domain/entities/user.dart';
import 'providers/auth_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  User? _user;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProfile());
  }

  Future<void> _loadProfile() async {
    final result = await ref.read(authRepositoryProvider).getMe();
    User? user;
    result.map(
      ok: (value) => user = value.value,
      err: (failure) => _error = _messageFor(failure.error.code),
    );
    if (user == null) {
      final cached = await ref.read(authRepositoryProvider).getStoredUser();
      user = cached.map(ok: (value) => value.value, err: (_) => null);
    }
    if (!mounted) return;
    setState(() {
      _user = user;
      _loading = false;
    });
  }

  Future<void> _editName() async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => _EditNameDialog(
        initialName: _user?.fullName ?? '',
      ),
    );
    if (name == null || name.length < 2 || !mounted) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final result = await ref
        .read(authRepositoryProvider)
        .updateMe(UpdateMeRequest(fullName: name));
    if (!mounted) return;
    result.map(
      ok: (value) {
        setState(() => _user = value.value);
        ref.invalidate(homeUserProvider);
      },
      err: (failure) =>
          setState(() => _error = _messageFor(failure.error.code)),
    );
    setState(() => _saving = false);
  }

  Future<void> _logout() async {
    setState(() => _saving = true);
    await ref.read(authProvider.notifier).logout();
    ref.invalidate(homeUserProvider);
    if (mounted) context.go('/login');
  }

  Future<void> _updateLocale(String locale) async {
    setState(() {
      _saving = true;
      _error = null;
    });
    final result = await ref
        .read(authRepositoryProvider)
        .updateMe(UpdateMeRequest(locale: locale));
    if (!mounted) return;
    result.map(
      ok: (value) {
        setState(() => _user = value.value);
        ref.invalidate(homeUserProvider);
      },
      err: (failure) =>
          setState(() => _error = _messageFor(failure.error.code)),
    );
    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final connected = ref.watch(homeConnectivityProvider).valueOrNull;
    final user = _user;
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (user == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(_error ?? 'No encontramos los datos de tu cuenta.'),
            const SizedBox(height: 12),
            OutlinedButton(
                onPressed: _loadProfile, child: const Text('Reintentar')),
          ]),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('MI CUENTA',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.forest,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                )),
        const SizedBox(height: 8),
        Text(connected == false
            ? 'Sin conexión. Mostrando el perfil guardado en este dispositivo.'
            : 'Información de tu cuenta.'),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(color: Colors.red)),
        ],
        const SizedBox(height: 24),
        Card(
          child: Column(children: [
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Nombre'),
              subtitle: Text(user.fullName),
              trailing: IconButton(
                tooltip: 'Editar nombre',
                onPressed: connected == false || _saving ? null : _editName,
                icon: const Icon(Icons.edit_outlined),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.badge_outlined),
              title: const Text('Rol'),
              subtitle: Text(_roleLabel(user.role)),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.phone_outlined),
              title: const Text('Celular'),
              subtitle: Text(user.phone),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.language_outlined),
              title: const Text('Idioma'),
              subtitle: Text(user.locale),
              trailing: DropdownButton<String>(
                value: user.locale,
                onChanged: connected == false || _saving
                    ? null
                    : (locale) {
                        if (locale != null) _updateLocale(locale);
                      },
                items: const [
                  DropdownMenuItem(value: 'es-CO', child: Text('Español')),
                  DropdownMenuItem(value: 'en', child: Text('English')),
                ],
              ),
            ),
          ]),
        ),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: _saving ? null : _logout,
          icon: _saving
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.logout),
          label: Text(_saving ? 'Cerrando sesión…' : 'Cerrar sesión'),
        ),
      ],
    );
  }
}

String _roleLabel(String role) => switch (role) {
      'producer' => 'Productor',
      'supplier' => 'Proveedor',
      'buyer' => 'Comprador',
      'carrier' => 'Transportador',
      _ => role,
    };

String _messageFor(String code) => switch (code) {
      'invalid_session' => 'Tu sesión venció. Inicia sesión nuevamente.',
      'network_error' => 'No hay conexión. Mostramos los datos guardados.',
      'invalid_full_name' => 'El nombre debe tener entre 2 y 160 caracteres.',
      'user_not_found' => 'No encontramos tu cuenta. Inicia sesión nuevamente.',
      _ => 'No pudimos actualizar la información. Intenta de nuevo.',
    };

class _EditNameDialog extends StatefulWidget {
  const _EditNameDialog({required this.initialName});

  final String initialName;

  @override
  State<_EditNameDialog> createState() => _EditNameDialogState();
}

class _EditNameDialogState extends State<_EditNameDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialName);
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final name = _controller.text.trim();
    if (name.length < 2 || name.length > 160) {
      setState(() => _error = 'Escribe un nombre de entre 2 y 160 caracteres.');
      return;
    }
    Navigator.of(context).pop(name);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Editar nombre'),
        content: TextField(
          controller: _controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          maxLength: 160,
          decoration: InputDecoration(
            labelText: 'Nombre completo',
            errorText: _error,
          ),
          onChanged: (_) {
            if (_error != null) setState(() => _error = null);
          },
          onSubmitted: (_) => _save(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(onPressed: _save, child: const Text('Guardar')),
        ],
      );
}

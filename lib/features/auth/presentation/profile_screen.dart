import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../shared/widgets/profile_widgets.dart';
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
  bool _loading = true, _saving = false, _didSave = false;
  bool _whatsAppNotices = true,
      _smsNotices = true,
      _localPreferencesChanged = false;
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
        err: (failure) => _error = _messageFor(failure.error.code));
    if (user == null) {
      final cached = await ref.read(authRepositoryProvider).getStoredUser();
      user = cached.map(ok: (value) => value.value, err: (_) => null);
    }
    if (mounted) {
      setState(() {
        _user = user;
        _loading = false;
      });
    }
  }

  Future<void> _editName() async {
    final name = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => _EditNameSheet(initialName: _user?.fullName ?? ''));
    if (name == null || !mounted) return;
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
          setState(() {
            _user = value.value;
            _didSave = true;
          });
          ref.invalidate(homeUserProvider);
          HapticFeedback.selectionClick();
        },
        err: (failure) =>
            setState(() => _error = _messageFor(failure.error.code)));
    setState(() => _saving = false);
  }

  Future<void> _logout(bool offline) async {
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
                title: const Text('¿Cerrar sesión?'),
                content: Text(offline || _localPreferencesChanged
                    ? 'Hay datos guardados solo en este dispositivo${offline ? ' y no tienes conexión' : ''}. No se perderán al cerrar sesión.'
                    : 'Podrás volver a entrar cuando quieras.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Seguir aquí')),
                  FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Cerrar sesión'))
                ]));
    if (confirmed != true || !mounted) return;
    setState(() => _saving = true);
    await ref.read(authProvider.notifier).logout();
    ref.invalidate(homeUserProvider);
    if (mounted) context.go('/login');
  }

  Future<void> _editField(String title, String initial,
      {TextInputType keyboard = TextInputType.text}) async {
    final updated = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (context) => _EditFieldSheet(
            title: title, initial: initial, keyboard: keyboard));
    if (updated == null || !mounted || title != 'Nombre') return;
    setState(() => _saving = true);
    final result = await ref
        .read(authRepositoryProvider)
        .updateMe(UpdateMeRequest(fullName: updated));
    if (!mounted) return;
    result.map(
        ok: (value) {
          setState(() {
            _user = value.value;
            _didSave = true;
          });
          ref.invalidate(homeUserProvider);
        },
        err: (failure) =>
            setState(() => _error = _messageFor(failure.error.code)));
    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final connected = ref.watch(homeConnectivityProvider).valueOrNull;
    if (_loading) return const Center(child: CircularProgressIndicator());
    final user = _user;
    if (user == null) {
      return Center(
          child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(_error ?? 'No encontramos los datos de tu cuenta.'),
                const SizedBox(height: 12),
                OutlinedButton(
                    onPressed: _loadProfile, child: const Text('Reintentar'))
              ])));
    }
    final producer = user.role == 'producer' || user.role == 'supplier';
    final roleStyle = switch (user.role) {
      'producer' || 'supplier' => (Icons.agriculture_outlined, AppTheme.forest),
      'buyer' => (Icons.storefront_outlined, const Color(0xFF315E9E)),
      'carrier' => (Icons.local_shipping_outlined, const Color(0xFF8A5A00)),
      _ => (Icons.person_outline, AppTheme.forest)
    };
    return ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          Text('Mi cuenta',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppTheme.forest, fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),
          Card(
              child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: ProfileHeader(
                      name: user.fullName,
                      phone: user.phone,
                      role: _roleLabel(user.role),
                      icon: roleStyle.$1,
                      color: roleStyle.$2,
                      onEdit:
                          connected == false || _saving ? null : _editName))),
          AnimatedSwitcher(
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 240),
              child: _didSave
                  ? const Padding(
                      key: ValueKey('saved'),
                      padding: EdgeInsets.only(top: 8),
                      child: Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Icon(Icons.check_circle,
                                color: AppTheme.forest, size: 18),
                            SizedBox(width: 6),
                            Text('Guardado')
                          ]))
                  : const SizedBox.shrink()),
          const SizedBox(height: 14),
          Card(
              child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ProfileCompletenessRing(
                            progress: producer ? .6 : .4, label: 'Perfil'),
                        const SizedBox(height: 14),
                        Text(producer
                            ? 'Te falta completar el perfil de proveedor para publicar lotes.'
                            : 'Completa tus datos para aprovechar mejor TRACOP.'),
                        if (producer)
                          Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                  onPressed: () =>
                                      context.push('/perfil/proveedor'),
                                  icon: const Icon(Icons.arrow_forward_rounded),
                                  label: const Text('Completar ahora')))
                      ]))),
          const SizedBox(height: 16),
          if (_error != null)
            Semantics(
                liveRegion: true,
                child: Text(_error!,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error))),
          SettingsSection(title: 'Cuenta', children: [
            EditableInfoTile(
                title: 'Nombre',
                value: user.fullName,
                icon: Icons.person_outline,
                onTap: connected == false || _saving
                    ? null
                    : () => _editField('Nombre', user.fullName)),
            ListTile(
                minTileHeight: 60,
                leading: const Icon(Icons.phone_outlined),
                title: const Text('Celular'),
                subtitle: Text(user.phone))
          ]),
          if (producer) ...[
            const SizedBox(height: 18),
            Card(
                color: AppTheme.mint.withValues(alpha: .45),
                child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => context.push('/perfil/proveedor'),
                    child: const Padding(
                        padding: EdgeInsets.all(18),
                        child: Row(children: [
                          CircleAvatar(
                              backgroundColor: Colors.white,
                              child: Icon(Icons.storefront_outlined,
                                  color: AppTheme.forest)),
                          SizedBox(width: 14),
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text('Perfil de proveedor',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16)),
                                SizedBox(height: 4),
                                Text(
                                    'Incompleto · necesario para publicar lotes')
                              ])),
                          Icon(Icons.chevron_right)
                        ])))),
          ],
          SettingsSection(title: 'Preferencias', children: [
            SwitchListTile(
                secondary: const Icon(Icons.chat_outlined),
                title: const Text('Avisos por WhatsApp'),
                value: _whatsAppNotices,
                onChanged: (value) => setState(() {
                      _whatsAppNotices = value;
                      _localPreferencesChanged = true;
                    })),
            SwitchListTile(
                secondary: const Icon(Icons.sms_outlined),
                title: const Text('Avisos por SMS'),
                value: _smsNotices,
                onChanged: (value) => setState(() {
                      _smsNotices = value;
                      _localPreferencesChanged = true;
                    })),
            const Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Text(
                    'Estas preferencias solo se mantienen durante esta sesión; aún no se sincronizan.')),
          ]),
          SettingsSection(title: 'Ayuda y soporte', children: [
            ListTile(
                leading: const Icon(Icons.help_outline),
                title: const Text('Centro de ayuda'),
                onTap: () => _info('Centro de ayuda',
                    'Pronto encontrarás aquí formas de contactar al equipo TRACOP.')),
            ListTile(
                leading: const Icon(Icons.support_agent_outlined),
                title: const Text('Contactar soporte'),
                onTap: () => _info(
                    'Soporte', 'Estamos preparando este canal de atención.'))
          ]),
          const SettingsSection(title: 'Acerca de', children: [
            ListTile(
                leading: Icon(Icons.eco_outlined),
                title: Text('TRACOP'),
                subtitle: Text('Conectamos el campo con quienes lo necesitan'))
          ]),
          const SizedBox(height: 20),
          Card(
              color: connected == false
                  ? const Color(0xFFFFF3CD)
                  : AppTheme.mint.withValues(alpha: .35),
              child: ListTile(
                  leading: Icon(connected == false
                      ? Icons.cloud_off_outlined
                      : Icons.cloud_done_outlined),
                  title:
                      Text(connected == false ? 'Sin conexión' : 'Conectado'),
                  subtitle: Text(connected == false
                      ? 'Mostrando los datos guardados en este dispositivo.'
                      : 'Tus cambios se guardan al confirmar.'),
                  minTileHeight: 64)),
          const SizedBox(height: 12),
          OutlinedButton.icon(
              onPressed: _saving ? null : () => _logout(connected == false),
              icon: _saving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.logout),
              label: Text(_saving ? 'Cerrando sesión…' : 'Cerrar sesión')),
        ]);
  }

  void _info(String title, String body) => showDialog<void>(
      context: context,
      builder: (context) =>
          AlertDialog(title: Text(title), content: Text(body), actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Entendido'))
          ]));
}

String _roleLabel(String role) => switch (role) {
      'producer' => 'Productor',
      'supplier' => 'Proveedor',
      'buyer' => 'Comprador',
      'carrier' => 'Transportista',
      _ => role
    };
String _messageFor(String code) => switch (code) {
      'invalid_session' => 'Tu sesión venció. Inicia sesión nuevamente.',
      'network_error' => 'No hay conexión. Mostramos los datos guardados.',
      'invalid_full_name' => 'El nombre debe tener entre 2 y 160 caracteres.',
      'user_not_found' => 'No encontramos tu cuenta. Inicia sesión nuevamente.',
      _ => 'No pudimos actualizar la información. Intenta de nuevo.'
    };

class _EditNameSheet extends StatelessWidget {
  const _EditNameSheet({required this.initialName});
  final String initialName;
  @override
  Widget build(BuildContext context) => _EditFieldSheet(
      title: 'Nombre', initial: initialName, keyboard: TextInputType.name);
}

class _EditFieldSheet extends StatefulWidget {
  const _EditFieldSheet(
      {required this.title, required this.initial, required this.keyboard});
  final String title, initial;
  final TextInputType keyboard;
  @override
  State<_EditFieldSheet> createState() => _EditFieldSheetState();
}

class _EditFieldSheetState extends State<_EditFieldSheet> {
  late final controller = TextEditingController(text: widget.initial);
  String? error;
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
      padding: EdgeInsets.fromLTRB(
          20, 24, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Editar ${widget.title.toLowerCase()}',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
                controller: controller,
                autofocus: true,
                keyboardType: widget.keyboard,
                textCapitalization: TextCapitalization.words,
                maxLength: 160,
                decoration:
                    InputDecoration(labelText: widget.title, errorText: error),
                onSubmitted: (_) => _save(context)),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                  child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'))),
              const SizedBox(width: 12),
              Expanded(
                  child: FilledButton(
                      onPressed: () => _save(context),
                      child: const Text('Guardar'))),
            ])
          ]));
  void _save(BuildContext context) {
    final text = controller.text.trim();
    if (text.length < 2 || text.length > 160) {
      setState(() => error = 'Escribe un nombre de entre 2 y 160 caracteres.');
      return;
    }
    Navigator.pop(context, text);
  }
}

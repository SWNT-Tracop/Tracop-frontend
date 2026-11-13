import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/motion.dart';
import '../../../app/theme.dart';
import '../../../core/i18n/strings.dart';
import '../../../shared/widgets/profile_widgets.dart';
import '../../home/presentation/home_screen.dart'
    show homeConnectivityProvider, homeUserProvider;
import '../domain/entities/auth_session.dart';
import '../domain/entities/user.dart';
import 'providers/auth_provider.dart';

const _minNameLength = 2;
const _maxNameLength = 160;

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  User? _user;
  UpsertProviderProfileRequest? _providerProfile;
  bool _loading = true, _saving = false, _loggingOut = false;
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
    final repo = ref.read(authRepositoryProvider);
    if (mounted && _error != null) setState(() => _error = null);
    final result = await repo.getMe();
    User? user;
    String? error;
    result.map(
        ok: (value) => user = value.value,
        err: (failure) => error = ProfileStrings.error(failure.error.code));
    if (user == null) {
      final cached = await repo.getStoredUser();
      user = cached.map(ok: (value) => value.value, err: (_) => null);
    }
    final stored = await repo.getStoredProviderProfile();
    if (!mounted) return;
    setState(() {
      _user = user;
      _error = error;
      _providerProfile =
          stored.map(ok: (value) => value.value, err: (_) => null);
      _loading = false;
    });
  }

  Future<void> _openProviderProfile() async {
    await context.push('/perfil/proveedor');
    if (mounted) await _loadProfile();
  }

  Future<void> _editName() async {
    final name = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => _EditFieldSheet(
            title: ProfileStrings.name,
            initial: _user?.fullName ?? '',
            keyboard: TextInputType.name));
    if (name == null || !mounted || name == _user?.fullName) return;
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
          HapticFeedback.selectionClick();
          _notify(ProfileStrings.nameSaved);
        },
        err: (failure) =>
            setState(() => _error = ProfileStrings.error(failure.error.code)));
    setState(() => _saving = false);
  }

  void _notify(String message) {
    if (Scaffold.maybeOf(context) == null) return;
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: AppMotion.snackBar,
          content: Text(message)));
  }

  Future<void> _logout(bool offline) async {
    final body = (offline
            ? ProfileStrings.logoutOfflineBody
            : ProfileStrings.logoutBody) +
        (_localPreferencesChanged ? ProfileStrings.logoutPreferencesNote : '');
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
                title: const Text(ProfileStrings.logoutTitle),
                content: Text(body),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text(ProfileStrings.stay)),
                  FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text(ProfileStrings.logout))
                ]));
    if (confirmed != true || !mounted) return;
    setState(() => _loggingOut = true);
    await ref.read(authProvider.notifier).logout();
    ref.invalidate(homeUserProvider);
    if (mounted) context.go('/login');
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
                Text(_error ?? ProfileStrings.notFound,
                    textAlign: TextAlign.center),
                const SizedBox(height: 12),
                OutlinedButton(
                    onPressed: _loadProfile,
                    child: const Text(CommonStrings.retry))
              ])));
    }
    final offline = connected == false;
    final busy = _saving || _loggingOut;
    final producer = user.role == 'producer' || user.role == 'supplier';
    final provider = _providerProfile;
    final roleStyle = switch (user.role) {
      'producer' || 'supplier' => (Icons.agriculture_outlined, AppTheme.forest),
      'buyer' => (Icons.storefront_outlined, AppTheme.buyerAccent),
      'carrier' => (Icons.local_shipping_outlined, AppTheme.carrierAccent),
      _ => (Icons.person_outline, AppTheme.forest)
    };
    // Avance segun datos reales: nombre, celular y perfil de proveedor.
    final checks = [
      user.fullName.trim().length >= _minNameLength,
      user.phone.isNotEmpty,
      if (producer) provider != null,
    ];
    final progress = checks.where((done) => done).length / checks.length;
    final complete = progress == 1;
    final onEdit = offline || busy ? null : _editName;

    return RefreshIndicator(
      onRefresh: _loadProfile,
      child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            Text(ProfileStrings.title,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppTheme.forest, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            Card(
                child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ProfileHeader(
                              name: user.fullName,
                              phone: user.phone,
                              role: RoleStrings.label(user.role),
                              icon: roleStyle.$1,
                              color: roleStyle.$2,
                              onEdit: onEdit),
                          if (offline) ...[
                            const SizedBox(height: 12),
                            const _InlineHint(
                                icon: Icons.cloud_off_outlined,
                                text: ProfileStrings.offlineEditHint),
                          ],
                        ]))),
            if (_saving)
              const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: LinearProgressIndicator()),
            if (_error != null)
              Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Semantics(
                      liveRegion: true,
                      child: Text(_error!,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.error)))),
            const SizedBox(height: 14),
            if (!complete)
              Card(
                  child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ProfileCompletenessRing(
                                progress: progress,
                                label: ProfileStrings.completenessLabel,
                                hint: producer
                                    ? ProfileStrings.pendingProvider
                                    : ProfileStrings.pendingGeneral),
                            if (producer)
                              Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton.icon(
                                      onPressed: _openProviderProfile,
                                      icon: const Icon(
                                          Icons.arrow_forward_rounded),
                                      label: const Text(
                                          ProfileStrings.completeNow)))
                          ]))),
            SettingsSection(title: ProfileStrings.sectionAccount, children: [
              EditableInfoTile(
                  title: ProfileStrings.name,
                  value: user.fullName,
                  icon: Icons.person_outline,
                  onTap: onEdit),
              ListTile(
                  minTileHeight: 60,
                  leading: const Icon(Icons.phone_outlined),
                  title: const Text(ProfileStrings.phone),
                  subtitle: Text(user.phone))
            ]),
            if (producer) ...[
              const SizedBox(height: 18),
              Card(
                  color: AppTheme.mint.withValues(alpha: .45),
                  child: InkWell(
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusSurface),
                      onTap: _openProviderProfile,
                      child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Row(children: [
                            CircleAvatar(
                                backgroundColor: AppTheme.white,
                                child: Icon(
                                    provider != null
                                        ? Icons.verified_outlined
                                        : Icons.storefront_outlined,
                                    color: AppTheme.forest)),
                            const SizedBox(width: 14),
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  const Text(ProfileStrings.providerCard,
                                      style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16)),
                                  const SizedBox(height: 4),
                                  Text(provider != null
                                      ? ProfileStrings.providerReady(
                                          provider.displayName,
                                          provider.municipality)
                                      : ProfileStrings.providerPending)
                                ])),
                            const Icon(Icons.chevron_right)
                          ])))),
            ],
            SettingsSection(
                title: ProfileStrings.sectionPreferences,
                children: [
                  SwitchListTile(
                      secondary: const Icon(Icons.chat_outlined),
                      title: const Text(ProfileStrings.whatsapp),
                      value: _whatsAppNotices,
                      onChanged: (value) => setState(() {
                            _whatsAppNotices = value;
                            _localPreferencesChanged = true;
                          })),
                  SwitchListTile(
                      secondary: const Icon(Icons.sms_outlined),
                      title: const Text(ProfileStrings.sms),
                      value: _smsNotices,
                      onChanged: (value) => setState(() {
                            _smsNotices = value;
                            _localPreferencesChanged = true;
                          })),
                  const Padding(
                      padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Text(ProfileStrings.preferencesNote)),
                ]),
            SettingsSection(title: ProfileStrings.sectionHelp, children: [
              ListTile(
                  leading: const Icon(Icons.help_outline),
                  title: const Text(ProfileStrings.helpCenter),
                  onTap: () => _info(ProfileStrings.helpCenter,
                      ProfileStrings.helpCenterBody)),
              ListTile(
                  leading: const Icon(Icons.support_agent_outlined),
                  title: const Text(ProfileStrings.support),
                  onTap: () => _info(
                      ProfileStrings.supportTitle, ProfileStrings.supportBody))
            ]),
            const SettingsSection(
                title: ProfileStrings.sectionAbout,
                children: [
                  ListTile(
                      leading: Icon(Icons.eco_outlined),
                      title: Text(ProfileStrings.appName),
                      subtitle: Text(ProfileStrings.tagline))
                ]),
            const SizedBox(height: 20),
            Card(
                color: offline
                    ? AppTheme.warningSurface
                    : AppTheme.mint.withValues(alpha: .35),
                child: ListTile(
                    leading: Icon(offline
                        ? Icons.cloud_off_outlined
                        : Icons.cloud_done_outlined),
                    title: Text(offline
                        ? ProfileStrings.offline
                        : ProfileStrings.online),
                    subtitle: Text(offline
                        ? ProfileStrings.offlineBody
                        : ProfileStrings.onlineBody),
                    minTileHeight: 64)),
            const SizedBox(height: 12),
            OutlinedButton.icon(
                onPressed: busy ? null : () => _logout(offline),
                icon: _loggingOut
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.logout),
                label: Text(_loggingOut
                    ? ProfileStrings.loggingOut
                    : ProfileStrings.logout)),
          ]),
    );
  }

  void _info(String title, String body) => showDialog<void>(
      context: context,
      builder: (context) =>
          AlertDialog(title: Text(title), content: Text(body), actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(CommonStrings.understood))
          ]));
}

class _InlineHint extends StatelessWidget {
  const _InlineHint({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, size: 18, color: AppTheme.mutedText),
        const SizedBox(width: 8),
        Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodySmall)),
      ]);
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
            Text(ProfileStrings.editTitle(widget.title),
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
                controller: controller,
                autofocus: true,
                keyboardType: widget.keyboard,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                maxLength: _maxNameLength,
                decoration:
                    InputDecoration(labelText: widget.title, errorText: error),
                onChanged: (_) {
                  if (error != null) setState(() => error = null);
                },
                onSubmitted: (_) => _save(context)),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                  child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(CommonStrings.cancel))),
              const SizedBox(width: 12),
              Expanded(
                  child: FilledButton(
                      onPressed: () => _save(context),
                      child: const Text(CommonStrings.save))),
            ])
          ]));
  void _save(BuildContext context) {
    final text = controller.text.trim();
    if (text.length < _minNameLength || text.length > _maxNameLength) {
      setState(() => error = ProfileStrings.nameLengthError);
      return;
    }
    Navigator.pop(context, text);
  }
}

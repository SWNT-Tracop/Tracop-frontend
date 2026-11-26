import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/strings.dart';
import '../../../core/result/result.dart';
import 'backoffice_provider.dart';

typedef _S = AccountAdminStrings;

/// Admin: look an account up by phone, change its marketplace role or suspend it. Every action
/// asks for a reason, which the API stores in the audit log.
class AccountsAdminScreen extends ConsumerStatefulWidget {
  const AccountsAdminScreen({super.key});

  @override
  ConsumerState<AccountsAdminScreen> createState() =>
      _AccountsAdminScreenState();
}

class _AccountsAdminScreenState extends ConsumerState<AccountsAdminScreen> {
  final _phone = TextEditingController();
  Map<String, dynamic>? _account;
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  String _normalized() {
    final digits = _phone.text.replaceAll(RegExp(r'\D'), '');
    return digits.startsWith('57') ? '+$digits' : '+57$digits';
  }

  Future<void> _search() async {
    final digits = _phone.text.replaceAll(RegExp(r'\D'), '');
    if (!RegExp(r'^(57)?3\d{9}$').hasMatch(digits)) {
      setState(() => _error = _S.invalidPhone);
      return;
    }
    await _run(() => ref
        .read(backofficeRepositoryProvider)
        .remote
        .findAccount(_normalized()));
  }

  Future<void> _run(Future<Map<String, dynamic>> Function() call,
      {String? success}) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await ref.read(backofficeRepositoryProvider).guard(call);
    if (!mounted) return;
    setState(() {
      _busy = false;
      result.map(
        ok: (ok) => _account = ok.value,
        err: (err) => _error = _errorText(err.error),
      );
    });
    if (success != null && result is Ok && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(success)));
    }
  }

  String _errorText(DomainFailure failure) => switch (failure.code) {
        'not_found' => _S.notFound,
        'invalid_phone' => _S.invalidPhone,
        'staff_account' || 'role_not_changeable' => _S.staffAccount,
        'own_account' => _S.ownAccount,
        _ => _S.failed,
      };

  Future<String?> _askReason(String title, {Widget? extra}) =>
      showDialog<String>(
        context: context,
        builder: (dialogContext) => _ReasonDialog(title: title, extra: extra),
      );

  Future<void> _changeRole() async {
    final account = _account!;
    var role = _S.marketRoles.firstWhere((item) => item != account['role'],
        orElse: () => _S.marketRoles.first);
    final reason = await _askReason(
      _S.changeRole,
      extra: StatefulBuilder(
        builder: (context, setDialogState) => DropdownButtonFormField<String>(
          initialValue: role,
          decoration: const InputDecoration(labelText: _S.newRole),
          items: [
            for (final item in _S.marketRoles)
              if (item != account['role'])
                DropdownMenuItem(
                    value: item, child: Text(RoleStrings.label(item))),
          ],
          onChanged: (value) => setDialogState(() => role = value ?? role),
        ),
      ),
    );
    if (reason == null) return;
    await _run(
        () => ref
            .read(backofficeRepositoryProvider)
            .remote
            .changeAccountRole(account['id'] as String, role, reason),
        success: _S.roleChanged);
  }

  Future<void> _toggleSuspension() async {
    final account = _account!;
    final suspended = account['status'] == 'suspended';
    final reason = await _askReason(suspended ? _S.reactivate : _S.suspend);
    if (reason == null) return;
    final remote = ref.read(backofficeRepositoryProvider).remote;
    final id = account['id'] as String;
    await _run(
        () => suspended
            ? remote.reactivateAccount(id, reason)
            : remote.suspendAccount(id, reason),
        success: suspended ? _S.reactivated : _S.suspended);
  }

  @override
  Widget build(BuildContext context) {
    final account = _account;
    final marketplace =
        account != null && _S.marketRoles.contains(account['role'] as String?);
    return ListView(padding: const EdgeInsets.all(20), children: [
      Text(_S.title, style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 4),
      const Text(_S.subtitle),
      const SizedBox(height: 16),
      Row(children: [
        Expanded(
          child: TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
                labelText: _S.phoneLabel, hintText: 'Ej.: 300 123 4567'),
            onSubmitted: (_) => _busy ? null : _search(),
          ),
        ),
        const SizedBox(width: 8),
        FilledButton(
            onPressed: _busy ? null : _search, child: const Text(_S.search)),
      ]),
      if (_error != null)
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Text(_error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ),
      if (account != null) ...[
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(account['fullName']?.toString() ?? '',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(
                  '${_S.role}: ${RoleStrings.label(account['role'].toString())}'),
              Text(
                  '${_S.status}: ${_S.statusLabels[account['status']] ?? account['status']}'),
              Text('${_S.phoneEnding} ${account['phoneLast4']}'),
              const SizedBox(height: 12),
              if (!marketplace)
                const Text(_S.staffAccount)
              else
                Wrap(spacing: 8, runSpacing: 8, children: [
                  FilledButton.tonal(
                      onPressed: _busy || account['status'] == 'suspended'
                          ? null
                          : _changeRole,
                      child: const Text(_S.changeRole)),
                  OutlinedButton(
                      onPressed: _busy ? null : _toggleSuspension,
                      child: Text(account['status'] == 'suspended'
                          ? _S.reactivate
                          : _S.suspend)),
                ]),
            ]),
          ),
        ),
      ],
    ]);
  }
}

class _ReasonDialog extends StatefulWidget {
  const _ReasonDialog({required this.title, this.extra});
  final String title;
  final Widget? extra;

  @override
  State<_ReasonDialog> createState() => _ReasonDialogState();
}

class _ReasonDialogState extends State<_ReasonDialog> {
  final _reason = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  void _submit() {
    final reason = _reason.text.trim();
    if (reason.length < 3 || reason.length > 300) {
      setState(() => _error = _S.reasonInvalid);
      return;
    }
    Navigator.pop(context, reason);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(widget.title),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          if (widget.extra != null) ...[
            widget.extra!,
            const SizedBox(height: 12)
          ],
          TextField(
            controller: _reason,
            maxLength: 300,
            decoration:
                InputDecoration(labelText: _S.reasonLabel, errorText: _error),
          ),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(_S.cancel)),
          FilledButton(onPressed: _submit, child: const Text(_S.confirm)),
        ],
      );
}

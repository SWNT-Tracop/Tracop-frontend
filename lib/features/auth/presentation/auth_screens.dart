import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import '../../../core/config/env.dart';
import '../../../core/result/result.dart';
import '../../../app/theme.dart';
import '../../../shared/widgets/option_selectors.dart';
import '../domain/entities/auth_session.dart';
import 'providers/auth_provider.dart';
import '../../home/presentation/home_screen.dart' show homeConnectivityProvider;
import 'leaf_splash_animation.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _restore());
  }

  Future<void> _restore() async {
    final restoration = ref.read(authProvider.notifier).restoreSession();
    final results = await Future.wait<bool>([
      restoration,
      Future<bool>.delayed(const Duration(milliseconds: 1270), () => false),
    ]);
    final restored = results.first;
    if (!mounted) return;
    context.go(restored || AppConfig.canEnterWithoutSession ? '/' : '/login');
  }

  @override
  Widget build(BuildContext context) => const Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(child: LeafSplashAnimation(size: 132)),
      );
}

String _platform() => kIsWeb
    ? 'web'
    : defaultTargetPlatform == TargetPlatform.iOS
        ? 'ios'
        : defaultTargetPlatform == TargetPlatform.android
            ? 'android'
            : 'other';
String _normalizePhone(String value) {
  final digits = value.replaceAll(RegExp(r'\D'), '');
  return digits.startsWith('57') ? '+$digits' : '+57$digits';
}

bool _validPhone(String value) =>
    RegExp(r'^(3\d{9}|\+?57\s?3\d{9})$').hasMatch(value.replaceAll(' ', ''));

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phone = TextEditingController();
  bool _busy = false;
  String? _error;
  String? _botLink;
  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_validPhone(_phone.text)) {
      setState(() => _error = 'Ingresa un celular válido (ej. 3001234567).');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _botLink = null;
    });
    final result = await ref
        .read(authRepositoryProvider)
        .requestOtp(RequestOtpRequest(phone: _normalizePhone(_phone.text)));
    if (!mounted) return;
    result.map(
        ok: (ok) {
          setState(() => _botLink = ok.value.botLink);
          context.push('/otp-verify', extra: _normalizePhone(_phone.text));
        },
        err: (err) => setState(() => _error = _errorText(err.error.code)));
    setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final connected = ref.watch(homeConnectivityProvider).valueOrNull;
    final offline = connected == false;
    return _AuthScaffold(
        title: 'INICIAR SESIÓN',
        subtitle: 'Te enviaremos un código para continuar.',
        children: [
          TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                  labelText: 'Celular',
                  hintText: '300 123 4567',
                  prefixIcon: Icon(Icons.phone_outlined))),
          if (_error != null) _ErrorText(_error!),
          const SizedBox(height: 20),
          if (offline) const _OfflineNotice(),
          FilledButton(
              onPressed: _busy || offline ? null : _send,
              child: Text(_busy ? 'Enviando…' : 'Enviar código')),
          if (_botLink != null)
            TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.send),
                label: const Text('Vincular por Telegram')),
          TextButton(
              onPressed: () => context.go('/register'),
              child: const Text('Crear una cuenta')),
        ]);
  }
}

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  String _role = 'producer';
  bool _consent = false;
  bool _busy = false;
  String? _error;
  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_validPhone(_phone.text)) {
      setState(() => _error = 'Ingresa un celular válido (ej. 3001234567).');
      return;
    }
    if (_name.text.trim().length < 2 || _name.text.trim().length > 160) {
      setState(() => _error = 'Escribe tu nombre completo.');
      return;
    }
    if (!_consent) {
      setState(() => _error = 'Debes aceptar el aviso de privacidad.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final deviceId = await ref.read(authProvider.notifier).getDeviceId();
    final result = await ref.read(authRepositoryProvider).register(
        RegisterRequest(
            phone: _normalizePhone(_phone.text),
            role: _role,
            fullName: _name.text.trim(),
            locale: 'es-CO',
            deviceId: deviceId,
            platform: _platform(),
            consentAccepted: true,
            consentVersion: AppConfig.privacyPolicyVersion));
    if (!mounted) return;
    result.map(
        ok: (_) => context.push('/otp-verify?providerSetup=true',
            extra: _normalizePhone(_phone.text)),
        err: (err) => setState(() => _error = _errorText(err.error.code)));
    setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final connected = ref.watch(homeConnectivityProvider).valueOrNull;
    final offline = connected == false;
    return _AuthScaffold(
        title: 'CREAR CUENTA',
        subtitle: 'Conecta tu trabajo con nuevas oportunidades.',
        children: [
          TextField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Nombre completo')),
          const SizedBox(height: 12),
          TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                  labelText: 'Celular', hintText: '300 123 4567')),
          const SizedBox(height: 14),
          const Text('¿Cómo participarás?'),
          const SizedBox(height: 8),
          OptionCircleSelector<String>(
            value: _role,
            options: const [
              SelectorOption(
                  value: 'producer',
                  label: 'Productor',
                  icon: Icons.agriculture_outlined),
              SelectorOption(
                  value: 'supplier',
                  label: 'Proveedor',
                  icon: Icons.storefront_outlined),
              SelectorOption(
                  value: 'buyer',
                  label: 'Comprador',
                  icon: Icons.shopping_bag_outlined),
              SelectorOption(
                  value: 'carrier',
                  label: 'Transportador',
                  icon: Icons.local_shipping_outlined),
            ],
            onChanged: (value) => setState(() => _role = value),
          ),
          CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _consent,
              onChanged: (v) => setState(() => _consent = v ?? false),
              title: const Text(
                  'Acepto el aviso de privacidad ${AppConfig.privacyPolicyVersion}')),
          Wrap(
            spacing: 4,
            children: [
              TextButton(
                onPressed: () => _showLegalDocument(
                  context,
                  title: 'Aviso de privacidad — borrador',
                  assetPath: 'assets/legal/privacy_notice_es_CO.txt',
                ),
                child: const Text('Leer aviso de privacidad'),
              ),
              TextButton(
                onPressed: () => _showLegalDocument(
                  context,
                  title: 'Términos de uso — borrador',
                  assetPath: 'assets/legal/terms_of_use_es_CO.txt',
                ),
                child: const Text('Leer términos de uso'),
              ),
            ],
          ),
          if (_error != null) _ErrorText(_error!),
          if (offline) const _OfflineNotice(),
          FilledButton(
              onPressed: _busy || offline ? null : _register,
              child: Text(_busy ? 'Enviando…' : 'Siguiente')),
          TextButton(
              onPressed: () => context.go('/login'),
              child: const Text('Ya tengo cuenta')),
        ]);
  }
}

class OtpVerifyScreen extends ConsumerStatefulWidget {
  const OtpVerifyScreen({
    required this.phone,
    this.providerSetup = false,
    super.key,
  });
  final String phone;
  final bool providerSetup;
  @override
  ConsumerState<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends ConsumerState<OtpVerifyScreen> {
  final _code = TextEditingController();
  bool _busy = false;
  String? _error;
  Future<void> _verify() async {
    if (!RegExp(r'^\d{6}$').hasMatch(_code.text)) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final id = await ref.read(authProvider.notifier).getDeviceId();
    await ref.read(authProvider.notifier).verifyOtp(VerifyOtpRequest(
        phone: widget.phone,
        code: _code.text,
        deviceId: id,
        platform: _platform()));
    if (!mounted) return;
    final state = ref.read(authProvider);
    if (state.hasError) {
      setState(() {
        _error = _errorText((state.error is DomainFailure
            ? (state.error as DomainFailure).code
            : 'unknown'));
        _code.clear();
      });
    } else {
      final role = state.valueOrNull?.user.role;
      context.go(
          widget.providerSetup && (role == 'producer' || role == 'supplier')
              ? '/perfil/proveedor?onboarding=true'
              : '/');
    }
    setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final connected = ref.watch(homeConnectivityProvider).valueOrNull;
    final offline = connected == false;
    return _AuthScaffold(
        title: 'VERIFICA TU CELULAR',
        subtitle: 'Ingresa el código que enviamos a ${widget.phone}.',
        children: [
          TextField(
              controller: _code,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 24,
                  letterSpacing: 10),
              decoration: const InputDecoration(
                  labelText: 'Código de 6 dígitos', counterText: ''),
              onChanged: (value) {
                if (!offline && value.length == 6) _verify();
              }),
          if (_error != null) _ErrorText(_error!),
          const SizedBox(height: 16),
          if (offline) const _OfflineNotice(),
          FilledButton(
              onPressed:
                  _busy || offline || _code.text.length != 6 ? null : _verify,
              child: Text(_busy ? 'Verificando…' : 'Verificar')),
          TextButton(
              onPressed: () => context.go('/login'),
              child: const Text('Cambiar número')),
        ]);
  }
}

class _OfflineNotice extends StatelessWidget {
  const _OfflineNotice();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.only(top: 12),
        child: Text('Sin conexión. Conéctate para continuar.'),
      );
}

Future<void> _showLegalDocument(
  BuildContext context, {
  required String title,
  required String assetPath,
}) {
  final document = rootBundle.loadString(assetPath);
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 560,
        height: 420,
        child: FutureBuilder<String>(
          future: document,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Text('No pudimos abrir el documento.');
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            return SingleChildScrollView(
              child: SelectableText(snapshot.data!),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cerrar'),
        ),
      ],
    ),
  );
}

class _AuthScaffold extends StatelessWidget {
  const _AuthScaffold(
      {required this.title, required this.subtitle, required this.children});
  final String title, subtitle;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppTheme.background,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Icon(Icons.eco_outlined,
                            size: 42, color: AppTheme.forest),
                        const SizedBox(height: 22),
                        Text(title,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                    color: AppTheme.forest,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.2),
                            textAlign: TextAlign.center),
                        const SizedBox(height: 8),
                        Text(subtitle,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium),
                        const SizedBox(height: 26),
                        ...children,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}

class _ErrorText extends StatelessWidget {
  const _ErrorText(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(text, style: const TextStyle(color: Colors.red)));
}

String _errorText(String code) => switch (code) {
      'invalid_phone' => 'Ingresa un celular válido (ej. 3001234567).',
      'invalid_role' => 'Selecciona un rol válido para continuar.',
      'invalid_full_name' =>
        'Revisa el nombre. Debe tener entre 2 y 160 caracteres.',
      'invalid_locale' => 'El idioma seleccionado no está disponible.',
      'consent_required' => 'Debes aceptar el aviso de privacidad.',
      'consent_version_mismatch' =>
        'El aviso de privacidad se actualizó. Acepta la nueva versión.',
      'invalid_otp' || 'otp_expired' => 'Código incorrecto o expirado.',
      'otp_attempts_exceeded' =>
        'Demasiados intentos. Solicita un código nuevo.',
      'rate_limited' => 'Demasiadas solicitudes. Intenta nuevamente más tarde.',
      'invalid_session' => 'Sesión expirada. Inicia sesión nuevamente.',
      'access_denied' =>
        'Este dispositivo está vinculado a otra cuenta. Usa otro dispositivo o inicia sesión con esa cuenta.',
      'network_error' =>
        'No hay conexión con el servicio. Intenta cuando tengas señal.',
      _ => 'No pudimos completar la solicitud. Intenta de nuevo.'
    };

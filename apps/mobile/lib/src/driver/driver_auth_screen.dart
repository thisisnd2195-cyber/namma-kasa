import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api.dart';
import '../core/api_client.dart';
import '../core/device.dart';
import '../core/google_auth.dart';
import '../core/session.dart';
import '../core/theme.dart';
import 'driver_home_screen.dart';

enum _Step { phone, code, credential }

/// Drivers cannot self-enrol: the number must already exist as a driver record
/// created by a Ward Admin, which is what stops someone registering as a
/// collection driver they are not (FR-AUTH-05).
class DriverAuthScreen extends ConsumerStatefulWidget {
  const DriverAuthScreen({super.key});

  @override
  ConsumerState<DriverAuthScreen> createState() => _DriverAuthScreenState();
}

class _DriverAuthScreenState extends ConsumerState<DriverAuthScreen> {
  final _phone = TextEditingController();
  final _code = TextEditingController();
  final _password = TextEditingController();

  _Step _step = _Step.phone;
  String? _verificationToken;
  bool _busy = false;
  bool _consented = false;
  String? _error;

  /// Set once Google Sign-In completes, replacing the password entirely
  /// (FR-AUTH-03: exactly one credential path).
  String? _googleIdToken;

  Future<void> _signInWithGoogle() => _run(() async {
        final token = await ref.read(googleAuthProvider).signIn();
        if (token == null) return; // backed out
        if (mounted) setState(() => _googleIdToken = token);
      });

  @override
  void dispose() {
    _phone.dispose();
    _code.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sendCode() => _run(() async {
        await ref.read(apiProvider).sendOtp(_phone.text.trim());
        if (mounted) setState(() => _step = _Step.code);
      });

  Future<void> _verifyCode() => _run(() async {
        final token = await ref
            .read(apiProvider)
            .verifyOtp(_phone.text.trim(), _code.text.trim());
        if (mounted) {
          setState(() {
            _verificationToken = token;
            _step = _Step.credential;
          });
        }
      });

  Future<void> _finish() => _run(() async {
        final deviceId = await deviceIdentifier();
        final api = ref.read(apiProvider);
        Session session;
        try {
          session = await api.registerDriver(
            verificationToken: _verificationToken!,
            deviceId: deviceId,
            locale: 'kn',
            password: _googleIdToken == null ? _password.text : null,
            googleIdToken: _googleIdToken,
          );
        } on ApiException catch (e) {
          // Already has an account: the same screen doubles as sign-in after a
          // reinstall or a new device.
          if (e.statusCode != 409) rethrow;
          final googleIdToken = _googleIdToken;
          session = googleIdToken == null
              ? await api.login(
                  phone: _phone.text.trim(),
                  password: _password.text,
                  deviceId: deviceId,
                )
              : await api.loginWithGoogle(idToken: googleIdToken, deviceId: deviceId);
        }
        await ref.read(sessionProvider.notifier).signIn(session);
        if (mounted) {
          await Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(builder: (_) => const DriverHomeScreen()),
          );
        }
      });

  @override
  Widget build(BuildContext context) {
    final theme = applyDriverScale(Theme.of(context));

    return Theme(
      data: theme,
      child: Scaffold(
        appBar: AppBar(title: const Text('Driver sign in')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(Tokens.space4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_error != null) _ErrorBox(message: _error!),
              switch (_step) {
                _Step.phone => _phoneStep(theme),
                _Step.code => _codeStep(theme),
                _Step.credential => _credentialStep(theme),
              },
            ],
          ),
        ),
      ),
    );
  }

  Widget _phoneStep(ThemeData theme) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Enter the number your Ward Admin registered.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: Tokens.space4),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Phone number',
              hintText: '919999900001',
            ),
          ),
          const SizedBox(height: Tokens.space4),
          FilledButton(
            onPressed: _busy ? null : _sendCode,
            child: Text(_busy ? 'Sending…' : 'Send code'),
          ),
        ],
      );

  Widget _codeStep(ThemeData theme) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('We sent a 6-digit code to ${_phone.text}.', style: theme.textTheme.bodyMedium),
          const SizedBox(height: Tokens.space4),
          TextField(
            controller: _code,
            keyboardType: TextInputType.number,
            maxLength: 6,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(labelText: 'Code'),
          ),
          FilledButton(
            onPressed: _busy ? null : _verifyCode,
            child: Text(_busy ? 'Checking…' : 'Verify'),
          ),
          TextButton(
            onPressed: _busy ? null : () => setState(() => _step = _Step.phone),
            child: const Text('Change number'),
          ),
        ],
      );

  Widget _credentialStep(ThemeData theme) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_googleIdToken == null) ...[
            TextField(
              controller: _password,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Set a password',
                helperText: 'At least 8 characters',
              ),
            ),
            if (ref.read(googleAuthProvider).isConfigured) ...[
              const SizedBox(height: Tokens.space2),
              OutlinedButton.icon(
                key: const Key('driver-google-sign-in'),
                // Glove-friendly, like every other driver control (FR-DRV-02).
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(56)),
                onPressed: _busy ? null : _signInWithGoogle,
                icon: const Icon(Icons.account_circle_outlined),
                label: const Text('Continue with Google'),
              ),
            ],
          ] else
            Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Tokens.success),
                const SizedBox(width: Tokens.space2),
                const Expanded(child: Text('Google account connected')),
                TextButton(
                  onPressed: _busy ? null : () => setState(() => _googleIdToken = null),
                  child: const Text('Change'),
                ),
              ],
            ),
          const SizedBox(height: Tokens.space4),
          // DPDP requires consent to be explicit and specific about what is
          // collected and when (NFR-04, CHK009).
          Container(
            padding: const EdgeInsets.all(Tokens.space3),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(Tokens.radiusCard),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Location sharing', style: theme.textTheme.titleMedium),
                const SizedBox(height: Tokens.space1),
                Text(
                  'Your location is shared only while a trip is running, so residents '
                  'know when the auto is near. It stops the moment you end the trip. '
                  'Residents never see your name or number.',
                  style: theme.textTheme.bodyMedium,
                ),
                CheckboxListTile(
                  value: _consented,
                  onChanged: (value) => setState(() => _consented = value ?? false),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text('I agree', style: theme.textTheme.bodyMedium),
                ),
              ],
            ),
          ),
          const SizedBox(height: Tokens.space4),
          FilledButton(
            onPressed: _busy || !_consented ? null : _finish,
            child: Text(_busy ? 'Finishing…' : 'Finish'),
          ),
        ],
      );
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: Tokens.space4),
      padding: const EdgeInsets.all(Tokens.space3),
      decoration: BoxDecoration(
        color: Tokens.errorContainer,
        borderRadius: BorderRadius.circular(Tokens.radiusInput),
      ),
      child: Text(message, style: const TextStyle(color: Tokens.error)),
    );
  }
}

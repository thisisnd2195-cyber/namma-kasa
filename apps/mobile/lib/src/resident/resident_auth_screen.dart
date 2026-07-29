import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api.dart';
import '../core/api_client.dart';
import '../core/map/map_view.dart';
import '../core/session.dart';
import '../core/theme.dart';
import 'resident_home_screen.dart';

enum _Step { phone, code, details }

/// Resident sign-up. The pin is the important field: ward and route are derived
/// from it, and a wrong pin means alerts for someone else's street. So the map
/// leads and the address text is supporting detail, not the other way round
/// (FR-AUTH-07).
class ResidentAuthScreen extends ConsumerStatefulWidget {
  const ResidentAuthScreen({super.key});

  @override
  ConsumerState<ResidentAuthScreen> createState() => _ResidentAuthScreenState();
}

class _ResidentAuthScreenState extends ConsumerState<ResidentAuthScreen> {
  final _phone = TextEditingController();
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  final _address = TextEditingController();
  final _landmark = TextEditingController();

  _Step _step = _Step.phone;
  String? _verificationToken;
  LatLng _pin = kBengaluruCentre;
  bool _pinMoved = false;
  bool _consented = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_phone, _code, _password, _name, _address, _landmark]) {
      c.dispose();
    }
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

  Future<void> _verify() => _run(() async {
        final token =
            await ref.read(apiProvider).verifyOtp(_phone.text.trim(), _code.text.trim());
        if (mounted) {
          setState(() {
            _verificationToken = token;
            _step = _Step.details;
          });
        }
      });

  Future<void> _finish() => _run(() async {
        final api = ref.read(apiProvider);
        Session session;
        try {
          session = await api.registerResident(
            verificationToken: _verificationToken!,
            password: _password.text,
            fullName: _name.text.trim(),
            addressLine: _address.text.trim(),
            landmark: _landmark.text.trim().isEmpty ? null : _landmark.text.trim(),
            lat: _pin.latitude,
            lng: _pin.longitude,
            locale: 'en',
          );
        } on ApiException catch (e) {
          // Already registered: the same screen doubles as sign-in.
          if (e.statusCode != 409) rethrow;
          session = await api.login(
            phone: _phone.text.trim(),
            password: _password.text,
            deviceId: 'resident',
          );
        }
        await ref.read(sessionProvider.notifier).signIn(session);
        if (mounted) {
          await Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(builder: (_) => const ResidentHomeScreen()),
          );
        }
      });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Resident sign in')),
      body: switch (_step) {
        _Step.phone => _padded(_phoneStep()),
        _Step.code => _padded(_codeStep()),
        _Step.details => _detailsStep(),
      },
    );
  }

  Widget _padded(Widget child) => SingleChildScrollView(
        padding: const EdgeInsets.all(Tokens.space4),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (_error != null) _errorBox(),
          child,
        ]),
      );

  Widget _errorBox() => Container(
        margin: const EdgeInsets.only(bottom: Tokens.space4),
        padding: const EdgeInsets.all(Tokens.space3),
        decoration: BoxDecoration(
          color: Tokens.errorContainer,
          borderRadius: BorderRadius.circular(Tokens.radiusInput),
        ),
        child: Semantics(
          liveRegion: true,
          child: Text(_error!, style: const TextStyle(color: Tokens.error)),
        ),
      );

  Widget _phoneStep() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('We will send you a code to confirm your number.'),
          const SizedBox(height: Tokens.space4),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Phone number',
              hintText: '919888800001',
            ),
          ),
          const SizedBox(height: Tokens.space4),
          FilledButton(
            onPressed: _busy ? null : _sendCode,
            child: Text(_busy ? 'Sending…' : 'Send code'),
          ),
        ],
      );

  Widget _codeStep() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Enter the 6-digit code sent to ${_phone.text}.'),
          const SizedBox(height: Tokens.space4),
          TextField(
            controller: _code,
            keyboardType: TextInputType.number,
            maxLength: 6,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(labelText: 'Code'),
          ),
          FilledButton(
            onPressed: _busy ? null : _verify,
            child: Text(_busy ? 'Checking…' : 'Verify'),
          ),
          TextButton(
            onPressed: _busy ? null : () => setState(() => _step = _Step.phone),
            child: const Text('Change number'),
          ),
        ],
      );

  Widget _detailsStep() {
    return Column(
      children: [
        SizedBox(
          height: 240,
          child: Stack(
            alignment: Alignment.center,
            children: [
              MapView(
                centre: _pin,
                zoom: 16,
                onCentreChanged: (centre) => setState(() {
                  _pin = centre;
                  _pinMoved = true;
                }),
              ),
              // A fixed centre crosshair with a draggable map reads better on a
              // small screen than a marker the thumb has to cover.
              const IgnorePointer(
                child: Icon(Icons.place, size: 40, color: Tokens.primary),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Tokens.space4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_error != null) _errorBox(),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    _pinMoved
                        ? 'Pin set to ${_pin.latitude.toStringAsFixed(5)}, '
                            '${_pin.longitude.toStringAsFixed(5)}'
                        : 'Drag the map so the pin sits on your house.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                TextField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Your name'),
                ),
                TextField(
                  controller: _address,
                  decoration: const InputDecoration(labelText: 'Address'),
                ),
                TextField(
                  controller: _landmark,
                  decoration: const InputDecoration(labelText: 'Landmark (optional)'),
                ),
                TextField(
                  controller: _password,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Set a password',
                    helperText: 'At least 8 characters',
                  ),
                ),
                const SizedBox(height: Tokens.space3),
                // DPDP consent must name what is collected and why (NFR-04).
                CheckboxListTile(
                  value: _consented,
                  onChanged: (v) => setState(() => _consented = v ?? false),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text(
                    'I agree to share my phone number and house location so the app '
                    'can tell me when the collection auto is near.',
                  ),
                ),
                FilledButton(
                  onPressed: _busy || !_consented || !_pinMoved ? null : _finish,
                  child: Text(_busy ? 'Finishing…' : 'Finish'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

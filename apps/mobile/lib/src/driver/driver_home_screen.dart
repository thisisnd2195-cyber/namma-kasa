import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../core/api.dart';
import '../core/api_client.dart';
import '../core/theme.dart';
import 'trip_tracker.dart';

/// The driver's whole day: what they are driving, where, and one big button.
/// Everything else is deliberately absent — the fewer mandatory taps per pass,
/// the more likely tracking actually happens (SC-008).
class DriverHomeScreen extends ConsumerStatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  ConsumerState<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends ConsumerState<DriverHomeScreen> {
  Map<String, dynamic>? _assignment;
  String? _error;
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final data = await ref.read(apiProvider).driverAssignment();
      if (mounted) setState(() => _assignment = data);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Location has to be granted before a trip can start, and "while in use" is
  /// not enough once the screen locks mid-round.
  Future<bool> _ensureLocationPermission() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        setState(() => _error = 'Location is blocked. Enable it in Settings to start a trip.');
      }
      return false;
    }
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  Future<void> _startTrip(int passNumber) async {
    if (!await _ensureLocationPermission()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final trip = await ref.read(apiProvider).startTrip(passNumber);
      await ref.read(tripTrackerProvider.notifier).start(trip['id'] as String);
      await _load();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _endTrip(String tripId) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final tracker = ref.read(tripTrackerProvider.notifier);
      final distance = tracker.distanceCoveredM;
      await tracker.stop();
      await ref.read(apiProvider).endTrip(tripId, distanceCoveredM: distance);
      await _load();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = applyDriverScale(Theme.of(context));
    final status = ref.watch(tripTrackerProvider);

    return Theme(
      data: theme,
      child: Scaffold(
        appBar: AppBar(title: const Text('Your route')),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.all(Tokens.space4),
                  children: [
                    if (_error != null) _Notice(text: _error!, tone: Tokens.error),
                    if (_assignment == null)
                      Text(
                        'No assignment yet. Contact your Ward Admin.',
                        style: theme.textTheme.bodyMedium,
                      )
                    else
                      ..._assignmentBody(theme, status),
                  ],
                ),
              ),
      ),
    );
  }

  List<Widget> _assignmentBody(ThemeData theme, TripTrackerStatus status) {
    final data = _assignment!;
    final auto = data['auto'] as Map<String, dynamic>;
    final route = data['route'] as Map<String, dynamic>;
    final today = data['today'] as Map<String, dynamic>;
    final activeTrip = data['activeTrip'] as Map<String, dynamic>?;

    final wasteTypes = (today['wasteTypes'] as List<dynamic>).cast<String>();
    final passesTotal = today['passesTotal'] as int;
    final passesCompleted = today['passesCompleted'] as int;
    final nextPass = today['nextPassNumber'] as int?;
    final isCollectionDay = today['isCollectionDay'] as bool;

    return [
      _Card(
        theme: theme,
        children: [
          Text(auto['registrationNumber'] as String, style: theme.textTheme.displaySmall),
          Text(
            '${route['routeCode']} · ${route['name']}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Tokens.space3),
          Text(
            '${route['windowStart']} – ${route['windowEnd']}',
            style: theme.textTheme.titleMedium,
          ),
          Text('Pass $passesCompleted of $passesTotal done', style: theme.textTheme.bodyMedium),
        ],
      ),
      const SizedBox(height: Tokens.space3),
      _Card(
        theme: theme,
        children: [
          Text("Today's collection", style: theme.textTheme.titleMedium),
          const SizedBox(height: Tokens.space2),
          if (!isCollectionDay)
            Text('No collection scheduled today.', style: theme.textTheme.bodyMedium)
          else if (wasteTypes.isEmpty)
            Text('Waste types not set for today.', style: theme.textTheme.bodyMedium)
          else
            Wrap(
              spacing: Tokens.space2,
              children: [
                for (final waste in wasteTypes)
                  Chip(
                    label: Text(waste),
                    backgroundColor: Tokens.successContainer,
                    side: BorderSide.none,
                  ),
              ],
            ),
        ],
      ),
      const SizedBox(height: Tokens.space4),
      if (activeTrip != null) ...[
        _TrackingPanel(status: status, theme: theme),
        const SizedBox(height: Tokens.space3),
        FilledButton(
          onPressed: _busy ? null : () => _endTrip(activeTrip['id'] as String),
          style: FilledButton.styleFrom(backgroundColor: Tokens.error),
          child: Text(_busy ? 'Ending…' : 'End trip'),
        ),
      ] else if (nextPass != null && isCollectionDay)
        FilledButton(
          onPressed: _busy ? null : () => _startTrip(nextPass),
          child: Text(_busy ? 'Starting…' : 'Start pass $nextPass'),
        )
      else
        Text(
          'All passes for today are done.',
          style: theme.textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
    ];
  }
}

class _TrackingPanel extends StatelessWidget {
  const _TrackingPanel({required this.status, required this.theme});

  final TripTrackerStatus status;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final degraded = status.state == TrackingState.degraded;
    return _Card(
      theme: theme,
      background: degraded ? Tokens.warningContainer : Tokens.successContainer,
      children: [
        Row(
          children: [
            Icon(
              degraded ? Icons.cloud_off : Icons.location_on,
              color: degraded ? Tokens.warning : Tokens.success,
            ),
            const SizedBox(width: Tokens.space2),
            Expanded(
              child: Text(
                degraded ? 'Offline — updates are saved' : 'Sharing location',
                style: theme.textTheme.titleMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: Tokens.space1),
        Text(
          '${status.sentPings} sent · ${status.pendingPings} waiting',
          style: theme.textTheme.bodyMedium,
        ),
        if (status.poorGps)
          Padding(
            padding: const EdgeInsets.only(top: Tokens.space2),
            child: Text(
              'Weak GPS signal. Keep the phone where it can see the sky.',
              style: theme.textTheme.bodyMedium?.copyWith(color: Tokens.warning),
            ),
          ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.theme, required this.children, this.background});

  final ThemeData theme;
  final List<Widget> children;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Tokens.space4),
      decoration: BoxDecoration(
        color: background ?? theme.colorScheme.surface,
        border: Border.all(color: theme.colorScheme.outline),
        borderRadius: BorderRadius.circular(Tokens.radiusCard),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text, required this.tone});

  final String text;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: Tokens.space3),
      padding: const EdgeInsets.all(Tokens.space3),
      decoration: BoxDecoration(
        color: Tokens.errorContainer,
        borderRadius: BorderRadius.circular(Tokens.radiusInput),
      ),
      child: Text(text, style: TextStyle(color: tone)),
    );
  }
}

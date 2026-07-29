import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../core/api.dart';
import '../core/api_client.dart';
import 'package:namma_kasa_api/api.dart' hide ApiException;

import '../../l10n/app_localizations.dart';
import '../core/theme.dart';
import 'photo_capture.dart';
import 'issue_sheet.dart';
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
  DriverAssignment? _assignment;
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

  /// OEM battery managers silently kill unexempted apps, which is the
  /// spec's top-listed risk. Asked once, before the first trip.
  Future<void> _runTrackingWizard() async {
    final proceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keep tracking alive'),
        content: const Text(
          'Your phone may stop sharing location when the screen is off.\n\n'
          'Next you will be asked to allow notifications and to exempt this app '
          'from battery optimisation. Please allow both.\n\n'
          'On Xiaomi, Oppo, Vivo and Realme phones also enable Autostart for '
          'Namma Kasa in Settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    if (proceed ?? false) {
      await ref.read(tripTrackerProvider.notifier).requestTrackingPermissions();
    }
  }

  /// FR-DRV-08: prompt the driver rather than ending their trip behind their
  /// back. The backend only force-ends once the device is unreachable too.
  Future<void> _maybePromptIdle(String tripId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Still collecting?'),
        content: const Text(
          'There has been no movement for 30 minutes. Is this trip finished?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Still going'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('End trip'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) await _endTrip(tripId);
  }

  Future<void> _startTrip(int passNumber) async {
    if (!await _ensureLocationPermission()) return;
    await _runTrackingWizard();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final trip = await ref.read(apiProvider).startTrip(passNumber);
      await ref.read(tripTrackerProvider.notifier).start(
            trip.id,
            registration: _assignment?.auto.registrationNumber ?? '',
          );
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
        appBar: AppBar(
          title: const Text('Your route'),
          actions: [
            // Always reachable, trip or no trip: a breakdown does not wait for
            // the driver to have started (FR-DRV-07).
            IconButton(
              tooltip: L10n.of(context).reportIssue,
              icon: const Icon(Icons.report_problem_outlined),
              onPressed: () async {
                final sent = await showModalBottomSheet<bool>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => const DriverIssueSheet(),
                );
                if (sent == true && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(L10n.of(context).issueSent)),
                  );
                }
              },
            ),
          ],
        ),
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
    final auto = data.auto;
    final route = data.route;
    final today = data.today;
    final activeTrip = data.activeTrip;

    final wasteTypes = today.wasteTypes.map((w) => w.toString()).toList();
    final passesTotal = today.passesTotal;
    final passesCompleted = today.passesCompleted;
    final nextPass = today.nextPassNumber;
    final isCollectionDay = today.isCollectionDay;

    return [
      _Card(
        theme: theme,
        children: [
          Text(auto.registrationNumber, style: theme.textTheme.displaySmall),
          Text(
            '${route.routeCode} · ${route.name}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Tokens.space3),
          Text(
            '${route.windowStart} – ${route.windowEnd}',
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
        _PhotoRow(tripId: activeTrip.id, theme: theme),
        const SizedBox(height: Tokens.space3),
        if (status.idleMinutes >= 30)
          OutlinedButton(
            onPressed: () => _maybePromptIdle(activeTrip.id),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, Tokens.driverTouchTarget),
            ),
            child: const Text('No movement for a while — finished?'),
          ),
        Semantics(
          button: true,
          label: 'End the current trip and stop sharing location',
          child: FilledButton(
            onPressed: _busy ? null : () => _endTrip(activeTrip.id),
            style: FilledButton.styleFrom(backgroundColor: Tokens.error),
            child: Text(_busy ? 'Ending…' : 'End trip'),
          ),
        ),
      ] else if (nextPass != null && isCollectionDay)
        Semantics(
          button: true,
          label: 'Start pass $nextPass and begin sharing location',
          child: FilledButton(
            onPressed: _busy ? null : () => _startTrip(nextPass),
            child: Text(_busy ? 'Starting…' : 'Start pass $nextPass'),
          ),
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

/// Collection proof. Optional per pass, so it never blocks the trip.
class _PhotoRow extends ConsumerWidget {
  const _PhotoRow({required this.tripId, required this.theme});

  final String tripId;
  final ThemeData theme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queue = ref.watch(photoQueueProvider);
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () async {
              await ref.read(photoQueueProvider.notifier).capture();
              await ref.read(photoQueueProvider.notifier).flush(tripId);
            },
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, Tokens.driverTouchTarget),
            ),
            icon: const Icon(Icons.photo_camera),
            label: const Text('Add photo'),
          ),
        ),
        if (queue.uploaded > 0 || queue.pending.isNotEmpty) ...[
          const SizedBox(width: Tokens.space3),
          Semantics(
            label: '${queue.uploaded} photos uploaded, '
                '${queue.pending.length} waiting to upload',
            child: Text(
              queue.pending.isEmpty
                  ? '${queue.uploaded} sent'
                  : '${queue.uploaded} sent · ${queue.pending.length} waiting',
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ],
    );
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
            // Decorative: the adjacent text already says the same thing.
            ExcludeSemantics(
              child: Icon(
                degraded ? Icons.cloud_off : Icons.location_on,
                color: degraded ? Tokens.warning : Tokens.success,
              ),
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
        Semantics(
          liveRegion: true,
          label: '${status.sentPings} location updates sent, '
              '${status.pendingPings} waiting to send',
          child: Text(
            '${status.sentPings} sent · ${status.pendingPings} waiting',
            style: theme.textTheme.bodyMedium,
          ),
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

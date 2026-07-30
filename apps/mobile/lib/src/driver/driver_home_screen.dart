import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:geolocator/geolocator.dart';

import '../core/api.dart';
import '../core/api_client.dart';
import '../core/map/map_view.dart';
import 'package:namma_kasa_api/api.dart' hide ApiException;

import '../../l10n/app_localizations.dart';
import '../core/theme.dart';
import 'photo_capture.dart';
import 'issue_sheet.dart';
import 'oem_steps.dart';
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
  /// spec's top-listed risk. Asked once, before the first trip, with the steps
  /// for this particular phone rather than a list of every brand (FR-DRV-04).
  Future<void> _runTrackingWizard() async {
    final guidance = oemGuidanceFor(await _manufacturer());
    if (!mounted) return;

    final proceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keep tracking alive'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your phone may stop sharing location when the screen is off.'),
            const SizedBox(height: Tokens.space3),
            Text(
              'On ${guidance.brand}:',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: Tokens.space1),
            for (final step in guidance.steps)
              Padding(
                padding: const EdgeInsets.only(bottom: Tokens.space1),
                child: Text('• $step'),
              ),
          ],
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

  /// Null off Android, and on any failure — the generic wording is correct
  /// everywhere, so a missing manufacturer is not worth an error.
  Future<String?> _manufacturer() async {
    try {
      if (!Platform.isAndroid) return null;
      return (await DeviceInfoPlugin().androidInfo).manufacturer;
    } on Object {
      return null;
    }
  }

  /// The route's serviceable polygon, for the full-bleed map (FR-DRV-01).
  List<LatLng>? get _routeArea {
    final geo = _assignment?.route.serviceableArea;
    if (geo == null) return null;
    try {
      final json = geo as Map<String, dynamic>;
      final type = json['type'] as String?;
      final coords = json['coordinates'] as List<dynamic>;
      final ring = (type == 'MultiPolygon'
          ? (coords[0] as List<dynamic>)[0]
          : coords[0]) as List<dynamic>;
      return [
        for (final point in ring.cast<List<dynamic>>())
          LatLng((point[1] as num).toDouble(), (point[0] as num).toDouble()),
      ];
    } on Object {
      return null; // an undrawable area is not worth an error
    }
  }

  LatLng get _mapCentre {
    final area = _routeArea;
    if (area == null || area.isEmpty) return kBengaluruCentre;
    final lat = area.map((p) => p.latitude).reduce((a, b) => a + b) / area.length;
    final lng = area.map((p) => p.longitude).reduce((a, b) => a + b) / area.length;
    return LatLng(lat, lng);
  }

  @override
  Widget build(BuildContext context) {
    final theme = applyDriverScale(Theme.of(context));
    final status = ref.watch(tripTrackerProvider);
    final data = _assignment;

    return Theme(
      data: theme,
      child: Scaffold(
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : Stack(
                children: [
                  // Full-bleed route map (DS-01): the driver's day at a glance.
                  Positioned.fill(
                    child: MapView(
                      centre: _mapCentre,
                      zoom: 13,
                      area: _routeArea,
                    ),
                  ),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(Tokens.space4),
                      child: Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FloatButton(
                                icon: Icons.arrow_back,
                                tooltip: MaterialLocalizations.of(context)
                                    .backButtonTooltip,
                                onTap: () => Navigator.of(context).maybePop(),
                              ),
                              const Spacer(),
                              Column(
                                children: [
                                  // Always reachable, trip or no trip: a
                                  // breakdown does not wait (FR-DRV-07).
                                  FloatButton(
                                    icon: Icons.report_problem_outlined,
                                    tooltip: L10n.of(context).reportIssue,
                                    onTap: _reportIssue,
                                  ),
                                  const SizedBox(height: Tokens.space3),
                                  FloatButton(
                                    icon: Icons.refresh,
                                    tooltip:
                                        MaterialLocalizations.of(context)
                                            .refreshIndicatorSemanticLabel,
                                    onTap: () => unawaited(_load()),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          if (data != null)
                            Padding(
                              padding: const EdgeInsets.only(top: Tokens.space1),
                              child: Pill(
                                text:
                                    'Pass ${data.today.passesCompleted} of ${data.today.passesTotal} done',
                                background: theme.colorScheme.surface,
                                foreground: theme.colorScheme.onSurface,
                                floating: true,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  DraggableScrollableSheet(
                    initialChildSize: 0.46,
                    minChildSize: 0.24,
                    maxChildSize: 0.9,
                    builder: (context, controller) => Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(Tokens.radiusSheet),
                        ),
                        boxShadow: Tokens.sheetShadow,
                      ),
                      child: ListView(
                        controller: controller,
                        padding: const EdgeInsets.fromLTRB(
                            Tokens.space4 + 4, 0, Tokens.space4 + 4, Tokens.space6),
                        children: [
                          const SheetGrabber(),
                          if (_error != null)
                            _Notice(text: _error!, tone: Tokens.error),
                          if (data == null)
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
                ],
              ),
      ),
    );
  }

  Future<void> _reportIssue() async {
    final sent = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const DriverIssueSheet(),
    );
    if (sent == true && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(L10n.of(context).issueSent)));
    }
  }

  List<Widget> _assignmentBody(ThemeData theme, TripTrackerStatus status) {
    final data = _assignment!;
    final auto = data.auto;
    final route = data.route;
    final today = data.today;
    final activeTrip = data.activeTrip;

    final wasteTypes = today.wasteTypes.map((w) => w.toString()).toList();
    final nextPass = today.nextPassNumber;
    final isCollectionDay = today.isCollectionDay;

    return [
      // The lead row: registration plate as identity, route as context.
      Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Tokens.textPrimary,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(
              auto.registrationNumber.substring(0, 2),
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
            ),
          ),
          const SizedBox(width: Tokens.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(auto.registrationNumber,
                    style: theme.textTheme.headlineSmall),
                const SizedBox(height: 2),
                Text(
                  '${route.routeCode} · ${route.name} · ${route.windowStart} – ${route.windowEnd}',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          if (activeTrip != null)
            const Pill(
              text: 'LIVE',
              background: Tokens.successContainer,
              foreground: Tokens.success,
              dot: Tokens.success,
            ),
        ],
      ),
      const SizedBox(height: Tokens.space4),
      Wrap(
        spacing: Tokens.space2,
        runSpacing: Tokens.space2,
        children: [
          if (!isCollectionDay)
            const Pill(
                text: 'No collection today',
                background: Tokens.surfaceAlt,
                foreground: Tokens.textSecondary)
          else if (wasteTypes.isEmpty)
            const Pill(
                text: 'Waste types not set',
                background: Tokens.surfaceAlt,
                foreground: Tokens.textSecondary)
          else
            for (final waste in wasteTypes) Chip(label: Text(waste)),
          Pill(
            text: '${today.passesTotal} passes today',
            background: Tokens.surfaceAlt,
            foreground: Tokens.textSecondary,
          ),
        ],
      ),
      const SizedBox(height: Tokens.space4),
      if (activeTrip != null) ...[
        _TrackingPanel(status: status, theme: theme),
        const SizedBox(height: Tokens.space3),
        _PhotoRow(tripId: activeTrip.id, theme: theme),
        const SizedBox(height: Tokens.space3),
        if (status.idleMinutes >= 30) ...[
          OutlinedButton(
            onPressed: () => _maybePromptIdle(activeTrip.id),
            child: const Text('No movement for a while — finished?'),
          ),
          const SizedBox(height: Tokens.space3),
        ],
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

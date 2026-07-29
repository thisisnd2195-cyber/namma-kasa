import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../core/api.dart';
import '../core/api_client.dart';
import '../core/map/map_view.dart';
import 'package:namma_kasa_api/api.dart' hide ApiException;

import '../core/theme.dart';
import 'feedback_screen.dart';
import 'live_stream.dart';
import 'proximity.dart';
import 'settings_sheet.dart';

/// The screen that answers "when is the auto coming?".
///
/// A resident should not have to open this at all on a normal day — the
/// proximity push is the real product. This is for the moment they want to
/// see for themselves.
class ResidentHomeScreen extends ConsumerStatefulWidget {
  const ResidentHomeScreen({super.key});

  @override
  ConsumerState<ResidentHomeScreen> createState() => _ResidentHomeScreenState();
}

class _ResidentHomeScreenState extends ConsumerState<ResidentHomeScreen> {
  ResidentHome? _home;
  String? _error;
  bool _loading = true;
  Timer? _poll;
  int? _ratedStars;
  bool _rating = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
    // The socket carries movement; this only keeps schedule and last-collected
    // honest if the app is left open.
    _poll = Timer.periodic(const Duration(seconds: 60), (_) => unawaited(_load()));
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final data = await ref.read(apiProvider).residentHome();
      if (!mounted) return;
      setState(() => _home = data);
      final routeId = data.route?.id;
      if (routeId != null) await ref.read(liveStreamProvider.notifier).connect(routeId);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// FR-CMP-06: the prompt is the whole interaction, so it submits in place.
  Future<void> _rate(int stars) async {
    setState(() => _rating = true);
    try {
      await ref.read(apiProvider).rateToday(stars);
      if (mounted) setState(() => _ratedStars = stars);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _rating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final theme = Theme.of(context);

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final home = _home;
    final route = home?.route;
    final pin = home?.household.pin;
    // Socket positions win over the polled snapshot: they are newer.
    final live = ref.watch(liveStreamProvider);
    final polled = (home?.servingAutos ?? [])
        .map((a) => {
              'tripId': a.tripId,
              'registrationNumber': a.registrationNumber,
              'passNumber': a.passNumber,
              'lat': a.lat,
              'lng': a.lng,
              'distanceM': a.distanceM,
            })
        .toList();
    final autos = live.isNotEmpty
        ? live.values
            .map((a) => {
                  'tripId': a.tripId,
                  'registrationNumber': a.registrationNumber,
                  'passNumber': a.passNumber,
                  'lat': a.lat,
                  'lng': a.lng,
                  // No pin yet means the household is still pending review,
                  // and the banner below replaces these cards anyway.
                  'distanceM': pin == null
                      ? 0
                      : distanceMetres(
                          pin.lat.toDouble(), pin.lng.toDouble(), a.lat, a.lng),
                })
            .toList()
        : polled;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.residentHomeTitle),
        actions: [
          IconButton(
            tooltip: 'Alert settings',
            icon: const Icon(Icons.tune),
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              builder: (_) => const ResidentSettingsSheet(),
            ),
          ),
          IconButton(
            tooltip: l10n.reportProblem,
            icon: const Icon(Icons.report_problem_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => FeedbackScreen(
                  canRateToday: _home?.canRateToday ?? false,
                  missedToday: _home?.missedToday ?? false,
                ),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          children: [
            SizedBox(
              height: 280,
              child: MapView(
                centre: pin == null ? kBengaluruCentre : LatLng(pin.lat.toDouble(), pin.lng.toDouble()),
                markers: [
                  if (pin != null)
                    MapMarker(
                      id: 'home',
                      position: LatLng(pin.lat.toDouble(), pin.lng.toDouble()),
                      color: Tokens.textSecondary,
                    ),
                  for (final auto in autos)
                    MapMarker(
                      id: auto['tripId'] as String,
                      position: LatLng(
                        (auto['lat'] as num).toDouble(),
                        (auto['lng'] as num).toDouble(),
                      ),
                      color: Tokens.success,
                      label: auto['registrationNumber'] as String,
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(Tokens.space4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_error != null)
                    _Banner(text: _error!, background: Tokens.errorContainer, color: Tokens.error),
                  if (route == null)
                    _Banner(
                      text: l10n.pendingReview,
                      background: Tokens.warningContainer,
                      color: const Color(0xFF7A5300),
                    )
                  else ...[
                    // The auto has been past and today is unrated: ask now,
                    // while the collection is still what just happened
                    // (FR-CMP-06). Waiting for the resident to go looking for
                    // the form is how ratings never get given.
                    if ((home?.canRateToday ?? false) && _ratedStars == null)
                      _Card(
                        theme: theme,
                        children: [
                          Text(l10n.rateThisCollection, style: theme.textTheme.titleMedium),
                          const SizedBox(height: Tokens.space2),
                          Row(
                            children: [
                              for (var star = 1; star <= 5; star++)
                                IconButton(
                                  iconSize: 36,
                                  tooltip: '$star',
                                  icon: const Icon(Icons.star_border),
                                  // Rating from the prompt itself: sending the
                                  // resident to another screen to finish is
                                  // how a one-tap rating stops being one tap.
                                  onPressed: _rating ? null : () => unawaited(_rate(star)),
                                ),
                            ],
                          ),
                        ],
                      ),
                    if (_ratedStars != null)
                      _Banner(
                        text: 'Thanks for rating.',
                        background: Tokens.successContainer,
                        color: Tokens.success,
                      ),
                    if (home?.missedToday ?? false)
                      _Banner(
                        text: 'No auto reached your house before the window closed.',
                        background: Tokens.warningContainer,
                        color: const Color(0xFF7A5300),
                      ),
                    if (autos.isEmpty)
                      _Card(
                        theme: theme,
                        children: [
                          Text(l10n.noActiveTrip, style: theme.textTheme.titleMedium),
                          const SizedBox(height: Tokens.space1),
                          Text(
                            l10n.nextCollection(
                              '${route.windowStart} – ${route.windowEnd}',
                            ),
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      )
                    else
                      for (final auto in autos)
                        _Card(
                          theme: theme,
                          background: Tokens.successContainer,
                          children: [
                            Text(
                              auto['registrationNumber'] as String,
                              style: theme.textTheme.titleMedium,
                            ),
                            Builder(
                              builder: (_) {
                                final metres = (auto['distanceM'] as num).toInt();
                                final label = distanceLabel(metres, l10n);
                                final minutes = minutesAway(metres);
                                return Semantics(
                                  liveRegion: true,
                                  label: 'Auto ${auto['registrationNumber']} is $label'
                                      '${minutes == null ? '' : ', ${l10n.minutesAway(minutes)}'}',
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(label, style: theme.textTheme.displaySmall),
                                      // The minutes are the answer to "should I
                                      // go down now?"; the metres alone are not.
                                      if (minutes != null)
                                        Text(
                                          l10n.minutesAway(minutes),
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            color: theme.colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            Text(
                              l10n.passProgress(
                                auto['passNumber'] as int,
                                route.passesPerDay,
                              ),
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                    const SizedBox(height: Tokens.space3),
                    _Card(
                      theme: theme,
                      children: [
                        Text('Today', style: theme.textTheme.titleMedium),
                        const SizedBox(height: Tokens.space2),
                        Wrap(
                          spacing: Tokens.space2,
                          children: [
                            for (final waste
                                in route.todayWasteTypes.map((w) => w.toString()))
                              Chip(label: Text(waste), side: BorderSide.none),
                          ],
                        ),
                        const SizedBox(height: Tokens.space2),
                        Text(
                          '${route.windowStart} – ${route.windowEnd}',
                          style: theme.textTheme.bodyMedium,
                        ),
                        if (home?.lastCollectedAt != null)
                          Text(
                            l10n.lastCollected(
                              DateFormat.yMMMd().add_jm().format(
                                    DateTime.parse(home!.lastCollectedAt!).toLocal(),
                                  ),
                            ),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
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
      margin: const EdgeInsets.only(bottom: Tokens.space2),
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

class _Banner extends StatelessWidget {
  const _Banner({required this.text, required this.background, required this.color});

  final String text;
  final Color background;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: Tokens.space3),
      padding: const EdgeInsets.all(Tokens.space3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(Tokens.radiusInput),
      ),
      child: Text(text, style: TextStyle(color: color)),
    );
  }
}

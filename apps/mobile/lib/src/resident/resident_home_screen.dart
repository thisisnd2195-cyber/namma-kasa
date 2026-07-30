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
    final isLive = live.isNotEmpty;
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
    final autos = isLive
        ? live.values
            .map((a) => {
                  'tripId': a.tripId,
                  'registrationNumber': a.registrationNumber,
                  'passNumber': a.passNumber,
                  'lat': a.lat,
                  'lng': a.lng,
                  // No pin yet means the household is still pending review,
                  // and the sheet below replaces these cards anyway.
                  'distanceM': pin == null
                      ? 0
                      : distanceMetres(
                          pin.lat.toDouble(), pin.lng.toDouble(), a.lat, a.lng),
                })
            .toList()
        : polled;

    final nearestM = autos.isEmpty
        ? null
        : autos
            .map((a) => (a['distanceM'] as num).toInt())
            .reduce((a, b) => a < b ? a : b);
    final minutes = nearestM == null ? null : minutesAway(nearestM);

    // Full-bleed map, floating controls, draggable sheet (DS-01).
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: MapView(
              centre: pin == null
                  ? kBengaluruCentre
                  : LatLng(pin.lat.toDouble(), pin.lng.toDouble()),
              markers: [
                if (pin != null)
                  MapMarker(
                    id: 'home',
                    position: LatLng(pin.lat.toDouble(), pin.lng.toDouble()),
                    color: Tokens.textPrimary,
                  ),
                for (final auto in autos)
                  MapMarker(
                    id: auto['tripId'] as String,
                    position: LatLng(
                      (auto['lat'] as num).toDouble(),
                      (auto['lng'] as num).toDouble(),
                    ),
                    // The live auto is the accent (DS-02/06).
                    color: Tokens.primary,
                    label: auto['registrationNumber'] as String,
                  ),
              ],
            ),
          ),

          // Floating controls over the map.
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
                        tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                        onTap: () => Navigator.of(context).maybePop(),
                      ),
                      const Spacer(),
                      Column(
                        children: [
                          FloatButton(
                            icon: Icons.tune,
                            tooltip: l10n.alertSettings,
                            onTap: () => showModalBottomSheet<void>(
                              context: context,
                              builder: (_) => const ResidentSettingsSheet(),
                            ),
                          ),
                          const SizedBox(height: Tokens.space3),
                          FloatButton(
                            icon: Icons.report_problem_outlined,
                            tooltip: l10n.reportProblem,
                            onTap: () => Navigator.of(context).push(
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
                    ],
                  ),
                  // The ETA pill: the one thing worth floating over the map.
                  if (minutes != null)
                    Padding(
                      padding: const EdgeInsets.only(top: Tokens.space1),
                      child: Pill(
                        text: l10n.minutesAway(minutes),
                        background: theme.colorScheme.surface,
                        foreground: theme.colorScheme.onSurface,
                        dot: Tokens.primary,
                        floating: true,
                      ),
                    ),
                ],
              ),
            ),
          ),

          DraggableScrollableSheet(
            initialChildSize: 0.42,
            minChildSize: 0.22,
            maxChildSize: 0.88,
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
                    _Banner(
                        text: _error!,
                        background: Tokens.errorContainer,
                        color: Tokens.error),
                  if (route == null)
                    _Banner(
                      text: l10n.pendingReview,
                      background: Tokens.warningContainer,
                      color: Tokens.warning,
                    )
                  else ...[
                    if (autos.isEmpty)
                      _SheetHeader(
                        icon: Icons.schedule,
                        title: l10n.noActiveTrip,
                        subtitle: l10n.nextCollection(
                          '${route.windowStart} – ${route.windowEnd}',
                        ),
                      )
                    else
                      for (final auto in autos)
                        _SheetHeader(
                          icon: Icons.electric_rickshaw,
                          title: distanceLabel(
                              (auto['distanceM'] as num).toInt(), l10n),
                          subtitle:
                              '${auto['registrationNumber']} · ${l10n.passProgress(auto['passNumber'] as int, route.passesPerDay)}',
                          trailing: isLive
                              ? const Pill(
                                  text: 'LIVE',
                                  background: Tokens.successContainer,
                                  foreground: Tokens.success,
                                  dot: Tokens.success,
                                )
                              : null,
                        ),
                    const SizedBox(height: Tokens.space4),
                    Wrap(
                      spacing: Tokens.space2,
                      runSpacing: Tokens.space2,
                      children: [
                        for (final waste
                            in route.todayWasteTypes.map((w) => w.toString()))
                          Chip(label: Text(waste)),
                        Pill(
                          text: '${route.windowStart} – ${route.windowEnd}',
                          background: Tokens.surfaceAlt,
                          foreground: Tokens.textSecondary,
                        ),
                      ],
                    ),
                    // Rate in place, the moment the collection is fresh
                    // (FR-CMP-06).
                    if ((home?.canRateToday ?? false) && _ratedStars == null) ...[
                      const SizedBox(height: Tokens.space4),
                      const Divider(height: 1),
                      const SizedBox(height: Tokens.space4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(l10n.rateThisCollection,
                                style: theme.textTheme.titleMedium),
                          ),
                          for (var star = 1; star <= 5; star++)
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                  minWidth: 36, minHeight: 44),
                              iconSize: 28,
                              tooltip: '$star',
                              icon: const Icon(Icons.star_border,
                                  color: Tokens.primary),
                              onPressed:
                                  _rating ? null : () => unawaited(_rate(star)),
                            ),
                        ],
                      ),
                    ],
                    if (_ratedStars != null) ...[
                      const SizedBox(height: Tokens.space3),
                      _Banner(
                        text: l10n.thanksForRating,
                        background: Tokens.successContainer,
                        color: Tokens.success,
                      ),
                    ],
                    if (home?.missedToday ?? false) ...[
                      const SizedBox(height: Tokens.space3),
                      _Banner(
                        text: l10n.missedTodayBanner,
                        background: Tokens.warningContainer,
                        color: Tokens.warning,
                      ),
                    ],
                    if (home?.lastCollectedAt != null) ...[
                      const SizedBox(height: Tokens.space3),
                      Text(
                        l10n.lastCollected(
                          DateFormat.yMMMd().add_jm().format(
                                DateTime.parse(home!.lastCollectedAt!).toLocal(),
                              ),
                        ),
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The sheet's lead row: icon tile, bold headline, sub line (DS-04).
class _SheetHeader extends StatelessWidget {
  const _SheetHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Tokens.primaryContainer,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: Tokens.primaryPressed, size: 24),
        ),
        const SizedBox(width: Tokens.space3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                liveRegion: true,
                child: Text(title, style: theme.textTheme.headlineSmall),
              ),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
        ?trailing,
      ],
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
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: Tokens.space2),
      padding: const EdgeInsets.all(Tokens.space3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(Tokens.radiusCard),
      ),
      child: Semantics(
        liveRegion: true,
        child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

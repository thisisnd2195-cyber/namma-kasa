import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../core/api.dart';
import '../core/api_client.dart';
import '../core/map/map_view.dart';
import '../core/theme.dart';

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
  Map<String, dynamic>? _home;
  String? _error;
  bool _loading = true;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
    // The WebSocket carries live movement; this only keeps schedule and
    // last-collected honest if the app is left open.
    _poll = Timer.periodic(const Duration(seconds: 20), (_) => unawaited(_load()));
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final data = await ref.read(apiProvider).residentHome();
      if (mounted) setState(() => _home = data);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
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
    final route = home?['route'] as Map<String, dynamic>?;
    final autos = (home?['servingAutos'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    final household = home?['household'] as Map<String, dynamic>?;
    final pin = household?['pin'] as Map<String, dynamic>?;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.residentHomeTitle)),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          children: [
            SizedBox(
              height: 280,
              child: MapView(
                centre: pin == null
                    ? kBengaluruCentre
                    : LatLng((pin['lat'] as num).toDouble(), (pin['lng'] as num).toDouble()),
                markers: [
                  if (pin != null)
                    MapMarker(
                      id: 'home',
                      position:
                          LatLng((pin['lat'] as num).toDouble(), (pin['lng'] as num).toDouble()),
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
                    if (autos.isEmpty)
                      _Card(
                        theme: theme,
                        children: [
                          Text(l10n.noActiveTrip, style: theme.textTheme.titleMedium),
                          const SizedBox(height: Tokens.space1),
                          Text(
                            l10n.nextCollection(
                              '${route['windowStart']} – ${route['windowEnd']}',
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
                            Text(
                              _distanceLabel((auto['distanceM'] as num).toInt()),
                              style: theme.textTheme.displaySmall,
                            ),
                            Text(
                              l10n.passProgress(
                                auto['passNumber'] as int,
                                route['passesPerDay'] as int,
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
                                in (route['todayWasteTypes'] as List<dynamic>).cast<String>())
                              Chip(label: Text(waste), side: BorderSide.none),
                          ],
                        ),
                        const SizedBox(height: Tokens.space2),
                        Text(
                          '${route['windowStart']} – ${route['windowEnd']}',
                          style: theme.textTheme.bodyMedium,
                        ),
                        if (home?['lastCollectedAt'] != null)
                          Text(
                            l10n.lastCollected(
                              DateFormat.yMMMd().add_jm().format(
                                    DateTime.parse(home!['lastCollectedAt'] as String).toLocal(),
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

  /// Rounded to 50 m, matching the notification copy, so the map and the push
  /// never disagree about how far away the auto is.
  String _distanceLabel(int metres) {
    if (metres < 50) return 'At your street';
    final rounded = (metres / 50).round() * 50;
    return rounded >= 1000
        ? '${(rounded / 1000).toStringAsFixed(1)} km away'
        : '$rounded m away';
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

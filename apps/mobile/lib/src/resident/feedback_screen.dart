import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api.dart';
import '../core/api_client.dart';
import 'package:namma_kasa_api/api.dart' hide ApiException;

import '../core/theme.dart';

const _categories = <String, String>{
  'missed_pickup': 'Auto did not come',
  'late': 'Came very late',
  'behavior': 'Staff behaviour',
  'segregation': 'Refused segregated waste',
  'other': 'Something else',
};

/// Complaints and the day's rating. Both are deliberately short forms: a
/// resident standing at their gate will not fill in a long one.
class FeedbackScreen extends ConsumerStatefulWidget {
  const FeedbackScreen({super.key, this.canRateToday = false});

  final bool canRateToday;

  @override
  ConsumerState<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends ConsumerState<FeedbackScreen> {
  final _description = TextEditingController();
  String _category = 'missed_pickup';
  int? _stars;
  bool _busy = false;
  String? _error;
  String? _notice;
  List<Complaint> _complaints = const [];

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final list = await ref.read(apiProvider).myComplaints();
      if (mounted) setState(() => _complaints = list);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _submitComplaint() async {
    setState(() {
      _busy = true;
      _error = null;
      _notice = null;
    });
    try {
      await ref.read(apiProvider).createComplaint(
            category: _category,
            description: _description.text.trim().isEmpty ? null : _description.text.trim(),
          );
      _description.clear();
      setState(() => _notice = 'Sent to your Ward Admin.');
      await _load();
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submitRating(int stars) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(apiProvider).rateToday(stars);
      if (mounted) setState(() => _stars = stars);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Report a problem')),
      body: ListView(
        padding: const EdgeInsets.all(Tokens.space4),
        children: [
          if (_error != null)
            _Notice(text: _error!, background: Tokens.errorContainer, color: Tokens.error),
          if (_notice != null)
            _Notice(text: _notice!, background: Tokens.successContainer, color: Tokens.success),

          if (widget.canRateToday) ...[
            Text("Rate today's collection", style: theme.textTheme.titleMedium),
            const SizedBox(height: Tokens.space2),
            Row(
              children: [
                for (var star = 1; star <= 5; star++)
                  IconButton(
                    tooltip: '$star star${star == 1 ? '' : 's'}',
                    onPressed: _busy || _stars != null ? null : () => _submitRating(star),
                    icon: Icon(
                      (_stars ?? 0) >= star ? Icons.star : Icons.star_border,
                      color: Tokens.warning,
                      size: 32,
                    ),
                  ),
              ],
            ),
            if (_stars != null)
              Text('Thanks for rating.', style: theme.textTheme.bodyMedium),
            const Divider(height: Tokens.space8),
          ],

          Text('What went wrong?', style: theme.textTheme.titleMedium),
          const SizedBox(height: Tokens.space2),
          RadioGroup<String>(
            groupValue: _category,
            onChanged: (value) => setState(() => _category = value ?? _category),
            child: Column(
              children: [
                for (final entry in _categories.entries)
                  RadioListTile<String>(
                    value: entry.key,
                    contentPadding: EdgeInsets.zero,
                    title: Text(entry.value, style: theme.textTheme.bodyMedium),
                  ),
              ],
            ),
          ),
          TextField(
            controller: _description,
            maxLines: 3,
            maxLength: 2000,
            decoration: const InputDecoration(
              labelText: 'Anything else? (optional)',
              alignLabelWithHint: true,
            ),
          ),
          FilledButton(
            onPressed: _busy ? null : _submitComplaint,
            child: Text(_busy ? 'Sending…' : 'Send complaint'),
          ),

          if (_complaints.isNotEmpty) ...[
            const Divider(height: Tokens.space8),
            Text('Your complaints', style: theme.textTheme.titleMedium),
            const SizedBox(height: Tokens.space2),
            for (final complaint in _complaints)
              Container(
                margin: const EdgeInsets.only(bottom: Tokens.space2),
                padding: const EdgeInsets.all(Tokens.space3),
                decoration: BoxDecoration(
                  border: Border.all(color: theme.colorScheme.outline),
                  borderRadius: BorderRadius.circular(Tokens.radiusCard),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _categories[complaint.category.toString()] ?? complaint.category.toString(),
                      style: theme.textTheme.bodyMedium,
                    ),
                    Text(
                      complaint.status.toString().replaceAll('_', ' '),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (complaint.resolutionNote != null)
                      Text(
                        complaint.resolutionNote!,
                        style: theme.textTheme.bodyMedium,
                      ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text, required this.background, required this.color});

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

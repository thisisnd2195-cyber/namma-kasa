import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:namma_kasa/src/core/api_client.dart';

/// Serves a canned RFC 9457 problem for any request, below the interceptors —
/// so this exercises the REAL error path, not a fake Api class above it.
class _ProblemAdapter implements HttpClientAdapter {
  _ProblemAdapter(this.status, this.body);

  final int status;
  final Map<String, Object?> body;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/problem+json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  /// The bug this guards against: the interceptor used to wrap ApiException
  /// inside DioException.error, so `on ApiException catch` NEVER matched —
  /// every screen's error handler, including the register-409 sign-in
  /// fallback, was dead code. Found live on an emulator, not by any test,
  /// because every other test fakes the Api class above dio.
  test('a problem response surfaces as a catchable ApiException', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final dio = container.read(apiClientProvider);
    dio.httpClientAdapter = _ProblemAdapter(409, {
      'type': 'about:blank',
      'title': 'Http',
      'status': 409,
      'detail': 'Already registered. Sign in instead.',
    });

    try {
      await dio.post<Map<String, dynamic>>('/auth/register', data: {});
      fail('expected a 409 to throw');
    } on ApiException catch (e) {
      // The whole point: this clause must MATCH.
      expect(e.statusCode, 409);
      expect(e.message, 'Already registered. Sign in instead.');
    }
  });

  test('falls back to title, then to a generic message', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final dio = container.read(apiClientProvider);
    dio.httpClientAdapter = _ProblemAdapter(500, {'title': 'Internal Server Error'});

    try {
      await dio.get<void>('/anything');
      fail('expected a 500 to throw');
    } on ApiException catch (e) {
      expect(e.statusCode, 500);
      expect(e.message, 'Internal Server Error');
    }
  });

  test('statusCode drives branching, as the 409 fallback relies on', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final dio = container.read(apiClientProvider);
    dio.httpClientAdapter = _ProblemAdapter(409, {'detail': 'exists'});

    var fellBack = false;
    try {
      await dio.post<void>('/auth/register', data: {});
    } on ApiException catch (e) {
      if (e.statusCode == 409) fellBack = true;
    }
    expect(fellBack, isTrue, reason: 'the register→login fallback depends on this exact branch');
  });
}

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'env.dart';
import 'session.dart';

/// Errors surfaced to the UI. The API always answers with RFC 9457
/// problem+json, so the human-readable reason is in `detail`.
///
/// Extends DioException rather than wrapping inside one: dio can only reject
/// with a DioException, and an ApiException carried in `.error` never matched
/// any screen's `on ApiException catch` — which silently killed every error
/// handler in the app, including the register-409 → sign-in fallback.
class ApiException extends DioException {
  ApiException(this.statusCode, String message, {RequestOptions? requestOptions})
      : super(requestOptions: requestOptions ?? RequestOptions(), message: message);

  final int? statusCode;

  @override
  String get message => super.message!;

  @override
  String toString() => message;
}

ApiException _toApiException(DioException error) {
  final data = error.response?.data;
  if (data is Map && data['detail'] is String) {
    return ApiException(error.response?.statusCode, data['detail'] as String,
        requestOptions: error.requestOptions);
  }
  if (data is Map && data['title'] is String) {
    return ApiException(error.response?.statusCode, data['title'] as String,
        requestOptions: error.requestOptions);
  }
  return ApiException(
    error.response?.statusCode,
    error.type == DioExceptionType.connectionError
        ? 'Cannot reach the server. Check your connection.'
        : 'Something went wrong. Please try again.',
    requestOptions: error.requestOptions,
  );
}

/// Attaches the access token and transparently rotates it once on a 401, so
/// screens never deal with the 15-minute token lifetime themselves.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._ref, this._refreshDio);

  final Ref _ref;
  final Dio _refreshDio;
  Future<void>? _inFlightRefresh;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _ref.read(sessionProvider)?.accessToken;
    if (token != null) options.headers['Authorization'] = 'Bearer $token';
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final session = _ref.read(sessionProvider);
    final isAuthCall = err.requestOptions.path.startsWith('/auth/');

    if (err.response?.statusCode != 401 || session == null || isAuthCall) {
      return handler.next(err);
    }

    try {
      // Collapse concurrent 401s into a single refresh.
      _inFlightRefresh ??= _refresh(session.refreshToken);
      await _inFlightRefresh;
    } catch (_) {
      await _ref.read(sessionProvider.notifier).signOut();
      return handler.next(err);
    } finally {
      _inFlightRefresh = null;
    }

    final retried = await _refreshDio.fetch<dynamic>(
      err.requestOptions
        ..headers['Authorization'] = 'Bearer ${_ref.read(sessionProvider)!.accessToken}',
    );
    handler.resolve(retried);
  }

  Future<void> _refresh(String refreshToken) async {
    final response = await _refreshDio.post<Map<String, dynamic>>(
      '/auth/refresh',
      data: {'refreshToken': refreshToken},
    );
    final body = response.data!;
    await _ref.read(sessionProvider.notifier).updateTokens(
          access: body['accessToken'] as String,
          refresh: body['refreshToken'] as String,
        );
  }
}

Dio _baseDio() => Dio(
      BaseOptions(
        baseUrl: Env.apiBase,
        // Generous, because drivers work in 2G/3G pockets (NFR-07).
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
        contentType: 'application/json',
      ),
    );

final apiClientProvider = Provider<Dio>((ref) {
  final dio = _baseDio();
  // A bare client for token rotation, so refreshing cannot recurse.
  dio.interceptors.add(AuthInterceptor(ref, _baseDio()));
  dio.interceptors.add(
    InterceptorsWrapper(
      // Reject with the ApiException ITSELF (it is a DioException), so
      // `on ApiException catch` clauses in screens actually match.
      onError: (err, handler) => handler.reject(_toApiException(err)),
    ),
  );
  return dio;
});

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Our ApiException (api_client.dart) carries the problem+json detail; the
// generated one is unused.
import 'package:namma_kasa_api/api.dart' hide ApiException;

import 'api_client.dart';
import 'session.dart';

/// Typed calls against the API.
///
/// Models come from `packages/namma_kasa_api`, generated from
/// `contracts/openapi.json`. The constitution treats a hand-written client
/// model as a defect, and `pnpm contracts:coverage` fails the build if an
/// endpoint is served without appearing in that document.
///
/// Transport stays on Dio rather than the generated client's own `http`
/// client, because the interceptor that silently rotates the 15-minute access
/// token lives there; screens would otherwise each have to handle expiry.
class Api {
  Api(this._dio);

  final Dio _dio;

  T _decode<T>(Response<Map<String, dynamic>> response, T? Function(dynamic) fromJson) {
    final value = fromJson(response.data);
    if (value == null) {
      throw ApiException(response.statusCode, 'Server returned an unexpected shape');
    }
    return value;
  }

  Future<int> sendOtp(String phone) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/otp/send',
      data: {'phone': phone},
    );
    return (response.data?['resendAfterSec'] as num?)?.toInt() ?? 30;
  }

  Future<String> verifyOtp(String phone, String code) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/otp/verify',
      data: {'phone': phone, 'code': code},
    );
    return response.data!['verificationToken'] as String;
  }

  Future<Session> registerDriver({
    required String verificationToken,
    required String deviceId,
    required String locale,
    String? password,
    String? googleIdToken,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/register',
      data: {
        'role': 'driver',
        'verificationToken': verificationToken,
        'credential': _credential(password: password, googleIdToken: googleIdToken),
        'profile': {'locale': locale, 'consent': true},
        'deviceId': deviceId,
      },
    );
    return _toSession(response);
  }

  /// Exactly one credential path is set up after phone verification
  /// (FR-AUTH-03), so this refuses to guess when given both or neither.
  static Map<String, dynamic> _credential({String? password, String? googleIdToken}) {
    if (googleIdToken != null && googleIdToken.isNotEmpty) {
      return {'googleIdToken': googleIdToken};
    }
    if (password != null && password.isNotEmpty) return {'password': password};
    throw ArgumentError('Provide either a password or a Google id token');
  }

  Future<Session> login({
    required String phone,
    required String password,
    required String deviceId,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'phone': phone, 'password': password, 'deviceId': deviceId},
    );
    return _toSession(response);
  }

  /// Sign in with a Google id token (FR-AUTH-03/04). The server verifies the
  /// token against its own client id and matches it to an existing account.
  Future<Session> loginWithGoogle({
    required String idToken,
    required String deviceId,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'googleIdToken': idToken, 'deviceId': deviceId},
    );
    return _toSession(response);
  }

  Future<void> registerDeviceToken(String fcmToken) async {
    await _dio.post<void>('/notifications/devices', data: {'fcmToken': fcmToken});
  }

  Future<void> updateSettings({int? notificationRadiusM, String? locale}) async {
    await _dio.patch<void>(
      '/resident/settings',
      data: {'notificationRadiusM': ?notificationRadiusM, 'locale': ?locale},
    );
  }

  Future<ResidentHome> residentHome() async {
    final response = await _dio.get<Map<String, dynamic>>('/resident/home');
    return _decode(response, ResidentHome.fromJson);
  }

  Future<Session> registerResident({
    required String verificationToken,
    required String fullName,
    required String addressLine,
    String? landmark,
    required double lat,
    required double lng,
    required String locale,
    String? password,
    String? googleIdToken,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/register',
      data: {
        'role': 'resident',
        'verificationToken': verificationToken,
        'credential': _credential(password: password, googleIdToken: googleIdToken),
        'profile': {
          'fullName': fullName,
          'addressLine': addressLine,
          'landmark': ?landmark,
          'pin': {'lat': lat, 'lng': lng},
          'locale': locale,
          'consent': true,
        },
      },
    );
    return _toSession(response);
  }

  Future<List<Complaint>> myComplaints() async {
    final response = await _dio.get<List<dynamic>>('/resident/complaints');
    return (response.data ?? [])
        .map<Complaint?>(Complaint.fromJson)
        .whereType<Complaint>()
        .toList();
  }

  Future<void> createComplaint({required String category, String? description}) async {
    await _dio.post<void>(
      '/resident/complaints',
      data: {'category': category, 'description': ?description, 'mediaUrls': <String>[]},
    );
  }

  Future<void> rateToday(int stars, {String? comment}) async {
    await _dio.post<void>('/resident/ratings', data: {'stars': stars, 'comment': ?comment});
  }

  /// One tap from the driver's home screen (FR-DRV-07). No trip id: a
  /// breakdown can happen before the first trip of the day has started.
  Future<DriverIssueRecord> reportIssue(String kind, {String? note, double? lat, double? lng}) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/driver/issues',
      data: {
        'kind': kind,
        'note': ?note,
        if (lat != null && lng != null) 'geo': {'lat': lat, 'lng': lng},
      },
    );
    return _decode(response, DriverIssueRecord.fromJson);
  }

  Future<Map<String, dynamic>> mqttToken(String tripId) async {
    final response =
        await _dio.post<Map<String, dynamic>>('/driver/trips/$tripId/mqtt-token');
    return response.data!;
  }

  Future<Map<String, dynamic>> presignTripMedia(String tripId) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/driver/trips/$tripId/media/presign',
      data: {'contentType': 'image/jpeg', 'type': 'collection_proof'},
    );
    return response.data!;
  }

  Future<void> confirmTripMedia({
    required String tripId,
    required String uploadId,
    required String objectUrl,
    double? lat,
    double? lng,
    DateTime? capturedAt,
  }) async {
    await _dio.post<void>(
      '/driver/trips/$tripId/media/confirm',
      data: {
        'uploadId': uploadId,
        'objectUrl': objectUrl,
        'type': 'collection_proof',
        if (lat != null && lng != null) 'geo': {'lat': lat, 'lng': lng},
        'capturedAt': ?capturedAt?.toUtc().toIso8601String(),
      },
    );
  }

  Future<DriverAssignment> driverAssignment() async {
    final response = await _dio.get<Map<String, dynamic>>('/driver/assignment');
    return _decode(response, DriverAssignment.fromJson);
  }

  Future<Trip> startTrip(int passNumber) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/driver/trips',
      data: {'passNumber': passNumber},
    );
    return _decode(response, Trip.fromJson);
  }

  Future<void> endTrip(String tripId, {int? distanceCoveredM}) async {
    await _dio.patch<Map<String, dynamic>>(
      '/driver/trips/$tripId/end',
      data: {'reason': 'driver', 'distanceCoveredM': ?distanceCoveredM},
    );
  }

  /// HTTPS fallback for the spool when the broker is unreachable.
  Future<void> postPings(String tripId, List<Map<String, dynamic>> pings) async {
    await _dio.post<Map<String, dynamic>>(
      '/driver/trips/$tripId/pings',
      data: {'pings': pings},
    );
  }

  Session _toSession(Response<Map<String, dynamic>> response) {
    final tokens = _decode(response, AuthTokens.fromJson);
    return Session(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
      userId: tokens.user.id,
      role: tokens.user.role.toString(),
      locale: tokens.user.locale.toString(),
      wardId: tokens.user.wardId,
    );
  }
}

final apiProvider = Provider<Api>((ref) => Api(ref.watch(apiClientProvider)));

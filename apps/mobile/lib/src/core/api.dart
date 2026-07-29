import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client.dart';
import 'session.dart';

/// Thin typed calls over the shared Dio client. The generated package in
/// packages/namma_kasa_api mirrors the same contract; these wrappers exist so
/// screens deal in plain maps rather than a generated client's ceremony.
class Api {
  Api(this._dio);

  final Dio _dio;

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
    required String password,
    required String deviceId,
    required String locale,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/register',
      data: {
        'role': 'driver',
        'verificationToken': verificationToken,
        'credential': {'password': password},
        'profile': {'locale': locale, 'consent': true},
        'deviceId': deviceId,
      },
    );
    return _toSession(response.data!);
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
    return _toSession(response.data!);
  }

  Future<void> registerDeviceToken(String fcmToken) async {
    await _dio.post<void>('/notifications/devices', data: {'fcmToken': fcmToken});
  }

  Future<Map<String, dynamic>> residentHome() async {
    final response = await _dio.get<Map<String, dynamic>>('/resident/home');
    return response.data!;
  }

  Future<Session> registerResident({
    required String verificationToken,
    required String password,
    required String fullName,
    required String addressLine,
    String? landmark,
    required double lat,
    required double lng,
    required String locale,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/register',
      data: {
        'role': 'resident',
        'verificationToken': verificationToken,
        'credential': {'password': password},
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
    return _toSession(response.data!);
  }

  Future<List<Map<String, dynamic>>> myComplaints() async {
    final response = await _dio.get<List<dynamic>>('/resident/complaints');
    return (response.data ?? []).cast<Map<String, dynamic>>();
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

  Future<Map<String, dynamic>> driverAssignment() async {
    final response = await _dio.get<Map<String, dynamic>>('/driver/assignment');
    return response.data!;
  }

  Future<Map<String, dynamic>> startTrip(int passNumber) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/driver/trips',
      data: {'passNumber': passNumber},
    );
    return response.data!;
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

  Session _toSession(Map<String, dynamic> body) {
    final user = body['user'] as Map<String, dynamic>;
    return Session(
      accessToken: body['accessToken'] as String,
      refreshToken: body['refreshToken'] as String,
      userId: user['id'] as String,
      role: user['role'] as String,
      locale: user['locale'] as String? ?? 'en',
      wardId: user['wardId'] as String?,
    );
  }
}

final apiProvider = Provider<Api>((ref) => Api(ref.watch(apiClientProvider)));

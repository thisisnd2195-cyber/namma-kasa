//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class NotificationsApi {
  NotificationsApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Register this device for push
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [NotificationsDevicesPostRequest] notificationsDevicesPostRequest:
  Future<Response> notificationsDevicesPostWithHttpInfo({ NotificationsDevicesPostRequest? notificationsDevicesPostRequest, Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/notifications/devices';

    // ignore: prefer_final_locals
    Object? postBody = notificationsDevicesPostRequest;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];


    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
      abortTrigger: abortTrigger,
    );
  }

  /// Register this device for push
  ///
  /// Parameters:
  ///
  /// * [NotificationsDevicesPostRequest] notificationsDevicesPostRequest:
  Future<void> notificationsDevicesPost({ NotificationsDevicesPostRequest? notificationsDevicesPostRequest, Future<void>? abortTrigger, }) async {
    final response = await notificationsDevicesPostWithHttpInfo(notificationsDevicesPostRequest: notificationsDevicesPostRequest, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }
}

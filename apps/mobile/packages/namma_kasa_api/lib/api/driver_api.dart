//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class DriverApi {
  DriverApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Today's auto, route, waste types and pass progress
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> driverAssignmentGetWithHttpInfo({ Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/driver/assignment';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];


    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
      abortTrigger: abortTrigger,
    );
  }

  /// Today's auto, route, waste types and pass progress
  Future<DriverAssignment?> driverAssignmentGet({ Future<void>? abortTrigger, }) async {
    final response = await driverAssignmentGetWithHttpInfo(abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'DriverAssignment',) as DriverAssignment;
    
    }
    return null;
  }

  /// Report a breakdown or blocked road to the Ward Admin
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [DriverIssuesPostRequest] driverIssuesPostRequest:
  Future<Response> driverIssuesPostWithHttpInfo({ DriverIssuesPostRequest? driverIssuesPostRequest, Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/driver/issues';

    // ignore: prefer_final_locals
    Object? postBody = driverIssuesPostRequest;

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

  /// Report a breakdown or blocked road to the Ward Admin
  ///
  /// Parameters:
  ///
  /// * [DriverIssuesPostRequest] driverIssuesPostRequest:
  Future<DriverIssueRecord?> driverIssuesPost({ DriverIssuesPostRequest? driverIssuesPostRequest, Future<void>? abortTrigger, }) async {
    final response = await driverIssuesPostWithHttpInfo(driverIssuesPostRequest: driverIssuesPostRequest, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'DriverIssueRecord',) as DriverIssueRecord;
    
    }
    return null;
  }

  /// End a trip
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [DriverTripsIdEndPatchRequest] driverTripsIdEndPatchRequest:
  Future<Response> driverTripsIdEndPatchWithHttpInfo(String id, { DriverTripsIdEndPatchRequest? driverTripsIdEndPatchRequest, Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/driver/trips/{id}/end'
      .replaceAll('{id}', id);

    // ignore: prefer_final_locals
    Object? postBody = driverTripsIdEndPatchRequest;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];


    return apiClient.invokeAPI(
      path,
      'PATCH',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
      abortTrigger: abortTrigger,
    );
  }

  /// End a trip
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [DriverTripsIdEndPatchRequest] driverTripsIdEndPatchRequest:
  Future<Trip?> driverTripsIdEndPatch(String id, { DriverTripsIdEndPatchRequest? driverTripsIdEndPatchRequest, Future<void>? abortTrigger, }) async {
    final response = await driverTripsIdEndPatchWithHttpInfo(id, driverTripsIdEndPatchRequest: driverTripsIdEndPatchRequest, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Trip',) as Trip;
    
    }
    return null;
  }

  /// Record a photo once its upload succeeded
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [DriverTripsIdMediaConfirmPostRequest] driverTripsIdMediaConfirmPostRequest:
  Future<Response> driverTripsIdMediaConfirmPostWithHttpInfo(String id, { DriverTripsIdMediaConfirmPostRequest? driverTripsIdMediaConfirmPostRequest, Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/driver/trips/{id}/media/confirm'
      .replaceAll('{id}', id);

    // ignore: prefer_final_locals
    Object? postBody = driverTripsIdMediaConfirmPostRequest;

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

  /// Record a photo once its upload succeeded
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [DriverTripsIdMediaConfirmPostRequest] driverTripsIdMediaConfirmPostRequest:
  Future<DriverTripsIdMediaConfirmPost201Response?> driverTripsIdMediaConfirmPost(String id, { DriverTripsIdMediaConfirmPostRequest? driverTripsIdMediaConfirmPostRequest, Future<void>? abortTrigger, }) async {
    final response = await driverTripsIdMediaConfirmPostWithHttpInfo(id, driverTripsIdMediaConfirmPostRequest: driverTripsIdMediaConfirmPostRequest, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'DriverTripsIdMediaConfirmPost201Response',) as DriverTripsIdMediaConfirmPost201Response;
    
    }
    return null;
  }

  /// Presigned URL for a collection-proof photo
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [DriverTripsIdMediaPresignPostRequest] driverTripsIdMediaPresignPostRequest:
  Future<Response> driverTripsIdMediaPresignPostWithHttpInfo(String id, { DriverTripsIdMediaPresignPostRequest? driverTripsIdMediaPresignPostRequest, Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/driver/trips/{id}/media/presign'
      .replaceAll('{id}', id);

    // ignore: prefer_final_locals
    Object? postBody = driverTripsIdMediaPresignPostRequest;

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

  /// Presigned URL for a collection-proof photo
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [DriverTripsIdMediaPresignPostRequest] driverTripsIdMediaPresignPostRequest:
  Future<DriverTripsIdMediaPresignPost201Response?> driverTripsIdMediaPresignPost(String id, { DriverTripsIdMediaPresignPostRequest? driverTripsIdMediaPresignPostRequest, Future<void>? abortTrigger, }) async {
    final response = await driverTripsIdMediaPresignPostWithHttpInfo(id, driverTripsIdMediaPresignPostRequest: driverTripsIdMediaPresignPostRequest, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'DriverTripsIdMediaPresignPost201Response',) as DriverTripsIdMediaPresignPost201Response;
    
    }
    return null;
  }

  /// Broker credentials scoped to this trip's topic
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<Response> driverTripsIdMqttTokenPostWithHttpInfo(String id, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/driver/trips/{id}/mqtt-token'
      .replaceAll('{id}', id);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];


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

  /// Broker credentials scoped to this trip's topic
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<DriverTripsIdMqttTokenPost201Response?> driverTripsIdMqttTokenPost(String id, { Future<void>? abortTrigger, }) async {
    final response = await driverTripsIdMqttTokenPostWithHttpInfo(id, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'DriverTripsIdMqttTokenPost201Response',) as DriverTripsIdMqttTokenPost201Response;
    
    }
    return null;
  }

  /// HTTPS fallback for position batches when MQTT is unreachable
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [DriverTripsIdPingsPostRequest] driverTripsIdPingsPostRequest:
  Future<Response> driverTripsIdPingsPostWithHttpInfo(String id, { DriverTripsIdPingsPostRequest? driverTripsIdPingsPostRequest, Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/driver/trips/{id}/pings'
      .replaceAll('{id}', id);

    // ignore: prefer_final_locals
    Object? postBody = driverTripsIdPingsPostRequest;

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

  /// HTTPS fallback for position batches when MQTT is unreachable
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [DriverTripsIdPingsPostRequest] driverTripsIdPingsPostRequest:
  Future<DriverTripsIdPingsPost202Response?> driverTripsIdPingsPost(String id, { DriverTripsIdPingsPostRequest? driverTripsIdPingsPostRequest, Future<void>? abortTrigger, }) async {
    final response = await driverTripsIdPingsPostWithHttpInfo(id, driverTripsIdPingsPostRequest: driverTripsIdPingsPostRequest, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'DriverTripsIdPingsPost202Response',) as DriverTripsIdPingsPost202Response;
    
    }
    return null;
  }

  /// Start a pass
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [DriverTripsPostRequest] driverTripsPostRequest:
  Future<Response> driverTripsPostWithHttpInfo({ DriverTripsPostRequest? driverTripsPostRequest, Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/driver/trips';

    // ignore: prefer_final_locals
    Object? postBody = driverTripsPostRequest;

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

  /// Start a pass
  ///
  /// Parameters:
  ///
  /// * [DriverTripsPostRequest] driverTripsPostRequest:
  Future<Trip?> driverTripsPost({ DriverTripsPostRequest? driverTripsPostRequest, Future<void>? abortTrigger, }) async {
    final response = await driverTripsPostWithHttpInfo(driverTripsPostRequest: driverTripsPostRequest, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Trip',) as Trip;
    
    }
    return null;
  }
}

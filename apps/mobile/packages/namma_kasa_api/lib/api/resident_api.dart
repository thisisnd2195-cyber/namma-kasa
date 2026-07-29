//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class ResidentApi {
  ResidentApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Complaints raised by this household
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> residentComplaintsGetWithHttpInfo({ Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/resident/complaints';

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

  /// Complaints raised by this household
  Future<List<Complaint>?> residentComplaintsGet({ Future<void>? abortTrigger, }) async {
    final response = await residentComplaintsGetWithHttpInfo(abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<Complaint>') as List)
        .cast<Complaint>()
        .toList(growable: false);

    }
    return null;
  }

  /// Raise a complaint
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [ResidentComplaintsPostRequest] residentComplaintsPostRequest:
  Future<Response> residentComplaintsPostWithHttpInfo({ ResidentComplaintsPostRequest? residentComplaintsPostRequest, Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/resident/complaints';

    // ignore: prefer_final_locals
    Object? postBody = residentComplaintsPostRequest;

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

  /// Raise a complaint
  ///
  /// Parameters:
  ///
  /// * [ResidentComplaintsPostRequest] residentComplaintsPostRequest:
  Future<Complaint?> residentComplaintsPost({ ResidentComplaintsPostRequest? residentComplaintsPostRequest, Future<void>? abortTrigger, }) async {
    final response = await residentComplaintsPostWithHttpInfo(residentComplaintsPostRequest: residentComplaintsPostRequest, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Complaint',) as Complaint;
    
    }
    return null;
  }

  /// Route, schedule, serving autos and last collection
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> residentHomeGetWithHttpInfo({ Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/resident/home';

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

  /// Route, schedule, serving autos and last collection
  Future<ResidentHome?> residentHomeGet({ Future<void>? abortTrigger, }) async {
    final response = await residentHomeGetWithHttpInfo(abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ResidentHome',) as ResidentHome;
    
    }
    return null;
  }

  /// Edit house details; moving the pin re-runs route mapping
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [ResidentHouseholdPatchRequest] residentHouseholdPatchRequest:
  Future<Response> residentHouseholdPatchWithHttpInfo({ ResidentHouseholdPatchRequest? residentHouseholdPatchRequest, Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/resident/household';

    // ignore: prefer_final_locals
    Object? postBody = residentHouseholdPatchRequest;

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

  /// Edit house details; moving the pin re-runs route mapping
  ///
  /// Parameters:
  ///
  /// * [ResidentHouseholdPatchRequest] residentHouseholdPatchRequest:
  Future<Household?> residentHouseholdPatch({ ResidentHouseholdPatchRequest? residentHouseholdPatchRequest, Future<void>? abortTrigger, }) async {
    final response = await residentHouseholdPatchWithHttpInfo(residentHouseholdPatchRequest: residentHouseholdPatchRequest, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Household',) as Household;
    
    }
    return null;
  }

  /// Rate today's collection, once per day
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [ResidentRatingsPostRequest] residentRatingsPostRequest:
  Future<Response> residentRatingsPostWithHttpInfo({ ResidentRatingsPostRequest? residentRatingsPostRequest, Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/resident/ratings';

    // ignore: prefer_final_locals
    Object? postBody = residentRatingsPostRequest;

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

  /// Rate today's collection, once per day
  ///
  /// Parameters:
  ///
  /// * [ResidentRatingsPostRequest] residentRatingsPostRequest:
  Future<Rating?> residentRatingsPost({ ResidentRatingsPostRequest? residentRatingsPostRequest, Future<void>? abortTrigger, }) async {
    final response = await residentRatingsPostWithHttpInfo(residentRatingsPostRequest: residentRatingsPostRequest, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Rating',) as Rating;
    
    }
    return null;
  }

  /// Alert radius and language
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [ResidentSettingsPatchRequest] residentSettingsPatchRequest:
  Future<Response> residentSettingsPatchWithHttpInfo({ ResidentSettingsPatchRequest? residentSettingsPatchRequest, Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/resident/settings';

    // ignore: prefer_final_locals
    Object? postBody = residentSettingsPatchRequest;

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

  /// Alert radius and language
  ///
  /// Parameters:
  ///
  /// * [ResidentSettingsPatchRequest] residentSettingsPatchRequest:
  Future<Household?> residentSettingsPatch({ ResidentSettingsPatchRequest? residentSettingsPatchRequest, Future<void>? abortTrigger, }) async {
    final response = await residentSettingsPatchWithHttpInfo(residentSettingsPatchRequest: residentSettingsPatchRequest, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Household',) as Household;
    
    }
    return null;
  }
}

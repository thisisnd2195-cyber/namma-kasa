//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class AuthApi {
  AuthApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Sign in with password or Google
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [LoginRequest] loginRequest:
  Future<Response> authLoginPostWithHttpInfo({ LoginRequest? loginRequest, Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/auth/login';

    // ignore: prefer_final_locals
    Object? postBody = loginRequest;

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

  /// Sign in with password or Google
  ///
  /// Parameters:
  ///
  /// * [LoginRequest] loginRequest:
  Future<AuthTokens?> authLoginPost({ LoginRequest? loginRequest, Future<void>? abortTrigger, }) async {
    final response = await authLoginPostWithHttpInfo(loginRequest: loginRequest, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'AuthTokens',) as AuthTokens;
    
    }
    return null;
  }

  /// Send a one-time code to a phone number
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [OtpSendRequest] otpSendRequest:
  Future<Response> authOtpSendPostWithHttpInfo({ OtpSendRequest? otpSendRequest, Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/auth/otp/send';

    // ignore: prefer_final_locals
    Object? postBody = otpSendRequest;

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

  /// Send a one-time code to a phone number
  ///
  /// Parameters:
  ///
  /// * [OtpSendRequest] otpSendRequest:
  Future<OtpSendResponse?> authOtpSendPost({ OtpSendRequest? otpSendRequest, Future<void>? abortTrigger, }) async {
    final response = await authOtpSendPostWithHttpInfo(otpSendRequest: otpSendRequest, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'OtpSendResponse',) as OtpSendResponse;
    
    }
    return null;
  }

  /// Exchange a one-time code for a verification token
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [OtpVerifyRequest] otpVerifyRequest:
  Future<Response> authOtpVerifyPostWithHttpInfo({ OtpVerifyRequest? otpVerifyRequest, Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/auth/otp/verify';

    // ignore: prefer_final_locals
    Object? postBody = otpVerifyRequest;

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

  /// Exchange a one-time code for a verification token
  ///
  /// Parameters:
  ///
  /// * [OtpVerifyRequest] otpVerifyRequest:
  Future<OtpVerifyResponse?> authOtpVerifyPost({ OtpVerifyRequest? otpVerifyRequest, Future<void>? abortTrigger, }) async {
    final response = await authOtpVerifyPostWithHttpInfo(otpVerifyRequest: otpVerifyRequest, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'OtpVerifyResponse',) as OtpVerifyResponse;
    
    }
    return null;
  }

  /// Rotate a refresh token
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [RefreshRequest] refreshRequest:
  Future<Response> authRefreshPostWithHttpInfo({ RefreshRequest? refreshRequest, Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/auth/refresh';

    // ignore: prefer_final_locals
    Object? postBody = refreshRequest;

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

  /// Rotate a refresh token
  ///
  /// Parameters:
  ///
  /// * [RefreshRequest] refreshRequest:
  Future<AuthTokens?> authRefreshPost({ RefreshRequest? refreshRequest, Future<void>? abortTrigger, }) async {
    final response = await authRefreshPostWithHttpInfo(refreshRequest: refreshRequest, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'AuthTokens',) as AuthTokens;
    
    }
    return null;
  }

  /// Create a resident or driver account
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [RegisterRequest] registerRequest:
  Future<Response> authRegisterPostWithHttpInfo({ RegisterRequest? registerRequest, Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/auth/register';

    // ignore: prefer_final_locals
    Object? postBody = registerRequest;

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

  /// Create a resident or driver account
  ///
  /// Parameters:
  ///
  /// * [RegisterRequest] registerRequest:
  Future<AuthTokens?> authRegisterPost({ RegisterRequest? registerRequest, Future<void>? abortTrigger, }) async {
    final response = await authRegisterPostWithHttpInfo(registerRequest: registerRequest, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'AuthTokens',) as AuthTokens;
    
    }
    return null;
  }
}

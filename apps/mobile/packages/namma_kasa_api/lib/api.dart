//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

library openapi.api;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:meta/meta.dart';

part 'api_client.dart';
part 'api_helper.dart';
part 'api_exception.dart';
part 'auth/authentication.dart';
part 'auth/api_key_auth.dart';
part 'auth/oauth.dart';
part 'auth/http_basic_auth.dart';
part 'auth/http_bearer_auth.dart';

part 'api/account_api.dart';
part 'api/auth_api.dart';
part 'api/driver_api.dart';
part 'api/notifications_api.dart';
part 'api/resident_api.dart';

part 'model/auth_tokens.dart';
part 'model/auth_tokens_user.dart';
part 'model/auto.dart';
part 'model/complaint.dart';
part 'model/complaint_history_inner.dart';
part 'model/driver.dart';
part 'model/driver_assignment.dart';
part 'model/driver_assignment_auto.dart';
part 'model/driver_assignment_route.dart';
part 'model/driver_assignment_today.dart';
part 'model/driver_trips_id_end_patch_request.dart';
part 'model/driver_trips_id_media_confirm_post201_response.dart';
part 'model/driver_trips_id_media_confirm_post_request.dart';
part 'model/driver_trips_id_media_confirm_post_request_geo.dart';
part 'model/driver_trips_id_media_presign_post201_response.dart';
part 'model/driver_trips_id_media_presign_post_request.dart';
part 'model/driver_trips_id_mqtt_token_post201_response.dart';
part 'model/driver_trips_id_pings_post202_response.dart';
part 'model/driver_trips_id_pings_post_request.dart';
part 'model/driver_trips_id_pings_post_request_pings_inner.dart';
part 'model/driver_trips_post_request.dart';
part 'model/household.dart';
part 'model/login_request.dart';
part 'model/login_request_any_of.dart';
part 'model/login_request_any_of1.dart';
part 'model/me_delete202_response.dart';
part 'model/me_retention_policy_get200_response.dart';
part 'model/notifications_devices_post_request.dart';
part 'model/otp_send_request.dart';
part 'model/otp_send_response.dart';
part 'model/otp_verify_request.dart';
part 'model/otp_verify_response.dart';
part 'model/problem.dart';
part 'model/rating.dart';
part 'model/refresh_request.dart';
part 'model/register_request.dart';
part 'model/register_request_any_of.dart';
part 'model/register_request_any_of1.dart';
part 'model/register_request_any_of1_profile.dart';
part 'model/register_request_any_of_profile.dart';
part 'model/register_request_any_of_profile_pin.dart';
part 'model/resident_complaints_post_request.dart';
part 'model/resident_home.dart';
part 'model/resident_home_route.dart';
part 'model/resident_home_serving_autos_inner.dart';
part 'model/resident_household_patch_request.dart';
part 'model/resident_household_patch_request_pin.dart';
part 'model/resident_ratings_post_request.dart';
part 'model/resident_settings_patch_request.dart';
part 'model/trip.dart';


/// An [ApiClient] instance that uses the default values obtained from
/// the OpenAPI specification file.
var defaultApiClient = ApiClient();

const _delimiters = {'csv': ',', 'ssv': ' ', 'tsv': '\t', 'pipes': '|'};
const _dateEpochMarker = 'epoch';
const _deepEquality = DeepCollectionEquality();
final _dateFormatter = DateFormat('yyyy-MM-dd');
final _regList = RegExp(r'^List<(.*)>$');
final _regSet = RegExp(r'^Set<(.*)>$');
final _regMap = RegExp(r'^Map<String,(.*)>$');

bool _isEpochMarker(String? pattern) => pattern == _dateEpochMarker || pattern == '/$_dateEpochMarker/';

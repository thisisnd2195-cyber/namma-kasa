import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../core/api.dart';

/// Photos are compressed to about this size before upload. Drivers work on
/// metered connections in 2G pockets; a 4 MB camera original would either fail
/// or cost them their data (FR-DRV-06).
const _maxBytes = 500 * 1024;

class PendingPhoto {
  const PendingPhoto({required this.file, required this.capturedAt, this.lat, this.lng});

  final File file;
  final DateTime capturedAt;
  final double? lat;
  final double? lng;
}

class PhotoQueueState {
  const PhotoQueueState({this.pending = const [], this.uploading = false, this.uploaded = 0});

  final List<PendingPhoto> pending;
  final bool uploading;
  final int uploaded;
}

/// Captures, compresses and uploads collection-proof photos.
///
/// Nothing is discarded on failure: a photo taken in a dead zone stays queued
/// until it lands, the same rule the GPS spool follows.
class PhotoQueue extends StateNotifier<PhotoQueueState> {
  PhotoQueue(this._api) : super(const PhotoQueueState());

  final Api _api;
  final ImagePicker _picker = ImagePicker();

  /// Camera-first: a proof photo of a street has to be taken there and then.
  Future<PendingPhoto?> capture({double? lat, double? lng}) async {
    final shot = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
      maxWidth: 1600,
    );
    if (shot == null) return null;

    final compressed = await _compress(File(shot.path));
    final photo = PendingPhoto(
      file: compressed,
      capturedAt: DateTime.now(),
      lat: lat,
      lng: lng,
    );
    state = PhotoQueueState(
      pending: [...state.pending, photo],
      uploading: state.uploading,
      uploaded: state.uploaded,
    );
    return photo;
  }

  Future<File> _compress(File original) async {
    if (await original.length() <= _maxBytes) return original;

    final target = '${original.path}_c.jpg';
    final result = await FlutterImageCompress.compressAndGetFile(
      original.absolute.path,
      target,
      quality: 60,
      minWidth: 1280,
      minHeight: 720,
    );
    return result == null ? original : File(result.path);
  }

  /// Drains the queue. Anything that fails stays put for the next attempt.
  Future<void> flush(String tripId) async {
    if (state.pending.isEmpty || state.uploading) return;
    state = PhotoQueueState(
      pending: state.pending,
      uploading: true,
      uploaded: state.uploaded,
    );

    final remaining = <PendingPhoto>[];
    var uploaded = state.uploaded;

    for (final photo in state.pending) {
      try {
        final presign = await _api.presignTripMedia(tripId);
        await Dio().put<void>(
          presign['uploadUrl'] as String,
          data: photo.file.openRead(),
          options: Options(
            headers: {
              Headers.contentTypeHeader: 'image/jpeg',
              Headers.contentLengthHeader: await photo.file.length(),
            },
          ),
        );
        await _api.confirmTripMedia(
          tripId: tripId,
          uploadId: presign['uploadId'] as String,
          objectUrl: presign['objectUrl'] as String,
          lat: photo.lat,
          lng: photo.lng,
          capturedAt: photo.capturedAt,
        );
        uploaded += 1;
      } catch (_) {
        remaining.add(photo);
      }
    }

    state = PhotoQueueState(pending: remaining, uploading: false, uploaded: uploaded);
  }
}

final photoQueueProvider = StateNotifierProvider<PhotoQueue, PhotoQueueState>(
  (ref) => PhotoQueue(ref.watch(apiProvider)),
);

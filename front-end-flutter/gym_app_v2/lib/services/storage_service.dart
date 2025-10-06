import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as p;
import '../core/logging/app_logger.dart';

/// A lightweight wrapper around Firebase Storage for uploading and deleting files.
/// Usage:
/// final url = await StorageService.instance.uploadFile(
///   file: File(path),
///   folder: 'coach-media',
///   onProgress: (p) => print('Progress ${(p*100).toStringAsFixed(1)}%'),
/// );
class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload a [file] to [folder]. Returns download URL or null on failure.
  Future<String?> uploadFile({
    required File file,
    required String folder,
    Map<String, String>? metadata,
    void Function(double progress)? onProgress,
  }) async {
    try {
      final ext = p.extension(file.path); // .jpg, .png, .mp4 ...
      final safeBase = p
          .basenameWithoutExtension(file.path)
          .replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
      final ts = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${ts}_$safeBase$ext';
      final ref = _storage.ref().child('$folder/$fileName');

      final uploadTask = ref.putFile(
        file,
        metadata == null ? null : SettableMetadata(customMetadata: metadata),
      );

      if (onProgress != null) {
        uploadTask.snapshotEvents.listen((s) {
          if (s.totalBytes > 0) {
            onProgress(s.bytesTransferred / s.totalBytes);
          }
        });
      }

      final snapshot = await uploadTask.whenComplete(() {});
      if (snapshot.state == TaskState.success) {
        final url = await ref.getDownloadURL();
        AppLogger.info('Upload success: $url', tag: 'Storage');
        return url;
      } else {
        AppLogger.warn('Upload failed state=${snapshot.state}', tag: 'Storage');
      }
    } catch (e, st) {
      AppLogger.warn('Upload error: $e', tag: 'Storage');
      AppLogger.debug(st.toString(), tag: 'Storage');
    }
    return null;
  }

  /// Delete by full download [url]. Ignores errors silently.
  Future<void> deleteByUrl(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
      AppLogger.info('Deleted: $url', tag: 'Storage');
    } catch (e) {
      AppLogger.warn('Delete failed (ignored): $e', tag: 'Storage');
    }
  }
}

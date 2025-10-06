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
      // Infer simple contentType for images to satisfy restrictive Storage rules.
      final contentType = _inferContentType(ext);
      final fileLength = await file.length();
      AppLogger.info(
        'Uploading -> path=$folder/$fileName size=${fileLength}B type=$contentType',
        tag: 'Storage',
      );
      final uploadTask = ref.putFile(
        file,
        SettableMetadata(
          contentType: contentType,
          customMetadata: metadata,
          cacheControl: 'public,max-age=604800',
        ),
      );

      if (onProgress != null) {
        uploadTask.snapshotEvents.listen(
          (s) {
            if (s.totalBytes > 0) {
              onProgress(s.bytesTransferred / s.totalBytes);
            }
          },
          onError: (err, st) {
            AppLogger.warn('Upload stream error: $err', tag: 'Storage');
          },
          cancelOnError: true,
        );
      }

      // Await the task directly so exceptions bubble to this try/catch.
      final snapshot = await uploadTask;
      if (snapshot.state == TaskState.success) {
        final url = await ref.getDownloadURL();
        AppLogger.info('Upload success: $url', tag: 'Storage');
        return url;
      } else {
        AppLogger.warn('Upload failed state=${snapshot.state}', tag: 'Storage');
      }
    } on FirebaseException catch (e, st) {
      if (e.code == 'unauthorized') {
        AppLogger.warn(
          'Upload unauthorized: check Storage rules. ${e.message}',
          tag: 'Storage',
        );
      } else {
        AppLogger.warn(
          'FirebaseException during upload: ${e.code} ${e.message}',
          tag: 'Storage',
        );
      }
      AppLogger.debug(st.toString(), tag: 'Storage');
    } catch (e, st) {
      AppLogger.warn('Upload error (generic): $e', tag: 'Storage');
      AppLogger.debug(st.toString(), tag: 'Storage');
    }
    return null;
  }

  String _inferContentType(String ext) {
    switch (ext.toLowerCase()) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      default:
        return 'application/octet-stream';
    }
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

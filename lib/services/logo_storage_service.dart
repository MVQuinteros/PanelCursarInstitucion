import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

/// Servicio para subir logos de instituciones a Firebase Storage.
///
/// Los archivos se guardan bajo:
///   `logos_instituciones/{institucionUid}/{fileName}`
///
/// Devuelve la URL de descarga pública para guardar en Firestore.
class LogoStorageService {
  LogoStorageService._();

  static final LogoStorageService instance = LogoStorageService._();

  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Sube los bytes de una imagen a Firebase Storage y devuelve la URL de descarga.
  ///
  /// - [bytes]: datos de la imagen (en web provienen de `file_picker`).
  /// - [institucionUid]: ID de la institución dueña del logo.
  /// - [fileName]: nombre original del archivo.
  Future<String> subirLogo({
    required Uint8List bytes,
    required String institucionUid,
    required String fileName,
  }) async {
    final ref = _storage
        .ref()
        .child('logos_instituciones/$institucionUid/$fileName');

    final metadata = SettableMetadata(
      contentType: 'image/jpeg',
      customMetadata: {
        'institucionUid': institucionUid,
      },
    );

    final task = await ref.putData(bytes, metadata);
    final downloadUrl = await task.ref.getDownloadURL();
    return downloadUrl;
  }

  /// Elimina un archivo de Storage dado su URL de descarga.
  Future<void> eliminarLogo(String downloadUrl) async {
    try {
      final ref = _storage.refFromURL(downloadUrl);
      await ref.delete();
    } catch (_) {
      // Si no existe o ya fue eliminado, ignorar.
    }
  }
}

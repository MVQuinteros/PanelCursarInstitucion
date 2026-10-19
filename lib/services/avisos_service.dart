import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/aviso_model.dart';
import '../services/auth_service.dart';

/// Servicio de avisos institucionales.
///
/// Mismo funcionamiento que `OfertasService`: cada institución solo ve y
/// gestiona sus propios avisos, filtrados por `institucionUid` y ordenados
/// por fecha de creación (historial: los avisos viejos permanecen en la
/// lista hasta que la institución los elimina).
class AvisosService {
  AvisosService._();

  static final AvisosService instance = AvisosService._();

  static const _coleccion = 'avisos_instituciones';

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  /// Referencia a la colección de avisos institucionales.
  CollectionReference<Map<String, dynamic>> get _avisos =>
      _db.collection(_coleccion);

  /// Stream de avisos de una institución, ordenados por fecha de creación
  /// (el más nuevo primero).
  Stream<List<AvisoModel>> avisosDeInstitucion(String institucionUid) {
    return _avisos
        .where('institucionUid', isEqualTo: institucionUid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => AvisoModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  /// Crea un aviso nuevo vinculado a la institución de la sesión actual
  /// y devuelve el ID asignado.
  Future<String> crearAviso(AvisoModel aviso) async {
    final institucionUid = AuthService.instance.sesion?.institucionUid ?? '';
    final ahora = FieldValue.serverTimestamp();
    final datos = aviso.toMap()
      ..remove('avisoId')
      ..remove('institucionUid')
      ..remove('createdAt')
      ..remove('updatedAt');
    final doc = await _avisos.add({
      ...datos,
      'institucionUid': institucionUid,
      'createdAt': ahora,
      'updatedAt': ahora,
    });
    return doc.id;
  }

  /// Actualiza un aviso existente. Se preserva la pertenencia
  /// (`institucionUid`) y la fecha de creación.
  Future<void> actualizarAviso(String avisoId, AvisoModel aviso) async {
    final datos = aviso.toMap()
      ..remove('avisoId')
      ..remove('institucionUid')
      ..remove('createdAt')
      ..remove('updatedAt');
    await _avisos.doc(avisoId).update({
      ...datos,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Elimina definitivamente un aviso del historial de la institución.
  Future<void> eliminarAviso(String avisoId) async {
    await _avisos.doc(avisoId).delete();
  }
}

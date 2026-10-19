import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/oferta_model.dart';
import '../services/auth_service.dart';

/// Servicio de ofertas académicas.
///
/// Cada institución solo puede crear, leer, actualizar y dar de baja
/// (baja lógica: `estado = 'inactiva'`) sus propias ofertas,
/// filtradas por `institucionUid`.
///
/// Moderación: al crear una oferta queda en `aprobada: false` (pendiente).
/// El panel de administración es quien la aprueba para publicarla en la app.
class OfertasService {
  OfertasService._();

  static final OfertasService instance = OfertasService._();

  static const _coleccion = 'ofertas';

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  /// Referencia a la colección de ofertas.
  CollectionReference<Map<String, dynamic>> get _ofertas =>
      _db.collection(_coleccion);

  /// Stream de ofertas de una institución, ordenadas por fecha de creación.
  Stream<List<OfertaModel>> ofertasDeInstitucion(String institucionUid) {
    return _ofertas
        .where('institucionUid', isEqualTo: institucionUid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => OfertaModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  /// Obtiene una oferta puntual (para precargar el formulario de edición).
  Future<OfertaModel?> obtenerOferta(String ofertaId) async {
    final doc = await _ofertas.doc(ofertaId).get();
    if (!doc.exists) return null;
    return OfertaModel.fromMap(doc.id, doc.data()!);
  }

  /// Crea una nueva oferta vinculada a la institución de la sesión actual
  /// y devuelve el ID asignado.
  ///
  /// Siempre nace como pendiente de moderación (`aprobada: false`).
  Future<String> crearOferta(OfertaModel oferta) async {
    final institucionUid = AuthService.instance.sesion?.institucionUid ?? '';
    final ahora = FieldValue.serverTimestamp();
    final datos = oferta.toMap()..remove('ofertaId');
    final doc = await _ofertas.add({
      ...datos,
      'institucionUid': institucionUid,
      'estado': 'activa',
      'aprobada': false,
      'createdAt': ahora,
      'updatedAt': ahora,
    });
    return doc.id;
  }

  /// Actualiza una oferta existente. Solo se permite editar campos de
  /// contenido: se preservan la moderación (`aprobada`), el estado, la
  /// pertenencia (`institucionUid`) y la fecha de creación.
  Future<void> actualizarOferta(String ofertaId, OfertaModel oferta) async {
    final datos = oferta.toMap()
      ..remove('ofertaId')
      ..remove('institucionUid')
      ..remove('aprobada')
      ..remove('estado')
      ..remove('createdAt');
    await _ofertas.doc(ofertaId).update({
      ...datos,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Marca la oferta como pendiente otra vez (para reenviar a revisión).
  Future<void> reenviarARevision(String ofertaId) async {
    await _ofertas.doc(ofertaId).update({
      'aprobada': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Baja lógica de una oferta: cambia `estado` a `'inactiva'`.
  Future<void> desactivarOferta(String ofertaId) async {
    await _ofertas.doc(ofertaId).update({
      'estado': 'inactiva',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Reactiva una oferta previamente desactivada.
  Future<void> activarOferta(String ofertaId) async {
    await _ofertas.doc(ofertaId).update({
      'estado': 'activa',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Elimina definitivamente una oferta de Firestore.
  Future<void> eliminarOferta(String ofertaId) async {
    await _ofertas.doc(ofertaId).delete();
  }
}

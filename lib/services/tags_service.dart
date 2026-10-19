import 'package:cloud_firestore/cloud_firestore.dart';

/// Servicio de etiquetas (`tags`) usadas para categorizar ofertas.
///
/// La colección `tags` la administra el panel de administración; acá solo
/// se leen los nombres para poblar el selector del formulario de oferta.
class TagsService {
  TagsService._();

  static final TagsService instance = TagsService._();

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  /// Devuelve la lista de nombres de tags (orden alfabético).
  Future<List<String>> obtenerNombres() async {
    try {
      final snap = await _db.collection('tags').get();
      final nombres =
          snap.docs
              .map((d) => (d.data()['nombre'] ?? '').toString().trim())
              .where((n) => n.isNotEmpty)
              .toList()
            ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      return nombres;
    } catch (_) {
      // Si la colección no existe o no hay permisos, no rompemos el formulario.
      return const <String>[];
    }
  }
}

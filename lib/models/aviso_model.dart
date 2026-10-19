import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo de aviso institucional (`avisos_instituciones`).
///
/// Es el equivalente institucional de los avisos globales (`avisos`) de la
/// app: cada institución publica sus propios avisos y se guardan como
/// historial (nunca se archivan; se editan o eliminan).
class AvisoModel {
  final String avisoId;
  final String institucionUid;
  final String titulo;
  final String mensaje;
  final String tipo;
  final String link;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  AvisoModel({
    required this.avisoId,
    required this.institucionUid,
    required this.titulo,
    required this.mensaje,
    required this.tipo,
    this.link = '',
    this.createdAt,
    this.updatedAt,
  });

  factory AvisoModel.fromMap(String id, Map<String, dynamic> map) {
    return AvisoModel(
      avisoId: id,
      institucionUid: map['institucionUid'] ?? '',
      titulo: map['titulo'] ?? '',
      mensaje: map['mensaje'] ?? '',
      tipo: map['tipo'] ?? 'noticia',
      link: map['link'] ?? '',
      createdAt: _fecha(map['createdAt']),
      updatedAt: _fecha(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'avisoId': avisoId,
      'institucionUid': institucionUid,
      'titulo': titulo,
      'mensaje': mensaje,
      'tipo': tipo,
      'link': link,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  static DateTime? _fecha(dynamic valor) {
    if (valor is Timestamp) return valor.toDate();
    if (valor is DateTime) return valor;
    return null;
  }
}

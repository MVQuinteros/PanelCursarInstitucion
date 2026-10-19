/// Modelo de oferta académica de una institución.
///
/// Campos:
///   - [ofertaId]       : ID del documento en Firestore.
///   - [institucionUid] : UID de la institución dueña (filtro de pertenencia).
///   - [nombre]         : Nombre de la carrera/curso/título.
///   - [descripcion]    : Descripción detallada.
///   - [area]           : Área académica (ej. Salud, Tecnología, Educación).
///   - [nivel]          : Nivel (ej. Tecnicatura, Licenciatura, Posgrado, Curso).
///   - [duracionAnios]  : Duración en años.
///   - [modalidad]      : Presencial / Virtual / Híbrida.
///   - [salidaLaboral]  : Campo laboral.
///   - [requisitos]     : Requisitos de ingreso.
///   - [tag]            : Etiqueta para filtrar/buscar.
///   - [estado]         : 'activa' | 'inactiva' (baja lógica, sin borrar).
///   - [aprobada]       : Moderación del admin (false = pendiente; no se
///                        publica en la app hasta que la aprueben).
///   - [createdAt]      : Fecha de creación.
///   - [updatedAt]      : Última modificación.
class OfertaModel {
  final String ofertaId;
  final String institucionUid;
  final String nombre;
  final String descripcion;
  final String area;
  final String nivel;
  final int duracionAnios;
  final String modalidad;
  final String salidaLaboral;
  final String requisitos;
  final String tag;
  final String estado;
  final bool aprobada;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  OfertaModel({
    required this.ofertaId,
    required this.institucionUid,
    required this.nombre,
    required this.descripcion,
    required this.area,
    required this.nivel,
    required this.duracionAnios,
    required this.modalidad,
    required this.salidaLaboral,
    required this.requisitos,
    required this.tag,
    this.estado = 'activa',
    this.aprobada = false,
    this.createdAt,
    this.updatedAt,
  });

  /// Indica si la oferta está publicada/activa (control de la institución).
  bool get estaActiva => estado == 'activa';

  /// Indica si el admin ya aprobó la oferta (moderación).
  bool get estaAprobada => aprobada;

  factory OfertaModel.fromMap(String id, Map<String, dynamic> map) {
    return OfertaModel(
      ofertaId: id,
      institucionUid: map['institucionUid']?.toString() ?? '',
      nombre: map['nombre']?.toString() ?? '',
      descripcion: map['descripcion']?.toString() ?? '',
      area: map['area']?.toString() ?? '',
      nivel: map['nivel']?.toString() ?? '',
      duracionAnios: map['duracionAnios'] ?? 0,
      modalidad: map['modalidad']?.toString() ?? '',
      salidaLaboral: map['salidaLaboral']?.toString() ?? '',
      requisitos: map['requisitos']?.toString() ?? '',
      tag: map['tag']?.toString() ?? '',
      estado: map['estado']?.toString() ?? 'activa',
      aprobada: map['aprobada'] == true,
      createdAt: (map['createdAt'] as dynamic)?.toDate(),
      updatedAt: (map['updatedAt'] as dynamic)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ofertaId': ofertaId,
      'institucionUid': institucionUid,
      'nombre': nombre,
      'descripcion': descripcion,
      'area': area,
      'nivel': nivel,
      'duracionAnios': duracionAnios,
      'modalidad': modalidad,
      'salidaLaboral': salidaLaboral,
      'requisitos': requisitos,
      'tag': tag,
      'estado': estado,
      'aprobada': aprobada,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}

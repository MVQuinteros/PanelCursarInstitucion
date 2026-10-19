import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo de la institución (espejo de `InstitucionModel` de la app CURSAR).
///
/// La ubicación se guarda como `ubicacion: GeoPoint` en Firestore y también
/// como `latitud`/`longitud` numéricos para compatibilidad de lecturas.
class InstitucionModel {
  final String institucionUid;
  final String nombre;
  final String descripcion;
  final String direccion;
  final String ciudad;
  final String provincia;
  final String telefono;
  final String email;
  final String sitioWeb;
  final String logoURL;
  final double? latitud;
  final double? longitud;
  final String estado;
  final DateTime? createdAt;

  InstitucionModel({
    required this.institucionUid,
    required this.nombre,
    required this.descripcion,
    required this.direccion,
    required this.ciudad,
    required this.provincia,
    required this.telefono,
    required this.email,
    required this.sitioWeb,
    required this.logoURL,
    this.latitud,
    this.longitud,
    this.estado = 'pendiente',
    this.createdAt,
  });

  /// Indica si la institución tiene coordenadas cargadas (mapa en la app).
  bool get tieneUbicacion => latitud != null && longitud != null;

  factory InstitucionModel.fromMap(String id, Map<String, dynamic> map) {
    final ubicacion = map['ubicacion'];
    double? lat = (map['latitud'] as num?)?.toDouble();
    double? lng = (map['longitud'] as num?)?.toDouble();
    if (ubicacion is GeoPoint) {
      lat ??= ubicacion.latitude;
      lng ??= ubicacion.longitude;
    }
    return InstitucionModel(
      institucionUid: id,
      nombre: map['nombre']?.toString() ?? '',
      descripcion: map['descripcion']?.toString() ?? '',
      direccion: map['direccion']?.toString() ?? '',
      ciudad: map['ciudad']?.toString() ?? '',
      provincia: map['provincia']?.toString() ?? '',
      telefono: map['telefono']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      sitioWeb: map['sitioWeb']?.toString() ?? '',
      logoURL: map['logoURL']?.toString() ?? '',
      latitud: lat,
      longitud: lng,
      estado: map['estado']?.toString() ?? 'pendiente',
      createdAt: (map['createdAt'] as dynamic)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'institucionUid': institucionUid,
      'nombre': nombre,
      'descripcion': descripcion,
      'direccion': direccion,
      'ciudad': ciudad,
      'provincia': provincia,
      'telefono': telefono,
      'email': email,
      'sitioWeb': sitioWeb,
      'logoURL': logoURL,
      'latitud': latitud,
      'longitud': longitud,
      'ubicacion': (latitud != null && longitud != null)
          ? GeoPoint(latitud!, longitud!)
          : null,
      'estado': estado,
      'createdAt': createdAt,
    };
  }
}

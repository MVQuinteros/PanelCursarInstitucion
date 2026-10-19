/// Sesión del usuario logueado en el portal, con su vínculo a una institución.
///
/// La vinculación es la "Opción A": en `usuarios/{uid}` se guardan
/// `rol: "institucion"` e `institucionUid`, y la institución lista a sus
/// administradores en `instituciones/{id}.ownerUids`.
class SesionInstitucion {
  final String uid;
  final String email;
  final String nombre;
  final String apellido;
  final String rol;
  final String institucionUid;
  final String estadoInstitucion;
  final String institucionNombre;
  final String institucionLogo;

  const SesionInstitucion({
    required this.uid,
    required this.email,
    required this.nombre,
    required this.apellido,
    required this.rol,
    required this.institucionUid,
    required this.estadoInstitucion,
    required this.institucionNombre,
    required this.institucionLogo,
  });

  bool get esInstitucion => rol == 'institucion';

  bool get aprobada => estadoInstitucion == 'aprobada';
}
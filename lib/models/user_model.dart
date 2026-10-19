class UserModel {
  final String uid;
  final String nombre;
  final String apellido;
  final String email;
  final String? contrasenaHash;
  final String rol;
  final DateTime? ultimoLogin;
  final DateTime? fechaNacimiento;
  final String? localidad;

  UserModel({
    required this.uid,
    required this.nombre,
    required this.apellido,
    required this.email,
    this.contrasenaHash,
    this.rol = 'usuario',
    this.ultimoLogin,
    this.fechaNacimiento,
    this.localidad,
  });

  factory UserModel.fromMap(String uid, Map<String, dynamic> map) {
    return UserModel(
      uid: uid,
      nombre: map['nombre'] ?? '',
      apellido: map['apellido'] ?? '',
      email: map['email'] ?? '',
      contrasenaHash: map['contraseñaHash'],
      rol: map['rol'] ?? 'usuario',
      ultimoLogin: (map['ultimoLogin'] as dynamic)?.toDate(),
      fechaNacimiento: (map['fechaNacimiento'] as dynamic)?.toDate(),
      localidad: map['localidad'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'nombre': nombre,
      'apellido': apellido,
      'email': email,
      'contraseñaHash': contrasenaHash,
      'rol': rol,
      'ultimoLogin': ultimoLogin,
      'fechaNacimiento': fechaNacimiento,
      'localidad': localidad,
    };
  }
}

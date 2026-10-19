import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/sesion_institucion.dart';

/// Logs de depuración para el flujo de autenticación y registro.
void _log(String mensaje) {
  debugPrint('[AuthService] $mensaje');
}

/// Gestiona el login/logout y mantiene la sesión vinculada a la institución
/// (Opción A: `usuarios/{uid}.rol` + `usuarios/{uid}.institucionUid`).
///
/// Escucha `authStateChanges()` y el documento `usuarios/{uid}` en tiempo real.
/// Cada cambio notifica a la UI (el router usa esto para redirigir).
class AuthService extends ChangeNotifier {
  AuthService._();

  static final AuthService instance = AuthService._();

  User? _firebaseUser;
  SesionInstitucion? _sesion;
  bool _inicializando = true;
  StreamSubscription<DocumentSnapshot>? _subUsuario;
  bool _escuchando = false;

  bool get inicializando => _inicializando;
  bool get estaLogueado => _firebaseUser != null;
  SesionInstitucion? get sesion => _sesion;

  /// Inicia la escucha del estado de autenticación. Llamar una sola vez en `main`.
  void iniciar() {
    if (_escuchando) return;
    _escuchando = true;
    FirebaseAuth.instance.authStateChanges().listen((user) {
      _firebaseUser = user;
      _subUsuario?.cancel();
      _subUsuario = null;
      if (user == null) {
        _log('authStateChanges: usuario desconectado');
        _sesion = null;
        _inicializando = false;
        notifyListeners();
        return;
      }
      _log('authStateChanges: usuario conectado, uid=${user.uid}');
      _inicializando = true;
      notifyListeners();
      _subUsuario = FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .snapshots()
          .listen((doc) async {
        if (!doc.exists) {
          _log('usuarios/${user.uid}: documento no encontrado');
          _sesion = null;
          _inicializando = false;
          notifyListeners();
          return;
        }
        final data = doc.data() as Map<String, dynamic>;
        final institucionUid =
            data['institucionUid']?.toString() ?? '';

        String estadoInstitucion = 'pendiente';
        String institucionNombre = '';
        String institucionLogo = '';

        if (institucionUid.isNotEmpty) {
          try {
            final instDoc = await FirebaseFirestore.instance
                .collection('instituciones')
                .doc(institucionUid)
                .get();
            if (instDoc.exists) {
              final instData = instDoc.data() as Map<String, dynamic>;
              estadoInstitucion =
                  instData['estado']?.toString() ?? 'pendiente';
              institucionNombre = instData['nombre']?.toString() ?? '';
              institucionLogo = instData['logoURL']?.toString() ?? '';
            } else {
              estadoInstitucion = 'no-vinculada';
            }
          } catch (_) {
            estadoInstitucion = 'no-vinculada';
          }
        }

        _sesion = SesionInstitucion(
          uid: user.uid,
          email: user.email ?? '',
          nombre: data['nombre']?.toString() ?? '',
          apellido: data['apellido']?.toString() ?? '',
          rol: data['rol']?.toString() ?? 'usuario',
          institucionUid: institucionUid,
          estadoInstitucion: estadoInstitucion,
          institucionNombre: institucionNombre,
          institucionLogo: institucionLogo,
        );
        _inicializando = false;
        notifyListeners();
      });
    });
  }

  Future<void> iniciarSesion({
    required String email,
    required String password,
  }) async {
    final emailTrim = email.trim();
    _log('Iniciando sesión: email=$emailTrim');
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailTrim,
        password: password,
      );
      _log('Sesión iniciada correctamente: email=$emailTrim');
    } catch (e) {
      _log('Error al iniciar sesión: email=$emailTrim, error=$e');
      rethrow;
    }
  }

  Future<void> iniciarSesionConGoogle() async {
    final provider = GoogleAuthProvider();
    await FirebaseAuth.instance.signInWithPopup(provider);
  }

  /// Crea la cuenta de una institución nueva:
  /// 1) Cuenta de Firebase Auth.
  /// 2) Documento `instituciones/{id}` con `estado: "pendiente"`.
  /// 3) Documento `usuarios/{uid}` vinculado (rol institucion + institucionUid).
  Future<void> registrarInstitucion({
    required String nombre,
    required String descripcion,
    required String email,
    required String password,
    required String telefono,
  }) async {
    _log('Iniciando registro de institución: email=$email');

    // 1) Cuenta de Firebase Auth.
    _log('Paso 1: creando cuenta en Firebase Auth...');
    final credencial = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(email: email.trim(), password: password);
    final user = credencial.user!;
    _log('Paso 1 OK: usuario creado en Auth, uid=${user.uid}');

    final institucionUid = _generarIdInstitucion(nombre);
    _log('Paso 2: institucionesUid generado=$institucionUid');

    final firestore = FirebaseFirestore.instance;

    // 2) Documento `instituciones/{id}` con estado pendiente.
    _log('Paso 3: creando documento instituciones/$institucionUid...');
    await firestore.collection('instituciones').doc(institucionUid).set({
      'nombre': nombre.trim(),
      'descripcion': descripcion.trim(),
      'direccion': '',
      'ciudad': '',
      'provincia': '',
      'telefono': telefono.trim(),
      'email': email.trim(),
      'sitioWeb': '',
      'logoURL': '',
      'ubicacion': null,
      'estado': 'pendiente',
      'ownerUids': [user.uid],
      'createdAt': FieldValue.serverTimestamp(),
    });
    _log('Paso 3 OK: documento instituciones/$institucionUid creado');

    // 3) Documento `usuarios/{uid}` vinculado.
    _log('Paso 4: creando documento usuarios/${user.uid}...');
    await firestore.collection('usuarios').doc(user.uid).set({
      'uid': user.uid,
      'nombre': nombre.trim(),
      'apellido': '',
      'email': email.trim(),
      'rol': 'institucion',
      'institucionUid': institucionUid,
      'ultimoLogin': FieldValue.serverTimestamp(),
    });
    _log('Paso 4 OK: documento usuarios/${user.uid} creado');

    await user.updateDisplayName(nombre.trim());
    _log('Registro completo para $email (uid=${user.uid}, institucion=$institucionUid)');
  }

  Future<void> cerrarSesion() async {
    await FirebaseAuth.instance.signOut();
  }

  Future<void> resetPassword(String email) async {
    await FirebaseAuth.instance.sendPasswordResetEmail(email: email.trim());
  }

  String _generarIdInstitucion(String nombre) {
    final slug = nombre
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[áàâä]'), 'a')
        .replaceAll(RegExp(r'[éèêë]'), 'e')
        .replaceAll(RegExp(r'[íìîï]'), 'i')
        .replaceAll(RegExp(r'[óòôö]'), 'o')
        .replaceAll(RegExp(r'[úùûü]'), 'u')
        .replaceAll('ñ', 'n')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    final sufijo = DateTime.now().millisecondsSinceEpoch % 100000;
    return '${slug.isEmpty ? 'institucion' : slug}_$sufijo';
  }

  /// Devuelve el mensaje de error amigable según el código de Firebase.
  String mensajeError(Object error) {
    // Errores de Firebase Authentication.
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'No hay un usuario registrado con ese email';
        case 'wrong-password':
          return 'Contraseña incorrecta';
        case 'invalid-email':
          return 'Email inválido';
        case 'invalid-credential':
          return 'Email o contraseña incorrectos';
        case 'email-already-in-use':
          return 'Ya existe una cuenta con ese email';
        case 'weak-password':
          return 'La contraseña es muy débil';
        case 'user-disabled':
          return 'La cuenta fue deshabilitada';
        default:
          return 'Error de autenticación (${error.code}). Intentá de nuevo.';
      }
    }

    // Errores generales de Firebase (incluye Firestore).
    if (error is FirebaseException) {
      return 'Error de Firebase (${error.code}): ${error.message ?? 'sin detalles'}';
    }

    return 'Error inesperado: $error';
  }

  @override
  void dispose() {
    _subUsuario?.cancel();
    super.dispose();
  }
}
import 'package:firebase_core/firebase_core.dart';

/// Configuración compartida del proyecto Firebase de CursAR.
///
/// IMPORTANTE: este sitio web usa el MISMO proyecto Firebase que la app móvil
/// (`proyecto-app-a77c8`). Los valores de apiKey / authDomain / projectId /
/// storageBucket son los mismos; solo el `appId` cambia por plataforma.
///
/// PASO 1 (obligatorio antes de ejecutar):
///   1. Andá a https://console.firebase.google.com -> proyecto-app-a77c8.
///   2. Agregar app -> Web -> registrá con cualquier nombre (ej: "Portal Instituciones").
///   3. Copiá el `appId` web que te muestra (formato: 1:642247955799:web:XXXX)
///      y pegalo abajo en firebaseOptionsWeb.
const FirebaseOptions firebaseOptionsWeb = FirebaseOptions(
  apiKey: 'AIzaSyCxxHznw7qA_N5ZthZKMrHkBTKStyaeESA',
  authDomain: 'proyecto-app-a77c8.firebaseapp.com',
  projectId: 'proyecto-app-a77c8',
  storageBucket: 'proyecto-app-a77c8.firebasestorage.app',
  messagingSenderId: '642247955799',
  appId: '1:642247955799:web:41f33c939c9f9ddc475a12',
);

Future<void> initializeFirebase() async {
  if (Firebase.apps.isNotEmpty) return;
  await Firebase.initializeApp(options: firebaseOptionsWeb);
}
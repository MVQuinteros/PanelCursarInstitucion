import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_config.dart';
import 'router/app_router.dart';
import 'services/auth_service.dart';
import 'core/theme/cursar_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: firebaseOptionsWeb);
  AuthService.instance.iniciar();
  runApp(const PortalInstitucionesApp());
}

/// Widget raíz del portal de instituciones.
class PortalInstitucionesApp extends StatelessWidget {
  const PortalInstitucionesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Instituciones CursAR',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.light,
      routerConfig: AppRouter.router,
    );
  }
}

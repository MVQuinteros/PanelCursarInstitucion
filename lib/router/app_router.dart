import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/auth_service.dart';
import '../screens/institucion_dashboard_screen.dart';
import '../screens/institucion_perfil_screen.dart';
import '../screens/login_screen.dart';
import '../screens/oferta_form_screen.dart';
import '../screens/ofertas_list_screen.dart';
import '../screens/registro_screen.dart';
import '../widgets/institucion_layout.dart';

/// Configuración de navegación del portal de instituciones.
///
/// Rutas públicas:
///   - `/`        : redirección según estado de autenticación.
///   - `/login`   : pantalla de inicio de sesión.
///   - `/registro`: pantalla de registro de institución.
///
/// Rutas protegidas (requieren sesión activa de institución):
///   - `/institucion`              : dashboard del panel institucional.
///   - `/institucion/ofertas`      : listado de ofertas académicas.
///   - `/institucion/ofertas/nueva`: formulario para crear oferta.
///   - `/institucion/ofertas/:id/editar` : formulario para editar oferta.
///   - `/institucion/perfil`       : edición de datos de la institución.
class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    refreshListenable: AuthService.instance,
    redirect: (context, state) {
      final auth = AuthService.instance;

      // Mientras se inicializa Firebase, no redirigir.
      if (auth.inicializando) return null;

      final estaLogueado = auth.estaLogueado;
      final sesion = auth.sesion;
      final esInstitucion = sesion?.esInstitucion ?? false;

      final esRutaLogin = state.matchedLocation == '/login';
      final esRutaRegistro = state.matchedLocation == '/registro';
      final esRutaPublica = esRutaLogin || esRutaRegistro;

      // No hay sesión: enviar a login (salvo si ya está en login/registro).
      if (!estaLogueado) {
        return esRutaPublica ? null : '/login';
      }

      // Hay sesión pero no es institución: redirigir a login (no aplica).
      if (!esInstitucion) {
        return '/login';
      }

      // La institución puede entrar aunque esté pendiente de aprobación:
      // así carga su perfil y ofertas mientras espera la moderación del admin.
      // (El aviso de "pendiente" se muestra dentro del panel.)

      // Sesión válida: si intenta ir a login/registro, enviar al dashboard.
      if (esRutaPublica) {
        return '/institucion';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        redirect: (context, state) {
          final auth = AuthService.instance;
          if (auth.inicializando) return null;
          final estaLogueado = auth.estaLogueado;
          final sesion = auth.sesion;
          final esInstitucion = sesion?.esInstitucion ?? false;

          if (!estaLogueado) return '/login';
          if (!esInstitucion) return '/login';
          return '/institucion';
        },
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/registro',
        builder: (context, state) => const RegistroScreen(),
      ),
      // Rutas protegidas envueltas en el layout del panel institucional.
      ShellRoute(
        builder: (context, state, child) =>
            InstitucionLayout(child: child, location: state.uri.toString()),
        routes: [
          GoRoute(
            path: '/institucion',
            builder: (context, state) => const InstitucionDashboardScreen(),
          ),
          GoRoute(
            path: '/institucion/ofertas',
            builder: (context, state) => const OfertasListScreen(),
          ),
          GoRoute(
            path: '/institucion/ofertas/nueva',
            builder: (context, state) => const OfertaFormScreen(),
          ),
          GoRoute(
            path: '/institucion/ofertas/:id/editar',
            builder: (context, state) {
              final ofertaId = state.pathParameters['id']!;
              return OfertaFormScreen(ofertaId: ofertaId);
            },
          ),
          GoRoute(
            path: '/institucion/perfil',
            builder: (context, state) => const InstitucionPerfilScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) =>
        const Scaffold(body: Center(child: Text('Página no encontrada'))),
  );
}

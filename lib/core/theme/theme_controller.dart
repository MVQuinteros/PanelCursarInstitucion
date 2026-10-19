import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

/// Controlador global del modo claro/oscuro del panel.
///
/// Sin dependencias de estado: un `ValueNotifier` simple que `MaterialApp`
/// escucha (en `main.dart`) para reconstruir el árbol con el tema elegido.
/// El botón del topbar alterna el modo con [alternar].
///
/// La elección se guarda en `localStorage` del navegador (clave
/// [ThemeController.claveTema]) para que al volver a entrar al panel
/// se recuerde entre sesiones.
class ThemeController {
  ThemeController._();

  /// Clave de `localStorage` donde se persiste el modo.
  static const String claveTema = 'cursar_tema';

  /// Tema guardado en el navegador (`'dark'` / `'light'` / `null`).
  static ThemeMode _leerGuardado() {
    try {
      final valor = web.window.localStorage.getItem(claveTema);
      if (valor == 'dark') return ThemeMode.dark;
      if (valor == 'light') return ThemeMode.light;
    } catch (_) {
      // Modo incógnito / almacenamiento bloqueado: se usa el valor por defecto.
    }
    return ThemeMode.light;
  }

  /// Modo actual de la aplicación (lo que diga `localStorage`).
  static final ValueNotifier<ThemeMode> modo = ValueNotifier<ThemeMode>(
    _leerGuardado(),
  );

  /// Tema activo.
  static ThemeMode get actual => modo.value;

  /// Cambia entre modo claro y oscuro y lo persiste en el navegador.
  static void alternar() {
    modo.value = modo.value == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
    try {
      web.window.localStorage.setItem(
        claveTema,
        modo.value == ThemeMode.dark ? 'dark' : 'light',
      );
    } catch (_) {
      // Sin almacenamiento disponible: el modo se mantiene solo en memoria.
    }
  }
}

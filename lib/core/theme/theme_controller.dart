import 'package:flutter/material.dart';

/// Controlador global del modo claro/oscuro del panel.
///
/// Sin dependencias: un `ValueNotifier` simple que `MaterialApp` escucha
/// (en `main.dart`) para reconstruir el árbol con el tema elegido.
/// El botón del topbar alterna el modo con [alternar].
class ThemeController {
  ThemeController._();

  /// Modo actual de la aplicación (arranca en claro).
  static final ValueNotifier<ThemeMode> modo = ValueNotifier<ThemeMode>(
    ThemeMode.light,
  );

  /// Tema activo.
  static ThemeMode get actual => modo.value;

  /// Cambia entre modo claro y oscuro.
  static void alternar() {
    modo.value = modo.value == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
  }
}

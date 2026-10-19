import 'package:flutter/material.dart';

/// Paleta semántica del modo oscuro (basada en tonos estilo GitHub Dark)
/// y su contraparte clara (look actual de la app).
///
/// Mapas de color:
///   bgMain         -> fondo de pantalla        (dark #0E1117 / light #FDFDFF)
///   bgSurface      -> tarjetas/contenedores     (dark #161B22 / light #FFFFFF)
///   borderSubtle   -> bordes de inputs/divisores(dark #30363D / light #E0E0E0)
///   textPrimary    -> títulos y texto principal (dark #F0F6FC / light #101828)
///   textSecondary  -> subtítulos y descripciones(dark #8B949E / light #6B7280)
///   accentPrimary  -> botones/enlaces/activos   (dark #007BFF / light #1E88E5)
///   iconNormal     -> iconos en reposo          (dark #8B949E / light #9E9E9E)
///   iconActive     -> iconos seleccionados      (dark #007BFF / light #1E88E5)
///   inputBg        -> fondo de campos           (dark #0E1117 / light #FFFFFF)
class AppColors extends ThemeExtension<AppColors> {
  final Color bgMain;
  final Color bgSurface;
  final Color borderSubtle;
  final Color textPrimary;
  final Color textSecondary;
  final Color accentPrimary;
  final Color iconNormal;
  final Color iconActive;
  final Color inputBg;

  const AppColors({
    required this.bgMain,
    required this.bgSurface,
    required this.borderSubtle,
    required this.textPrimary,
    required this.textSecondary,
    required this.accentPrimary,
    required this.iconNormal,
    required this.iconActive,
    required this.inputBg,
  });

  /// Paleta de modo oscuro (#0E1117 base, sin negro puro, alta legibilidad).
  static const dark = AppColors(
    bgMain: Color(0xFF0E1117),
    bgSurface: Color(0xFF161B22),
    borderSubtle: Color(0xFF30363D),
    textPrimary: Color(0xFFF0F6FC),
    textSecondary: Color(0xFF8B949E),
    accentPrimary: Color(0xFF007BFF),
    iconNormal: Color(0xFF8B949E),
    iconActive: Color(0xFF007BFF),
    inputBg: Color(0xFF0E1117),
  );

  /// Paleta clara, equivalente al look actual de la app.
  static const light = AppColors(
    bgMain: Color(0xFFFDFDFF),
    bgSurface: Color(0xFFFFFFFF),
    borderSubtle: Color(0xFFE0E0E0),
    textPrimary: Color(0xFF101828),
    textSecondary: Color(0xFF6B7280),
    accentPrimary: Color(0xFF1E88E5),
    iconNormal: Color(0xFF9E9E9E),
    iconActive: Color(0xFF1E88E5),
    inputBg: Color(0xFFFFFFFF),
  );

  @override
  AppColors copyWith({
    Color? bgMain,
    Color? bgSurface,
    Color? borderSubtle,
    Color? textPrimary,
    Color? textSecondary,
    Color? accentPrimary,
    Color? iconNormal,
    Color? iconActive,
    Color? inputBg,
  }) {
    return AppColors(
      bgMain: bgMain ?? this.bgMain,
      bgSurface: bgSurface ?? this.bgSurface,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      accentPrimary: accentPrimary ?? this.accentPrimary,
      iconNormal: iconNormal ?? this.iconNormal,
      iconActive: iconActive ?? this.iconActive,
      inputBg: inputBg ?? this.inputBg,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      bgMain: Color.lerp(bgMain, other.bgMain, t)!,
      bgSurface: Color.lerp(bgSurface, other.bgSurface, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      accentPrimary: Color.lerp(accentPrimary, other.accentPrimary, t)!,
      iconNormal: Color.lerp(iconNormal, other.iconNormal, t)!,
      iconActive: Color.lerp(iconActive, other.iconActive, t)!,
      inputBg: Color.lerp(inputBg, other.inputBg, t)!,
    );
  }
}

/// Acceso cómodo: `context.colors.accentPrimary`, `context.colors.bgSurface`, etc.
extension AppThemeX on BuildContext {
  AppColors get colors =>
      Theme.of(this).extension<AppColors>() ?? AppColors.light;
}

/// Tema claro (look actual de la app).
ThemeData buildLightTheme() => _buildTheme(AppColors.light, Brightness.light);

/// Tema oscuro con la paleta GitHub Dark.
ThemeData buildDarkTheme() => _buildTheme(AppColors.dark, Brightness.dark);

ThemeData _buildTheme(AppColors c, Brightness brightness) {
  final colorScheme = ColorScheme(
    brightness: brightness,
    primary: c.accentPrimary,
    onPrimary: const Color(0xFFFFFFFF),
    secondary: c.accentPrimary,
    onSecondary: const Color(0xFFFFFFFF),
    error: const Color(0xFFE53935),
    onError: const Color(0xFFFFFFFF),
    surface: c.bgSurface,
    onSurface: c.textPrimary,
    onSurfaceVariant: c.textSecondary,
    outline: c.borderSubtle,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: c.bgMain,
    extensions: [c],
    // AppBar: fondo del tema, borde sutil y sin elevación.
    appBarTheme: AppBarTheme(
      backgroundColor: c.bgMain,
      foregroundColor: c.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      iconTheme: IconThemeData(color: c.iconNormal),
      titleTextStyle: TextStyle(
        color: c.textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    // Navegación inferior: reposo / seleccionado con los tokens de icono.
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: c.bgSurface,
      selectedItemColor: c.iconActive,
      unselectedItemColor: c.iconNormal,
    ),
    // Inputs: fondo inputBg, borde borderSubtle y focus accentPrimary.
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.inputBg,
      hintStyle: TextStyle(color: c.textSecondary, fontSize: 14),
      labelStyle: TextStyle(color: c.textSecondary),
      prefixIconColor: c.textSecondary,
      suffixIconColor: c.textSecondary,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: c.borderSubtle),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: c.borderSubtle),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: c.accentPrimary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE53935), width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE53935), width: 2),
      ),
    ),
    // Tarjetas y superficies elevadas.
    cardTheme: const CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
    ),
    dividerColor: c.borderSubtle,
    dialogTheme: DialogThemeData(backgroundColor: c.bgSurface),
    bottomSheetTheme: BottomSheetThemeData(backgroundColor: c.bgSurface),
  );
}
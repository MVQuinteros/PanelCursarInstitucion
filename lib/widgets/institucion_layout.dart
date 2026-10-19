import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/cursar_theme.dart';
import '../core/theme/cursar_palette.dart';
import '../core/theme/cursar_tone.dart';
import '../models/sesion_institucion.dart';
import '../services/auth_service.dart';

/// Layout común del panel institucional.
///
/// Espejo de `AppShell` de `adminCursarF`: sidebar + topbar + contenido.
/// En escritorio el sidebar es fijo; en móvil pasa a ser un drawer.
class InstitucionLayout extends StatefulWidget {
  final Widget child;
  final String location;

  const InstitucionLayout({
    super.key,
    required this.child,
    required this.location,
  });

  @override
  State<InstitucionLayout> createState() => _InstitucionLayoutState();
}

class _InstitucionLayoutState extends State<InstitucionLayout> {
  static const _wide = AppTokens.breakpointMobile;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  int _indexForLocation(String location) {
    switch (location) {
      case '/institucion':
        return 0;
      case '/institucion/ofertas':
      case '/institucion/ofertas/nueva':
      case _ when location.startsWith('/institucion/ofertas/'):
        return 1;
      case '/institucion/perfil':
        return 2;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final auth = AuthService.instance;
    final sesion = auth.sesion;
    final isWide = MediaQuery.sizeOf(context).width >= _wide;
    final location = widget.location;
    final currentIndex = _indexForLocation(location);

    String appBarTitle;
    switch (location) {
      case '/institucion':
        appBarTitle = 'Dashboard';
        break;
      case '/institucion/ofertas':
        appBarTitle = 'Ofertas académicas';
        break;
      case '/institucion/ofertas/nueva':
        appBarTitle = 'Nueva oferta';
        break;
      case '/institucion/perfil':
        appBarTitle = 'Mi perfil';
        break;
      case _ when location.startsWith('/institucion/ofertas/'):
        appBarTitle = 'Editar oferta';
        break;
      default:
        appBarTitle = 'Panel institucional';
    }

    final initials = _initials(sesion);

    final sidebar = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Brand del sidebar.
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: p.accent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'C',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'CURSAR',
                      style: TextStyle(
                        color: p.textPrimary,
                        fontSize: AppTokens.xl,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                      ),
                    ),
                    Text(
                      'Panel institucional',
                      style: TextStyle(
                        color: p.textMuted,
                        fontSize: AppTokens.xs,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isWide)
                IconButton(
                  onPressed: () => _scaffoldKey.currentState?.closeDrawer(),
                  icon: const Icon(Icons.close, size: 18),
                  color: p.textSecondary,
                  tooltip: 'Cerrar menú',
                ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 4, 10, 8),
                  child: Text(
                    'GESTIÓN',
                    style: TextStyle(
                      color: p.textMuted,
                      fontSize: AppTokens.xs,
                      letterSpacing: 0.8,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _NavItem(
                  label: 'Dashboard',
                  icon: Icons.dashboard,
                  active: currentIndex == 0,
                  onTap: () {
                    GoRouter.of(context).go('/institucion');
                    if (!isWide) _scaffoldKey.currentState?.closeDrawer();
                  },
                ),
                _NavItem(
                  label: 'Ofertas',
                  icon: Icons.work,
                  active: currentIndex == 1,
                  onTap: () {
                    GoRouter.of(context).go('/institucion/ofertas');
                    if (!isWide) _scaffoldKey.currentState?.closeDrawer();
                  },
                ),
                _NavItem(
                  label: 'Perfil',
                  icon: Icons.person,
                  active: currentIndex == 2,
                  onTap: () {
                    GoRouter.of(context).go('/institucion/perfil');
                    if (!isWide) _scaffoldKey.currentState?.closeDrawer();
                  },
                ),
              ],
            ),
          ),
        ),
        // Pie del sidebar con user-chip y logout.
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: p.accentSoft,
                    child: Text(
                      initials,
                      style: TextStyle(
                        color: p.accent,
                        fontSize: AppTokens.sm,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          sesion?.nombre ?? 'Institución',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: p.textPrimary,
                            fontSize: AppTokens.md,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Institución',
                          style: TextStyle(
                            color: p.textMuted,
                            fontSize: AppTokens.xs,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              CursarFilledButton(
                label: 'Cerrar sesión',
                icon: Icons.logout,
                tone: Tone.danger,
                small: true,
                block: true,
                onPressed: () async {
                  await auth.cerrarSesion();
                  if (mounted) GoRouter.of(context).go('/login');
                },
              ),
            ],
          ),
        ),
      ],
    );

    final drawer = Drawer(
      backgroundColor: p.bgSurface,
      child: SafeArea(child: sidebar),
    );

    final topbarHeight = AppTokens.topbarHeight;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: p.bgMain,
      drawer: isWide ? null : drawer,
      body: Row(
        children: [
          if (isWide)
            SizedBox(
              width: AppTokens.sidebarWidth,
              child: ColoredBox(
                color: p.bgSurface,
                child: SafeArea(right: false, child: sidebar),
              ),
            ),
          Expanded(
            child: Column(
              children: [
                // Topbar.
                Container(
                  height: topbarHeight,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: p.bgSurface,
                    border: Border(bottom: BorderSide(color: p.borderSubtle)),
                  ),
                  child: Row(
                    children: [
                      if (!isWide)
                        IconButton(
                          onPressed: () =>
                              _scaffoldKey.currentState?.openDrawer(),
                          icon: const Icon(Icons.menu, size: 20),
                          color: p.textSecondary,
                          tooltip: 'Abrir menú',
                        ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              appBarTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: p.textPrimary,
                                fontSize: AppTokens.xxl,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              '${_timeGreeting()}, ${sesion?.nombre ?? ''} 👋',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: p.textMuted,
                                fontSize: AppTokens.xs,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        onPressed: () async {
                          await auth.cerrarSesion();
                          if (mounted) GoRouter.of(context).go('/login');
                        },
                        icon: const Icon(Icons.logout, size: 19),
                        color: p.textSecondary,
                        tooltip: 'Cerrar sesión',
                      ),
                    ],
                  ),
                ),
                // Contenido.
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(
                      isWide
                          ? AppTokens.contentPadding
                          : AppTokens.contentPaddingMobile,
                    ),
                    child: widget.child,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: location == '/institucion/ofertas'
          ? FloatingActionButton(
              onPressed: () =>
                  GoRouter.of(context).go('/institucion/ofertas/nueva'),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  String _initials(SesionInstitucion? sesion) {
    if (sesion == null) return '?';
    final nombre = (sesion.nombre.isNotEmpty ? sesion.nombre[0] : '');
    final apellido = (sesion.apellido.isNotEmpty ? sesion.apellido[0] : '');
    if (nombre.isNotEmpty && apellido.isNotEmpty) {
      return '$nombre$apellido';
    }
    if (nombre.isNotEmpty) return nombre;
    if (apellido.isNotEmpty) return apellido;
    return (sesion.email.isNotEmpty ? sesion.email[0] : '?').toUpperCase();
  }

  String _timeGreeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Buenos días';
    if (h < 19) return 'Buenas tardes';
    return 'Buenas noches';
  }
}

/// Ítem de navegación del sidebar (espejo de `_NavItem` de adminCursarF).
class _NavItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final fg = active ? p.accent : p.textSecondary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: active ? p.accentSoft : Colors.transparent,
        borderRadius: BorderRadius.circular(AppTokens.radiusSm),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTokens.radiusSm),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              children: [
                Icon(icon, size: 17, color: fg),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: fg,
                      fontSize: AppTokens.md2,
                      fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Botón semántico con tono (espejo de `AppButton` de adminCursarF).
class CursarFilledButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Tone tone;
  final bool small;
  final bool block;
  final VoidCallback onPressed;

  const CursarFilledButton({
    super.key,
    required this.label,
    required this.icon,
    required this.tone,
    this.small = false,
    this.block = false,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    final (Color fg, Color bg) = switch (tone) {
      Tone.success => (Colors.white, p.success),
      Tone.warning => (Colors.white, p.warning),
      Tone.purple => (Colors.white, p.purple),
      Tone.info => (Colors.white, p.accent),
      Tone.neutral => (p.textPrimary, p.bgElevated),
      Tone.danger => (Colors.white, p.danger),
      _ => (Colors.white, p.accent),
    };

    final button = ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 17, color: fg),
      label: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: small ? AppTokens.sm : AppTokens.md2,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg,
        minimumSize: Size(block ? double.infinity : 0, small ? 36 : 44),
        padding: EdgeInsets.symmetric(
          horizontal: block ? 16 : (small ? 12 : 16),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusSm),
        ),
      ),
    );

    return block ? SizedBox(width: double.infinity, child: button) : button;
  }
}

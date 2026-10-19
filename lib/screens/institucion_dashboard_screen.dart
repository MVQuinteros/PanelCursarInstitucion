import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/cursar_palette.dart';
import '../core/theme/cursar_theme.dart';
import '../core/theme/cursar_tone.dart';
import '../core/widgets/info_banner.dart';
import '../models/oferta_model.dart';
import '../models/sesion_institucion.dart';
import '../services/auth_service.dart';
import '../services/ofertas_service.dart';

/// Dashboard del panel institucional.
///
/// Tarjetas de estadísticas clickeables (estilo `adminCursarF`): total de
/// ofertas, aprobadas, pendientes, inactivas, estado de la institución y
/// completitud del perfil.
class InstitucionDashboardScreen extends StatelessWidget {
  const InstitucionDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final sesion = AuthService.instance.sesion;
    final instUid = sesion?.institucionUid ?? '';

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (sesion != null && !sesion.aprobada)
            const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: InfoBanner(
                message:
                    'Tu institución está pendiente de aprobación. Podés cargar '
                    'tu información y ofertas mientras tanto.',
                tone: Tone.warning,
                icon: Icons.hourglass_top,
              ),
            ),
          _WelcomeCard(sesion: sesion),
          const SizedBox(height: 12),
          _StatsGrid(
            sesion: sesion,
            institucionUid: instUid,
            onTapOfertas: () => GoRouter.of(context).go('/institucion/ofertas'),
            onTapPerfil: () => GoRouter.of(context).go('/institucion/perfil'),
          ),
          const SizedBox(height: 20),
          Text(
            'Acciones rápidas',
            style: TextStyle(
              color: p.textPrimary,
              fontSize: AppTokens.lg,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _AccionCard(
                  titulo: 'Nueva oferta',
                  subtitulo: 'Crear una oferta académica',
                  icono: Icons.add_circle_outline,
                  color: p.accent,
                  onTap: () =>
                      GoRouter.of(context).go('/institucion/ofertas/nueva'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _AccionCard(
                  titulo: 'Ver ofertas',
                  subtitulo: 'Listado de ofertas cargadas',
                  icono: Icons.work_outline,
                  color: p.accent,
                  onTap: () => GoRouter.of(context).go('/institucion/ofertas'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: _AccionCard(
              titulo: 'Mi perfil',
              subtitulo: 'Editar datos y ubicación de la institución',
              icono: Icons.person_outline,
              color: p.textSecondary,
              onTap: () => GoRouter.of(context).go('/institucion/perfil'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta de bienvenida del dashboard.
class _WelcomeCard extends StatelessWidget {
  final SesionInstitucion? sesion;

  const _WelcomeCard({required this.sesion});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final logo = sesion?.institucionLogo;
    return Card(
      color: p.bgSurface,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bienvenido, ${sesion?.nombre ?? ''}',
                    style: TextStyle(
                      color: p.textPrimary,
                      fontSize: AppTokens.xxl,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    sesion?.institucionNombre ?? 'Institución',
                    style: TextStyle(
                      color: p.textSecondary,
                      fontSize: AppTokens.lg,
                    ),
                  ),
                ],
              ),
            ),
            if (logo != null && logo.isNotEmpty)
              CircleAvatar(backgroundImage: NetworkImage(logo), radius: 24),
          ],
        ),
      ),
    );
  }
}

/// Grid de tarjetas de estadísticas (responsive: 3 / 2 / 1 columnas).
class _StatsGrid extends StatelessWidget {
  final SesionInstitucion? sesion;
  final String institucionUid;
  final VoidCallback onTapOfertas;
  final VoidCallback onTapPerfil;

  const _StatsGrid({
    required this.sesion,
    required this.institucionUid,
    required this.onTapOfertas,
    required this.onTapPerfil,
  });

  @override
  Widget build(BuildContext context) {
    // Primero el documento de la institución (para el indicador de perfil).
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: institucionUid.isNotEmpty
          ? FirebaseFirestore.instance
                .collection('instituciones')
                .doc(institucionUid)
                .snapshots()
          : const Stream.empty(),
      builder: (context, instSnap) {
        final perfil = _Perfil.fromData(instSnap.data?.data());
        return StreamBuilder<List<OfertaModel>>(
          stream: institucionUid.isNotEmpty
              ? OfertasService.instance.ofertasDeInstitucion(institucionUid)
              : Stream.value(const <OfertaModel>[]),
          builder: (context, snapshot) {
            final ofertas = snapshot.data ?? const <OfertaModel>[];
            final aprobadas = ofertas.where((o) => o.estaAprobada).length;
            final pendientes = ofertas.length - aprobadas;
            final activas = ofertas.where((o) => o.estaActiva).length;
            final inactivas = ofertas.length - activas;

            final cards = <_StatSpec>[
              _StatSpec(
                label: 'Ofertas totales',
                value: '${ofertas.length}',
                tone: Tone.info,
                sub: 'Carreras cargadas',
                icon: Icons.list_alt,
                onTap: onTapOfertas,
              ),
              _StatSpec(
                label: 'Aprobadas',
                value: '$aprobadas',
                tone: Tone.success,
                sub: 'Publicadas en la app',
                icon: Icons.verified_outlined,
                onTap: onTapOfertas,
              ),
              _StatSpec(
                label: 'Pendientes',
                value: '$pendientes',
                tone: Tone.warning,
                sub: 'Esperando aprobación',
                icon: Icons.schedule,
                onTap: onTapOfertas,
              ),
              _StatSpec(
                label: 'Activas',
                value: '$activas',
                tone: Tone.purple,
                sub: 'Visibles en el portal',
                icon: Icons.visibility_outlined,
                onTap: onTapOfertas,
              ),
              _StatSpec(
                label: 'Inactivas',
                value: '$inactivas',
                tone: Tone.neutral,
                sub: 'Dadas de baja',
                icon: Icons.block,
                onTap: onTapOfertas,
              ),
              _StatSpec(
                label: 'Estado',
                value: '',
                tone: sesion?.aprobada == true ? Tone.success : Tone.warning,
                sub: (sesion?.estadoInstitucion ?? 'pendiente').toUpperCase(),
                icon: sesion?.aprobada == true
                    ? Icons.check_circle_outline
                    : Icons.hourglass_top,
                onTap: onTapPerfil,
              ),
              _StatSpec(
                label: 'Perfil',
                value: '${perfil.completados}/${_Perfil.total}',
                tone: perfil.completados == _Perfil.total
                    ? Tone.success
                    : Tone.secondary,
                sub: perfil.completados == _Perfil.total
                    ? 'Perfil completo'
                    : 'Completá tus datos',
                icon: Icons.person_outline,
                onTap: onTapPerfil,
              ),
            ];

            return LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 1080
                    ? 3
                    : constraints.maxWidth >= 680
                    ? 2
                    : 1;
                return GridView.count(
                  crossAxisCount: columns,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 2.35,
                  children: [for (final c in cards) _StatCardItem(spec: c)],
                );
              },
            );
          },
        );
      },
    );
  }
}

/// Indicador de completitud del perfil institucional.
///
/// Cuenta 4 datos clave que la app CURSAR usa para mostrar la institución:
/// logo, ubicación (coordenadas), contacto (teléfono o email) y descripción.
class _Perfil {
  static const int total = 4;

  final bool logo;
  final bool ubicacion;
  final bool contacto;
  final bool descripcion;

  const _Perfil({
    required this.logo,
    required this.ubicacion,
    required this.contacto,
    required this.descripcion,
  });

  int get completados =>
      [logo, ubicacion, contacto, descripcion].where((e) => e).length;

  factory _Perfil.fromData(Map<String, dynamic>? d) {
    if (d == null) {
      return const _Perfil(
        logo: false,
        ubicacion: false,
        contacto: false,
        descripcion: false,
      );
    }
    final logo = (d['logoURL'] ?? '').toString().trim().isNotEmpty;
    final tieneLatLng =
        (d['latitud'] as num?) != null && (d['longitud'] as num?) != null;
    final ubicacion = d['ubicacion'] != null || tieneLatLng;
    final contacto =
        (d['telefono'] ?? '').toString().trim().isNotEmpty ||
        (d['email'] ?? '').toString().trim().isNotEmpty;
    final descripcion = (d['descripcion'] ?? '').toString().trim().isNotEmpty;
    return _Perfil(
      logo: logo,
      ubicacion: ubicacion,
      contacto: contacto,
      descripcion: descripcion,
    );
  }
}

class _StatSpec {
  final String label;
  final String value;
  final Tone tone;
  final String sub;
  final IconData icon;
  final VoidCallback? onTap;

  const _StatSpec({
    required this.label,
    required this.value,
    required this.tone,
    required this.sub,
    required this.icon,
    this.onTap,
  });
}

class _StatCardItem extends StatelessWidget {
  final _StatSpec spec;

  const _StatCardItem({required this.spec});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final fg = spec.tone.fg(p);
    final bg = spec.tone.bg(p);

    return Card(
      color: bg,
      child: InkWell(
        onTap: spec.onTap,
        borderRadius: BorderRadius.circular(AppTokens.radius),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Stack(
            children: [
              if (spec.onTap != null)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Text(
                    '→',
                    style: TextStyle(
                      color: fg,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: fg.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(spec.icon, color: fg, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          spec.label,
                          style: TextStyle(
                            color: p.textSecondary,
                            fontSize: AppTokens.sm,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (spec.value.isNotEmpty)
                    Text(
                      spec.value,
                      style: TextStyle(
                        color: fg,
                        fontSize: AppTokens.statValue,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                  if (spec.value.isNotEmpty) const SizedBox(height: 2),
                  Text(
                    spec.sub,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: p.textMuted,
                      fontSize: AppTokens.xs,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tarjeta de acción rápida.
class _AccionCard extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final IconData icono;
  final Color color;
  final VoidCallback onTap;

  const _AccionCard({
    required this.titulo,
    required this.subtitulo,
    required this.icono,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Card(
      color: p.bgSurface,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icono, color: color, size: 24),
        ),
        title: Text(
          titulo,
          style: TextStyle(color: p.textPrimary, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitulo, style: TextStyle(color: p.textSecondary)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

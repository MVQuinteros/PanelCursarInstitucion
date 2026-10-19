import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/cursar_palette.dart';
import '../core/theme/cursar_theme.dart';
import '../core/theme/cursar_tone.dart';
import '../models/oferta_model.dart';
import '../models/sesion_institucion.dart';
import '../services/auth_service.dart';
import '../services/ofertas_service.dart';

/// Dashboard del panel institucional.
///
/// Gráficas (fl_chart) al abrir: estado de moderación (barras) y ofertas
/// por área (dona), tarjetas de estadísticas clickeables (estilo
/// `adminCursarF`) y completitud del perfil.
class InstitucionDashboardScreen extends StatelessWidget {
  const InstitucionDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sesion = AuthService.instance.sesion;
    final instUid = sesion?.institucionUid ?? '';

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _WelcomeCard(sesion: sesion),
          const SizedBox(height: 12),
          _GraficasSection(institucionUid: instUid),
          const SizedBox(height: 12),
          _StatsGrid(
            institucionUid: instUid,
            onTapOfertas: () => GoRouter.of(context).go('/institucion/ofertas'),
            onTapPerfil: () => GoRouter.of(context).go('/institucion/perfil'),
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
  final String institucionUid;
  final VoidCallback onTapOfertas;
  final VoidCallback onTapPerfil;

  const _StatsGrid({
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

/// Paleta de los gráficos (misma que `CHART_COLORS` del panel admin).
const _chartColors = <Color>[
  Color(0xFF007BFF),
  Color(0xFF2EA043),
  Color(0xFFD29922),
  Color(0xFF9C27B0),
  Color(0xFFE53935),
  Color(0xFF1E88E5),
  Color(0xFF00A0B0),
  Color(0xFF8B949E),
];

/// Gráficas del dashboard (estilo `adminCursarF`): barras de moderación +
/// dona de ofertas por área. 2 columnas en desktop, apiladas en móvil.
class _GraficasSection extends StatelessWidget {
  final String institucionUid;

  const _GraficasSection({required this.institucionUid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<OfertaModel>>(
      stream: institucionUid.isNotEmpty
          ? OfertasService.instance.ofertasDeInstitucion(institucionUid)
          : Stream.value(const <OfertaModel>[]),
      builder: (context, snapshot) {
        final cargando = snapshot.connectionState == ConnectionState.waiting;
        final ofertas = snapshot.data ?? const <OfertaModel>[];
        final aprobadas = ofertas.where((o) => o.estaAprobada).length;
        final pendientes = ofertas.where((o) => !o.estaAprobada).length;

        const spinner = Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );

        return LayoutBuilder(
          builder: (context, constraints) {
            final tarjetas = [
              _GraficaCard(
                titulo: 'Estado de moderación',
                subtitulo: 'Ofertas aprobadas y pendientes de revisión',
                child: cargando
                    ? spinner
                    : _BarrasModeracion(
                        aprobadas: aprobadas,
                        pendientes: pendientes,
                      ),
              ),
              _GraficaCard(
                titulo: 'Ofertas por área',
                subtitulo: 'Distribución de tus ${ofertas.length} oferta(s)',
                child: cargando ? spinner : _DonaPorArea(ofertas: ofertas),
              ),
            ];

            if (constraints.maxWidth >= 860) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: tarjetas[0]),
                  const SizedBox(width: 12),
                  Expanded(child: tarjetas[1]),
                ],
              );
            }
            return Column(
              children: [tarjetas[0], const SizedBox(height: 12), tarjetas[1]],
            );
          },
        );
      },
    );
  }
}

/// Contenedor de una gráfica: título + subtítulo + área de chart (alto fijo).
class _GraficaCard extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final Widget child;

  const _GraficaCard({
    required this.titulo,
    required this.subtitulo,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Card(
      color: p.bgSurface,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titulo,
              style: TextStyle(
                color: p.textPrimary,
                fontSize: AppTokens.lg,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitulo,
              style: TextStyle(color: p.textSecondary, fontSize: AppTokens.sm),
            ),
            const SizedBox(height: 10),
            SizedBox(height: 180, child: child),
          ],
        ),
      ),
    );
  }
}

/// Barras: ofertas aprobadas vs pendientes de moderación.
class _BarrasModeracion extends StatelessWidget {
  final int aprobadas;
  final int pendientes;

  const _BarrasModeracion({required this.aprobadas, required this.pendientes});

  static const _verde = Color(0xFF2EA043);
  static const _ambar = Color(0xFFD29922);

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    if (aprobadas == 0 && pendientes == 0) {
      return Center(
        child: Text(
          'Sin ofertas todavía',
          style: TextStyle(color: p.textMuted, fontSize: AppTokens.sm),
        ),
      );
    }

    final maximo = aprobadas > pendientes ? aprobadas : pendientes;
    return Column(
      children: [
        Expanded(
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maximo * 1.3,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => p.bgSurface,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                      BarTooltipItem(
                        '${rod.toY.toInt()} oferta(s)',
                        TextStyle(
                          color: p.textPrimary,
                          fontSize: AppTokens.xs,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) =>
                    FlLine(color: p.borderSubtle, strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 34,
                    getTitlesWidget: (value, meta) {
                      const labels = ['Aprobadas', 'Pendientes'];
                      final i = value.toInt();
                      if (i < 0 || i >= labels.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          labels[i],
                          style: TextStyle(
                            color: p.textSecondary,
                            fontSize: AppTokens.xs,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              barGroups: [
                BarChartGroupData(
                  x: 0,
                  barRods: [
                    BarChartRodData(
                      toY: aprobadas.toDouble(),
                      color: _verde,
                      width: 32,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
                BarChartGroupData(
                  x: 1,
                  barRods: [
                    BarChartRodData(
                      toY: pendientes.toDouble(),
                      color: _ambar,
                      width: 32,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _LeyendaItem(color: _verde, label: 'Aprobadas', valor: aprobadas),
            const SizedBox(width: 16),
            _LeyendaItem(color: _ambar, label: 'Pendientes', valor: pendientes),
          ],
        ),
      ],
    );
  }
}

/// Dona: distribución de las ofertas por área, con leyenda y resaltado
/// al pasar el mouse sobre una sección.
class _DonaPorArea extends StatefulWidget {
  final List<OfertaModel> ofertas;

  const _DonaPorArea({required this.ofertas});

  @override
  State<_DonaPorArea> createState() => _DonaPorAreaState();
}

class _DonaPorAreaState extends State<_DonaPorArea> {
  int? _tocado;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    // Agrupa por área (las vacías van como "Sin área").
    final conteos = <String, int>{};
    for (final o in widget.ofertas) {
      final clave = o.area.trim().isEmpty ? 'Sin área' : o.area.trim();
      conteos[clave] = (conteos[clave] ?? 0) + 1;
    }
    final entradas = conteos.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (entradas.isEmpty) {
      return Center(
        child: Text(
          'Sin ofertas todavía',
          style: TextStyle(color: p.textMuted, fontSize: AppTokens.sm),
        ),
      );
    }

    final total = widget.ofertas.length;
    final tocado = (_tocado != null && _tocado! < entradas.length)
        ? _tocado
        : null;

    return Row(
      children: [
        Expanded(
          flex: 45,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final lado = constraints.biggest.shortestSide;
              final radio = (lado / 2 - 6).clamp(24.0, 96.0).toDouble();
              final centro = radio * 0.55;
              return Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox.expand(
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: centro,
                        borderData: FlBorderData(show: false),
                        pieTouchData: PieTouchData(
                          touchCallback: (event, response) {
                            setState(() {
                              _tocado =
                                  response?.touchedSection?.touchedSectionIndex;
                            });
                          },
                        ),
                        sections: [
                          for (var i = 0; i < entradas.length; i++)
                            PieChartSectionData(
                              value: entradas[i].value.toDouble(),
                              color: _chartColors[i % _chartColors.length],
                              radius: tocado == i ? radio + 6 : radio,
                              showTitle: false,
                              borderSide: BorderSide(
                                color: p.bgSurface,
                                width: 1,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$total',
                        style: TextStyle(
                          color: p.textPrimary,
                          fontSize: AppTokens.xl,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'ofertas',
                        style: TextStyle(
                          color: p.textMuted,
                          fontSize: AppTokens.xs,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 55,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < entradas.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: _LeyendaArea(
                      color: _chartColors[i % _chartColors.length],
                      label: entradas[i].key,
                      valor: entradas[i].value,
                      total: total,
                      destacado: tocado == i,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Item de la leyenda de la dona: color, área, valor y porcentaje.
class _LeyendaArea extends StatelessWidget {
  final Color color;
  final String label;
  final int valor;
  final int total;
  final bool destacado;

  const _LeyendaArea({
    required this.color,
    required this.label,
    required this.valor,
    required this.total,
    required this.destacado,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final pct = total > 0 ? ((valor / total) * 100).round() : 0;
    return Row(
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: destacado ? p.textPrimary : p.textSecondary,
              fontSize: AppTokens.xs,
              fontWeight: destacado ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$valor · $pct%',
          style: TextStyle(color: p.textMuted, fontSize: AppTokens.xs),
        ),
      ],
    );
  }
}

/// Item de la leyenda de las barras: color, nombre y conteo.
class _LeyendaItem extends StatelessWidget {
  final Color color;
  final String label;
  final int valor;

  const _LeyendaItem({
    required this.color,
    required this.label,
    required this.valor,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$label ($valor)',
          style: TextStyle(color: p.textSecondary, fontSize: AppTokens.xs),
        ),
      ],
    );
  }
}

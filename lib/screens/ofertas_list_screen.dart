import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/cursar_palette.dart';
import '../core/theme/cursar_theme.dart';
import '../core/theme/cursar_tone.dart';
import '../core/widgets/empty_state.dart';
import '../core/widgets/info_banner.dart';
import '../core/widgets/loading_card.dart';
import '../core/widgets/status_badge.dart';
import '../models/oferta_model.dart';
import '../services/auth_service.dart';
import '../services/ofertas_service.dart';

/// Filtro de moderación del listado.
enum _FiltroOfertas { todas, aprobadas, pendientes }

/// Listado de ofertas académicas de la institución logueada.
///
/// Permite crear una nueva oferta, editar una existente, dar de baja
/// (baja lógica) o reenviar a revisión una oferta pendiente.
class OfertasListScreen extends StatefulWidget {
  const OfertasListScreen({super.key});

  @override
  State<OfertasListScreen> createState() => _OfertasListScreenState();
}

class _OfertasListScreenState extends State<OfertasListScreen> {
  late final String _institucionUid;
  bool _cargando = false;
  _FiltroOfertas _filtro = _FiltroOfertas.todas;

  @override
  void initState() {
    super.initState();
    final sesion = AuthService.instance.sesion;
    _institucionUid = sesion?.institucionUid ?? '';
  }

  Future<void> _cambiarEstado(String ofertaId, bool activar) async {
    setState(() => _cargando = true);
    try {
      if (activar) {
        await OfertasService.instance.activarOferta(ofertaId);
      } else {
        await OfertasService.instance.desactivarOferta(ofertaId);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo cambiar el estado de la oferta.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _reenviarARevision(String ofertaId) async {
    setState(() => _cargando = true);
    try {
      await OfertasService.instance.reenviarARevision(ofertaId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Oferta reenviada a revisión.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo reenviar la oferta.')),
        );
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  List<OfertaModel> _aplicarFiltro(List<OfertaModel> ofertas) {
    switch (_filtro) {
      case _FiltroOfertas.aprobadas:
        return ofertas.where((o) => o.estaAprobada).toList();
      case _FiltroOfertas.pendientes:
        return ofertas.where((o) => !o.estaAprobada).toList();
      case _FiltroOfertas.todas:
        return ofertas;
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final sesion = AuthService.instance.sesion;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Barra de información de la institución.
        Container(
          color: p.bgSurface,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.school, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${sesion?.institucionNombre ?? 'Institución'} '
                  '(${sesion?.estadoInstitucion ?? 'pendiente'})',
                  style: TextStyle(
                    color: p.textPrimary,
                    fontSize: AppTokens.md,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              StatusBadge(
                sesion?.aprobada == true ? 'Activada' : 'Pendiente',
                tone: sesion?.aprobada == true ? Tone.success : Tone.warning,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Filtros por estado de moderación.
        StreamBuilder<List<OfertaModel>>(
          stream: _institucionUid.isNotEmpty
              ? OfertasService.instance.ofertasDeInstitucion(_institucionUid)
              : Stream.value(const <OfertaModel>[]),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Expanded(child: LoadingCard());
            }

            final todas = snapshot.data ?? const <OfertaModel>[];
            final pendientes = todas.where((o) => !o.estaAprobada).length;
            final aprobadas = todas.where((o) => o.estaAprobada).length;
            final ofertas = _aplicarFiltro(todas);

            return Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (pendientes > 0)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: InfoBanner(
                        message:
                            'Tenés $pendientes oferta(s) pendiente(s) de '
                            'aprobación por el administrador.',
                        tone: Tone.warning,
                        icon: Icons.schedule,
                      ),
                    ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FiltroChip(
                          label: 'Todas (${todas.length})',
                          selected: _filtro == _FiltroOfertas.todas,
                          onSelected: () =>
                              setState(() => _filtro = _FiltroOfertas.todas),
                        ),
                        const SizedBox(width: 8),
                        _FiltroChip(
                          label: 'Aprobadas ($aprobadas)',
                          selected: _filtro == _FiltroOfertas.aprobadas,
                          onSelected: () => setState(
                            () => _filtro = _FiltroOfertas.aprobadas,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _FiltroChip(
                          label: 'Pendientes ($pendientes)',
                          selected: _filtro == _FiltroOfertas.pendientes,
                          onSelected: () => setState(
                            () => _filtro = _FiltroOfertas.pendientes,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ofertas.isEmpty
                        ? EmptyState(
                            icon: Icons.campaign_outlined,
                            title: todas.isEmpty
                                ? 'Sin ofertas cargadas'
                                : 'Sin ofertas en este filtro',
                            subtitle: todas.isEmpty
                                ? 'Presioná "+" para crear tu primera oferta académica.'
                                : 'Probá con otro filtro.',
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            itemCount: ofertas.length,
                            itemBuilder: (context, index) => _OfertaCard(
                              oferta: ofertas[index],
                              cargando: _cargando,
                              onEditar: () => context.go(
                                '/institucion/ofertas/${ofertas[index].ofertaId}/editar',
                              ),
                              onCambiarEstado: () => _cambiarEstado(
                                ofertas[index].ofertaId,
                                !ofertas[index].estaActiva,
                              ),
                              onReenviar: () =>
                                  _reenviarARevision(ofertas[index].ofertaId),
                            ),
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Chip de filtro del listado.
class _FiltroChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _FiltroChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      labelStyle: TextStyle(
        color: selected ? p.accent : p.textSecondary,
        fontSize: AppTokens.sm,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
      ),
      selectedColor: p.accentSoft,
      backgroundColor: p.bgSurface,
      side: BorderSide(color: selected ? p.accent : p.borderSubtle),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusSm),
      ),
      visualDensity: VisualDensity.compact,
    );
  }
}

/// Tarjeta de una oferta con badges y acciones.
class _OfertaCard extends StatelessWidget {
  final OfertaModel oferta;
  final bool cargando;
  final VoidCallback onEditar;
  final VoidCallback onCambiarEstado;
  final VoidCallback onReenviar;

  const _OfertaCard({
    required this.oferta,
    required this.cargando,
    required this.onEditar,
    required this.onCambiarEstado,
    required this.onReenviar,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Card(
      color: p.bgSurface,
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onEditar,
        borderRadius: BorderRadius.circular(AppTokens.radius),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      oferta.nombre,
                      style: TextStyle(
                        color: p.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: AppTokens.lg,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusBadge(
                    oferta.estaAprobada ? 'Aprobada' : 'Pendiente',
                    tone: oferta.estaAprobada ? Tone.success : Tone.warning,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${oferta.area} • ${oferta.nivel} • ${oferta.modalidad}',
                style: TextStyle(
                  color: p.textSecondary,
                  fontSize: AppTokens.sm,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                oferta.descripcion,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: p.textSecondary,
                  fontSize: AppTokens.xs,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  StatusBadge(
                    oferta.estaActiva ? 'Activa' : 'Inactiva',
                    tone: oferta.estaActiva ? Tone.info : Tone.neutral,
                  ),
                  const Spacer(),
                  if (!oferta.estaAprobada)
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 20),
                      color: p.warning,
                      tooltip: 'Reenviar a revisión',
                      onPressed: cargando ? null : onReenviar,
                    ),
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    color: p.accent,
                    tooltip: 'Editar',
                    onPressed: onEditar,
                  ),
                  IconButton(
                    icon: Icon(
                      oferta.estaActiva ? Icons.block : Icons.check_circle,
                      size: 20,
                    ),
                    color: oferta.estaActiva ? p.danger : p.success,
                    tooltip: oferta.estaActiva ? 'Dar de baja' : 'Activar',
                    onPressed: cargando ? null : onCambiarEstado,
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

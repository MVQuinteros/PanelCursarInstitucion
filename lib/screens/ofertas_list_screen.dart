import 'package:flutter/material.dart';

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
import '../widgets/oferta_form_dialog.dart';

enum _FiltroOfertas { todas, aprobadas, pendientes, activas, inactivas }

class OfertasListScreen extends StatefulWidget {
  const OfertasListScreen({super.key});

  @override
  State<OfertasListScreen> createState() => _OfertasListScreenState();
}

class _OfertasListScreenState extends State<OfertasListScreen> {
  late final String _institucionUid;
  bool _cargando = false;
  _FiltroOfertas _filtro = _FiltroOfertas.todas;
  String _busqueda = '';

  final _busquedaCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final sesion = AuthService.instance.sesion;
    _institucionUid = sesion?.institucionUid ?? '';
    _busquedaCtrl.addListener(() {
      setState(() => _busqueda = _busquedaCtrl.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _busquedaCtrl.dispose();
    super.dispose();
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

  Future<void> _abrirFormulario({OfertaModel? existente, String? id}) async {
    final res = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          OfertaFormDialog(ofertaId: id, ofertaExistente: existente),
    );
    if (res == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Oferta guardada correctamente.')),
      );
    }
  }

  List<OfertaModel> _aplicarFiltro(List<OfertaModel> ofertas) {
    var filtradas = switch (_filtro) {
      _FiltroOfertas.aprobadas => ofertas.where((o) => o.estaAprobada).toList(),
      _FiltroOfertas.pendientes =>
        ofertas.where((o) => !o.estaAprobada).toList(),
      _FiltroOfertas.activas => ofertas.where((o) => o.estaActiva).toList(),
      _FiltroOfertas.inactivas => ofertas.where((o) => !o.estaActiva).toList(),
      _FiltroOfertas.todas => ofertas,
    };
    if (_busqueda.isNotEmpty) {
      filtradas = filtradas
          .where((o) => o.nombre.toLowerCase().contains(_busqueda))
          .toList();
    }
    return filtradas;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final sesion = AuthService.instance.sesion;
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 900;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          color: p.bgSurface,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.school, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  sesion?.institucionNombre ?? 'Institución',
                  style: TextStyle(
                    color: p.textPrimary,
                    fontSize: AppTokens.md,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
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
            final activas = todas.where((o) => o.estaActiva).length;
            final inactivas = todas.where((o) => !o.estaActiva).length;
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
                            'Tenés $pendientes oferta(s) pendiente(s) de aprobación por el administrador.',
                        tone: Tone.warning,
                        icon: Icons.schedule,
                      ),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _busquedaCtrl,
                          style: TextStyle(
                            color: p.textPrimary,
                            fontSize: AppTokens.md,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Buscar por nombre',
                            prefixIcon: const Icon(Icons.search),
                            filled: true,
                            fillColor: p.bgSurface,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 10,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                AppTokens.radiusSm,
                              ),
                              borderSide: BorderSide(color: p.borderSubtle),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                AppTokens.radiusSm,
                              ),
                              borderSide: BorderSide(color: p.borderSubtle),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                AppTokens.radiusSm,
                              ),
                              borderSide: BorderSide(color: p.accent),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: () => _abrirFormulario(),
                        icon: const Icon(Icons.add),
                        label: const Text('Nueva oferta'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
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
                          label: 'Pendientes ($pendientes)',
                          selected: _filtro == _FiltroOfertas.pendientes,
                          onSelected: () => setState(
                            () => _filtro = _FiltroOfertas.pendientes,
                          ),
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
                          label: 'Activas ($activas)',
                          selected: _filtro == _FiltroOfertas.activas,
                          onSelected: () =>
                              setState(() => _filtro = _FiltroOfertas.activas),
                        ),
                        const SizedBox(width: 8),
                        _FiltroChip(
                          label: 'Inactivas ($inactivas)',
                          selected: _filtro == _FiltroOfertas.inactivas,
                          onSelected: () => setState(
                            () => _filtro = _FiltroOfertas.inactivas,
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
                                ? 'Creá tu primera oferta académica.'
                                : 'Probá con otro filtro o buscador.',
                          )
                        : isWide
                        ? SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SingleChildScrollView(
                              child: _OfertasTable(
                                ofertas: ofertas,
                                cargando: _cargando,
                                onEditar: (o) => _abrirFormulario(
                                  existente: o,
                                  id: o.ofertaId,
                                ),
                                onCambiarEstado: (o) =>
                                    _cambiarEstado(o.ofertaId, !o.estaActiva),
                                onReenviar: (o) =>
                                    _reenviarARevision(o.ofertaId),
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            itemCount: ofertas.length,
                            itemBuilder: (context, index) {
                              final o = ofertas[index];
                              return _OfertaCard(
                                oferta: o,
                                cargando: _cargando,
                                onEditar: () => _abrirFormulario(
                                  existente: o,
                                  id: o.ofertaId,
                                ),
                                onCambiarEstado: () =>
                                    _cambiarEstado(o.ofertaId, !o.estaActiva),
                                onReenviar: () =>
                                    _reenviarARevision(o.ofertaId),
                              );
                            },
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

class _OfertasTable extends StatelessWidget {
  final List<OfertaModel> ofertas;
  final bool cargando;
  final ValueChanged<OfertaModel> onEditar;
  final ValueChanged<OfertaModel> onCambiarEstado;
  final ValueChanged<OfertaModel> onReenviar;

  const _OfertasTable({
    required this.ofertas,
    required this.cargando,
    required this.onEditar,
    required this.onCambiarEstado,
    required this.onReenviar,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final headerStyle = TextStyle(
      color: p.textSecondary,
      fontSize: AppTokens.sm,
      fontWeight: FontWeight.w600,
    );
    final cellStyle = TextStyle(color: p.textPrimary, fontSize: AppTokens.md);

    return DataTable(
      headingRowColor: WidgetStatePropertyAll(p.bgSurface),
      dataRowMinHeight: 42,
      dataRowMaxHeight: 52,
      columns: [
        DataColumn(label: Text('Oferta', style: headerStyle)),
        DataColumn(label: Text('Área/Nivel/Modalidad', style: headerStyle)),
        DataColumn(label: Text('Duración', style: headerStyle)),
        DataColumn(label: Text('Tag', style: headerStyle)),
        DataColumn(label: Text('Estado', style: headerStyle)),
        DataColumn(label: Text('Moderación', style: headerStyle)),
        DataColumn(label: Text('Acciones', style: headerStyle)),
      ],
      rows: ofertas.map((o) {
        return DataRow(
          cells: [
            DataCell(
              Text(o.nombre, style: cellStyle, overflow: TextOverflow.ellipsis),
            ),
            DataCell(
              Text(
                '${o.area} • ${o.nivel} • ${o.modalidad}',
                style: cellStyle,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            DataCell(
              Text(
                o.duracionAnios == 0 ? '' : '${o.duracionAnios} año(s)',
                style: cellStyle,
              ),
            ),
            DataCell(Text(o.tag, style: cellStyle)),
            DataCell(
              StatusBadge(
                o.estaActiva ? 'Activa' : 'Inactiva',
                tone: o.estaActiva ? Tone.info : Tone.neutral,
              ),
            ),
            DataCell(
              StatusBadge(
                o.estaAprobada ? 'Aprobada' : 'Pendiente',
                tone: o.estaAprobada ? Tone.success : Tone.warning,
              ),
            ),
            DataCell(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Tooltip(
                    message: 'Editar',
                    child: IconButton(
                      icon: const Icon(Icons.edit, size: 18),
                      color: p.accent,
                      onPressed: cargando ? null : () => onEditar(o),
                    ),
                  ),
                  Tooltip(
                    message: o.estaActiva ? 'Dar de baja' : 'Activar',
                    child: IconButton(
                      icon: Icon(
                        o.estaActiva ? Icons.block : Icons.check_circle,
                        size: 18,
                      ),
                      color: o.estaActiva ? p.danger : p.success,
                      onPressed: cargando ? null : () => onCambiarEstado(o),
                    ),
                  ),
                  if (!o.estaAprobada)
                    Tooltip(
                      message: 'Reenviar a revisión',
                      child: IconButton(
                        icon: const Icon(Icons.refresh, size: 18),
                        color: p.warning,
                        onPressed: cargando ? null : () => onReenviar(o),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

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
              if (oferta.tag.isNotEmpty)
                Text(
                  'Tag: ${oferta.tag}',
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

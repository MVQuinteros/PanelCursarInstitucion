import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/theme/cursar_palette.dart';
import '../core/theme/cursar_theme.dart';
import '../core/theme/cursar_tone.dart';
import '../core/widgets/empty_state.dart';
import '../core/widgets/loading_card.dart';
import '../core/widgets/status_badge.dart';
import '../models/aviso_model.dart';
import '../services/avisos_service.dart';
import '../services/auth_service.dart';
import '../widgets/aviso_form_dialog.dart';

/// Listado de avisos institucionales con historial.
///
/// Mismo funcionamiento que la pantalla de Ofertas: buscador, filtros por
/// tipo, tabla en escritorio y tarjetas en móvil. Los avisos publicados
/// quedan como historial (los más nuevos primero) hasta que la institución
/// los edita o los elimina.
class AvisosListScreen extends StatefulWidget {
  const AvisosListScreen({super.key});

  @override
  State<AvisosListScreen> createState() => _AvisosListScreenState();
}

class _AvisosListScreenState extends State<AvisosListScreen> {
  late final String _institucionUid;
  bool _cargando = false;
  String _filtroTipo = ''; // '' = todas
  String _busqueda = '';

  final _busquedaCtrl = TextEditingController();

  static const _etiquetasTipo = <String, String>{
    'noticia': 'Noticia',
    'inscripcion': 'Inscripción',
    'consejo': 'Consejo',
    'evento': 'Evento',
    'otro': 'Otro',
  };

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

  String _etiquetaTipo(String tipo) => _etiquetasTipo[tipo] ?? tipo;

  Tone _toneTipo(String tipo) {
    return switch (tipo) {
      'inscripcion' => Tone.success,
      'consejo' => Tone.purple,
      'evento' => Tone.warning,
      'noticia' => Tone.info,
      _ => Tone.neutral,
    };
  }

  Future<void> _abrirFormulario({AvisoModel? existente, String? id}) async {
    final res = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AvisoFormDialog(avisoId: id, avisoExistente: existente),
    );
    if (res == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aviso guardado correctamente.')),
      );
    }
  }

  Future<void> _eliminar(AvisoModel aviso) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final p = ctx.palette;
        return AlertDialog(
          backgroundColor: p.bgSurface,
          title: Text('Eliminar aviso', style: TextStyle(color: p.textPrimary)),
          content: Text(
            'Se eliminará "${aviso.titulo}" del historial. '
            'Esta acción no se puede deshacer.',
            style: TextStyle(color: p.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text('Cancelar', style: TextStyle(color: p.textSecondary)),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: p.danger),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
    if (confirmar != true || !mounted) return;

    setState(() => _cargando = true);
    try {
      await AvisosService.instance.eliminarAviso(aviso.avisoId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aviso eliminado del historial.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo eliminar el aviso.')),
        );
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  List<AvisoModel> _aplicarFiltro(List<AvisoModel> avisos) {
    var filtradas = _filtroTipo.isEmpty
        ? avisos
        : avisos.where((a) => a.tipo == _filtroTipo).toList();
    if (_busqueda.isNotEmpty) {
      filtradas = filtradas
          .where(
            (a) =>
                a.titulo.toLowerCase().contains(_busqueda) ||
                a.mensaje.toLowerCase().contains(_busqueda),
          )
          .toList();
    }
    return filtradas;
  }

  String _fecha(AvisoModel a) {
    final fecha = a.createdAt;
    return fecha == null ? '—' : DateFormat('dd/MM/yyyy').format(fecha);
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
              const Icon(Icons.campaign, size: 20),
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
        StreamBuilder<List<AvisoModel>>(
          stream: _institucionUid.isNotEmpty
              ? AvisosService.instance.avisosDeInstitucion(_institucionUid)
              : Stream.value(const <AvisoModel>[]),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Expanded(child: LoadingCard());
            }
            final todas = snapshot.data ?? const <AvisoModel>[];
            final avisos = _aplicarFiltro(todas);

            // Tipos presentes en el historial, para armar los filtros.
            final tipos = <String>{};
            for (final a in todas) {
              tipos.add(a.tipo);
            }
            final tiposOrdenados = tipos.toList()..sort();

            return Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                            hintText: 'Buscar por título o mensaje',
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
                        label: const Text('Nuevo aviso'),
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
                          selected: _filtroTipo.isEmpty,
                          onSelected: () => setState(() => _filtroTipo = ''),
                        ),
                        for (final tipo in tiposOrdenados) ...[
                          const SizedBox(width: 8),
                          _FiltroChip(
                            label:
                                '${_etiquetaTipo(tipo)} '
                                '(${todas.where((a) => a.tipo == tipo).length})',
                            selected: _filtroTipo == tipo,
                            onSelected: () =>
                                setState(() => _filtroTipo = tipo),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: avisos.isEmpty
                        ? EmptyState(
                            icon: Icons.campaign_outlined,
                            title: todas.isEmpty
                                ? 'Sin avisos publicados'
                                : 'Sin avisos en este filtro',
                            subtitle: todas.isEmpty
                                ? 'Creá tu primer aviso para la comunidad.'
                                : 'Probá con otro filtro o buscador.',
                          )
                        : isWide
                        ? SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SingleChildScrollView(
                              child: _AvisosTable(
                                avisos: avisos,
                                cargando: _cargando,
                                fecha: _fecha,
                                etiquetaTipo: _etiquetaTipo,
                                toneTipo: _toneTipo,
                                onEditar: (a) => _abrirFormulario(
                                  existente: a,
                                  id: a.avisoId,
                                ),
                                onEliminar: _eliminar,
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            itemCount: avisos.length,
                            itemBuilder: (context, index) {
                              final a = avisos[index];
                              return _AvisoCard(
                                aviso: a,
                                cargando: _cargando,
                                fecha: _fecha(a),
                                etiquetaTipo: _etiquetaTipo(a.tipo),
                                toneTipo: _toneTipo(a.tipo),
                                onEditar: () => _abrirFormulario(
                                  existente: a,
                                  id: a.avisoId,
                                ),
                                onEliminar: () => _eliminar(a),
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

class _AvisosTable extends StatelessWidget {
  final List<AvisoModel> avisos;
  final bool cargando;
  final String Function(AvisoModel) fecha;
  final String Function(String) etiquetaTipo;
  final Tone Function(String) toneTipo;
  final ValueChanged<AvisoModel> onEditar;
  final ValueChanged<AvisoModel> onEliminar;

  const _AvisosTable({
    required this.avisos,
    required this.cargando,
    required this.fecha,
    required this.etiquetaTipo,
    required this.toneTipo,
    required this.onEditar,
    required this.onEliminar,
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
        DataColumn(label: Text('Título', style: headerStyle)),
        DataColumn(label: Text('Mensaje', style: headerStyle)),
        DataColumn(label: Text('Tipo', style: headerStyle)),
        DataColumn(label: Text('Publicado', style: headerStyle)),
        DataColumn(label: Text('Acciones', style: headerStyle)),
      ],
      rows: avisos.map((a) {
        return DataRow(
          cells: [
            DataCell(
              Text(a.titulo, style: cellStyle, overflow: TextOverflow.ellipsis),
            ),
            DataCell(
              SizedBox(
                width: 340,
                child: Text(
                  a.mensaje,
                  style: cellStyle,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ),
            DataCell(StatusBadge(etiquetaTipo(a.tipo), tone: toneTipo(a.tipo))),
            DataCell(Text(fecha(a), style: cellStyle)),
            DataCell(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Tooltip(
                    message: 'Editar',
                    child: IconButton(
                      icon: const Icon(Icons.edit, size: 18),
                      color: p.accent,
                      onPressed: cargando ? null : () => onEditar(a),
                    ),
                  ),
                  Tooltip(
                    message: 'Eliminar del historial',
                    child: IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18),
                      color: p.danger,
                      onPressed: cargando ? null : () => onEliminar(a),
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

class _AvisoCard extends StatelessWidget {
  final AvisoModel aviso;
  final bool cargando;
  final String fecha;
  final String etiquetaTipo;
  final Tone toneTipo;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  const _AvisoCard({
    required this.aviso,
    required this.cargando,
    required this.fecha,
    required this.etiquetaTipo,
    required this.toneTipo,
    required this.onEditar,
    required this.onEliminar,
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
                      aviso.titulo,
                      style: TextStyle(
                        color: p.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: AppTokens.lg,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusBadge(etiquetaTipo, tone: toneTipo),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                aviso.mensaje,
                style: TextStyle(
                  color: p.textSecondary,
                  fontSize: AppTokens.sm,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              if (aviso.link.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Link: ${aviso.link}',
                  style: TextStyle(color: p.textMuted, fontSize: AppTokens.xs),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    'Publicado: $fecha',
                    style: TextStyle(
                      color: p.textMuted,
                      fontSize: AppTokens.xs,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    color: p.accent,
                    tooltip: 'Editar',
                    onPressed: cargando ? null : onEditar,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    color: p.danger,
                    tooltip: 'Eliminar del historial',
                    onPressed: cargando ? null : onEliminar,
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

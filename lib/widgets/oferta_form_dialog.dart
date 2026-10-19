import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/theme/cursar_palette.dart';
import '../core/theme/cursar_tone.dart';
import '../core/theme/cursar_theme.dart';
import '../models/oferta_model.dart';
import '../models/sesion_institucion.dart';
import '../services/auth_service.dart';
import '../services/ofertas_service.dart';
import '../services/tags_service.dart';
import '../core/widgets/info_banner.dart';

/// Diálogo modal para crear o editar una oferta académica.
class OfertaFormDialog extends StatefulWidget {
  final String? ofertaId;
  final OfertaModel? ofertaExistente;

  const OfertaFormDialog({super.key, this.ofertaId, this.ofertaExistente});

  @override
  State<OfertaFormDialog> createState() => _OfertaFormDialogState();
}

class _OfertaFormDialogState extends State<OfertaFormDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _cargando = true;
  bool _guardando = false;
  String? _error;

  SesionInstitucion? _sesion;

  List<String> _tagsDisponibles = const [];

  final _nombreCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  final _requisitosCtrl = TextEditingController();
  final _duracionCtrl = TextEditingController();
  final _costoCtrl = TextEditingController();

  String _area = '';
  String _nivel = '';
  String _modalidad = '';
  String _tag = '';

  static const _areas = <String>[
    'Técnico',
    'Terciario',
    'Universitario',
    'Capacitación',
    'Idioma',
    'Otro',
  ];
  static const _niveles = <String>[
    'Inicial',
    'Intermedio',
    'Avanzado',
    'Grado',
    'Postgrado',
    'Otro',
  ];
  static const _modalidades = <String>[
    'Presencial',
    'Virtual',
    'Híbrido',
    'Otro',
  ];

  bool get _esEdicion =>
      widget.ofertaId != null || widget.ofertaExistente != null;
  String? get _ofertaId => widget.ofertaId ?? widget.ofertaExistente?.ofertaId;

  @override
  void initState() {
    super.initState();
    _sesion = AuthService.instance.sesion;
    _cargarInicial();
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descripcionCtrl.dispose();
    _requisitosCtrl.dispose();
    _duracionCtrl.dispose();
    _costoCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarInicial() async {
    setState(() => _cargando = true);
    try {
      final tags = await TagsService.instance.obtenerNombres();
      if (widget.ofertaExistente != null) {
        final o = widget.ofertaExistente!;
        _nombreCtrl.text = o.nombre;
        _descripcionCtrl.text = o.descripcion;
        _requisitosCtrl.text = o.requisitos;
        _duracionCtrl.text = o.duracionAnios == 0 ? '' : '${o.duracionAnios}';
        _costoCtrl.text = o.salidaLaboral;
        _area = o.area;
        _nivel = o.nivel;
        _modalidad = o.modalidad;
        _tag = o.tag;
      } else if (_esEdicion && _ofertaId != null && _sesion != null) {
        final doc = await FirebaseFirestore.instance
            .collection('ofertas')
            .doc(_ofertaId)
            .get();
        if (doc.exists && doc.data() != null) {
          final o = OfertaModel.fromMap(doc.id, doc.data()!);
          _nombreCtrl.text = o.nombre;
          _descripcionCtrl.text = o.descripcion;
          _requisitosCtrl.text = o.requisitos;
          _duracionCtrl.text = o.duracionAnios == 0 ? '' : '${o.duracionAnios}';
          _costoCtrl.text = o.salidaLaboral;
          _area = o.area;
          _nivel = o.nivel;
          _modalidad = o.modalidad;
          _tag = o.tag;
        }
      }
      setState(() {
        _tagsDisponibles = tags;
        _cargando = false;
        _error = null;
      });
    } catch (_) {
      setState(() {
        _tagsDisponibles = const [];
        _cargando = false;
        _error = 'No se pudieron cargar los datos para el formulario.';
      });
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    final sesion = _sesion ?? AuthService.instance.sesion;
    if (sesion == null) {
      setState(() => _error = 'No hay una sesión activa.');
      return;
    }
    setState(() => _guardando = true);
    try {
      if (!_esEdicion) {
        await OfertasService.instance.crearOferta(
          OfertaModel(
            ofertaId: '',
            institucionUid: sesion.institucionUid,
            nombre: _nombreCtrl.text.trim(),
            descripcion: _descripcionCtrl.text.trim(),
            area: _area,
            nivel: _nivel,
            duracionAnios: int.tryParse(_duracionCtrl.text.trim()) ?? 0,
            modalidad: _modalidad,
            salidaLaboral: _costoCtrl.text.trim(),
            requisitos: _requisitosCtrl.text.trim(),
            tag: _tag,
            estado: 'activa',
            aprobada: false,
          ),
        );
      } else {
        if (_ofertaId == null) throw Exception('Falta ID de oferta');
        await OfertasService.instance.actualizarOferta(
          _ofertaId!,
          OfertaModel(
            ofertaId: _ofertaId!,
            institucionUid:
                widget.ofertaExistente?.institucionUid ?? sesion.institucionUid,
            nombre: _nombreCtrl.text.trim(),
            descripcion: _descripcionCtrl.text.trim(),
            area: _area,
            nivel: _nivel,
            duracionAnios: int.tryParse(_duracionCtrl.text.trim()) ?? 0,
            modalidad: _modalidad,
            salidaLaboral: _costoCtrl.text.trim(),
            requisitos: _requisitosCtrl.text.trim(),
            tag: _tag,
            estado: widget.ofertaExistente?.estado ?? 'activa',
            aprobada: widget.ofertaExistente?.aprobada ?? false,
          ),
        );
      }
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() {
        _guardando = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final width = MediaQuery.of(context).size.width;
    final dialogWidth = width >= 800
        ? 700.0
        : width >= 600
        ? 600.0
        : width - 24.0;

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: dialogWidth,
          maxHeight: 90 * MediaQuery.of(context).size.height / 100,
        ),
        child: Card(
          color: p.bgSurface,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _cargando
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _esEdicion ? 'Editar oferta' : 'Nueva oferta',
                              style: TextStyle(
                                color: p.textPrimary,
                                fontSize: AppTokens.xxl,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            color: p.textSecondary,
                            onPressed: _guardando
                                ? null
                                : () => Navigator.of(context).pop(false),
                          ),
                        ],
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 8),
                        InfoBanner(
                          message: _error!,
                          tone: Tone.danger,
                          icon: Icons.error,
                        ),
                      ],
                      const SizedBox(height: 12),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _campo(
                                  'Nombre de la oferta',
                                  _nombreCtrl,
                                  maxLines: 1,
                                  requerido: true,
                                ),
                                const SizedBox(height: 10),
                                _dropdown(
                                  'Área',
                                  _areas,
                                  _area,
                                  (v) => setState(() => _area = v ?? ''),
                                ),
                                const SizedBox(height: 10),
                                _dropdown(
                                  'Nivel',
                                  _niveles,
                                  _nivel,
                                  (v) => setState(() => _nivel = v ?? ''),
                                ),
                                const SizedBox(height: 10),
                                _dropdown(
                                  'Modalidad',
                                  _modalidades,
                                  _modalidad,
                                  (v) => setState(() => _modalidad = v ?? ''),
                                ),
                                const SizedBox(height: 10),
                                _dropdownTags(
                                  'Tag',
                                  _tagsDisponibles,
                                  _tag,
                                  (v) => setState(() => _tag = v ?? ''),
                                ),
                                const SizedBox(height: 10),
                                _campo(
                                  'Duración',
                                  _duracionCtrl,
                                  maxLines: 1,
                                  requerido: true,
                                ),
                                const SizedBox(height: 10),
                                _campo('Costo', _costoCtrl, maxLines: 1),
                                const SizedBox(height: 10),
                                _campo(
                                  'Requisitos',
                                  _requisitosCtrl,
                                  maxLines: 3,
                                ),
                                const SizedBox(height: 10),
                                _campo(
                                  'Descripción',
                                  _descripcionCtrl,
                                  maxLines: 5,
                                  requerido: true,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: _guardando
                                ? null
                                : () => Navigator.of(context).pop(false),
                            child: Text(
                              'Cancelar',
                              style: TextStyle(color: p.textSecondary),
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton.icon(
                            onPressed: _guardando ? null : _guardar,
                            icon: _guardando
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.save),
                            label: Text(
                              _esEdicion ? 'Guardar cambios' : 'Crear oferta',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _campo(
    String label,
    TextEditingController ctrl, {
    int maxLines = 1,
    bool requerido = false,
  }) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: p.textSecondary, fontSize: AppTokens.sm),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          maxLines: maxLines,
          style: TextStyle(color: p.textPrimary, fontSize: AppTokens.md),
          decoration: InputDecoration(
            filled: true,
            fillColor: p.bgSurface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTokens.radiusSm),
              borderSide: BorderSide(color: p.borderSubtle),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTokens.radiusSm),
              borderSide: BorderSide(color: p.borderSubtle),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTokens.radiusSm),
              borderSide: BorderSide(color: p.accent),
            ),
          ),
          validator: requerido
              ? (v) {
                  if (v == null || v.trim().isEmpty) return 'Campo obligatorio';
                  return null;
                }
              : null,
        ),
      ],
    );
  }

  Widget _dropdown(
    String label,
    List<String> opciones,
    String valor,
    ValueChanged<String?> onChanged,
  ) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: p.textSecondary, fontSize: AppTokens.sm),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: valor.isEmpty ? null : valor,
          dropdownColor: p.bgSurface,
          style: TextStyle(color: p.textPrimary, fontSize: AppTokens.md),
          decoration: InputDecoration(
            filled: true,
            fillColor: p.bgSurface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTokens.radiusSm),
              borderSide: BorderSide(color: p.borderSubtle),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTokens.radiusSm),
              borderSide: BorderSide(color: p.borderSubtle),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTokens.radiusSm),
              borderSide: BorderSide(color: p.accent),
            ),
          ),
          items: opciones
              .map(
                (e) => DropdownMenuItem<String>(
                  value: e,
                  child: Text(e, style: TextStyle(color: p.textPrimary)),
                ),
              )
              .toList(),
          onChanged: onChanged,
          validator: (v) =>
              (v == null || v.isEmpty) ? 'Campo obligatorio' : null,
        ),
      ],
    );
  }

  Widget _dropdownTags(
    String label,
    List<String> opciones,
    String valor,
    ValueChanged<String?> onChanged,
  ) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: p.textSecondary, fontSize: AppTokens.sm),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: valor.isEmpty ? null : valor,
          dropdownColor: p.bgSurface,
          style: TextStyle(color: p.textPrimary, fontSize: AppTokens.md),
          decoration: InputDecoration(
            filled: true,
            fillColor: p.bgSurface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTokens.radiusSm),
              borderSide: BorderSide(color: p.borderSubtle),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTokens.radiusSm),
              borderSide: BorderSide(color: p.borderSubtle),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTokens.radiusSm),
              borderSide: BorderSide(color: p.accent),
            ),
          ),
          items: opciones
              .map(
                (e) => DropdownMenuItem<String>(
                  value: e,
                  child: Text(e, style: TextStyle(color: p.textPrimary)),
                ),
              )
              .toList(),
          onChanged: onChanged,
          validator: (v) =>
              (v == null || v.isEmpty) ? 'Campo obligatorio' : null,
        ),
      ],
    );
  }
}

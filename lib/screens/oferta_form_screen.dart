import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/cursar_palette.dart';
import '../core/theme/cursar_theme.dart';
import '../models/oferta_model.dart';
import '../services/ofertas_service.dart';
import '../services/tags_service.dart';

/// Formulario para crear o editar una oferta académica.
///
/// Cuando se pasa [ofertaId], se edita una oferta existente (se precarga).
/// De lo contrario, se crea una nueva vinculada a la institución logueada.
/// Las ofertas nacen pendientes de moderación (`aprobada: false`).
class OfertaFormScreen extends StatefulWidget {
  final String? ofertaId;

  const OfertaFormScreen({super.key, this.ofertaId});

  @override
  State<OfertaFormScreen> createState() => _OfertaFormScreenState();
}

class _OfertaFormScreenState extends State<OfertaFormScreen> {
  /// Listas oficiales (tomadas del panel de administración).
  static const List<String> _areas = <String>[
    'Tecnología',
    'Ingeniería',
    'Salud',
    'Educación',
    'Creativa',
    'Administración',
    'Economía',
    'Ciencias Sociales',
    'Ciencias Ambientales',
    'Derecho',
    'Humanidades',
  ];
  static const List<String> _niveles = <String>['Universitario', 'Terciario'];
  static const List<String> _modalidades = <String>[
    'Presencial',
    'Bimodal',
    'Virtual',
  ];

  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  final _duracionCtrl = TextEditingController();
  final _salidaLaboralCtrl = TextEditingController();
  final _requisitosCtrl = TextEditingController();

  String? _area;
  String? _nivel;
  String? _modalidad;
  String? _tag;

  List<String> _tagsDisponibles = const <String>[];

  bool _cargando = false;
  bool _esEdicion = false;

  @override
  void initState() {
    super.initState();
    _esEdicion = widget.ofertaId != null;
    _cargarTags();
    if (_esEdicion) _cargarOferta();
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descripcionCtrl.dispose();
    _duracionCtrl.dispose();
    _salidaLaboralCtrl.dispose();
    _requisitosCtrl.dispose();
    super.dispose();
  }

  /// Carga los tags disponibles para el selector (si falla, queda libre).
  Future<void> _cargarTags() async {
    final tags = await TagsService.instance.obtenerNombres();
    if (mounted) setState(() => _tagsDisponibles = tags);
  }

  /// Precarga los datos de la oferta a editar.
  Future<void> _cargarOferta() async {
    setState(() => _cargando = true);
    try {
      final o = await OfertasService.instance.obtenerOferta(widget.ofertaId!);
      if (o != null && mounted) {
        setState(() {
          _nombreCtrl.text = o.nombre;
          _descripcionCtrl.text = o.descripcion;
          _duracionCtrl.text = o.duracionAnios == 0 ? '' : '${o.duracionAnios}';
          _salidaLaboralCtrl.text = o.salidaLaboral;
          _requisitosCtrl.text = o.requisitos;
          _area = o.area.isEmpty ? null : o.area;
          _nivel = o.nivel.isEmpty ? null : o.nivel;
          _modalidad = o.modalidad.isEmpty ? null : o.modalidad;
          _tag = o.tag.isEmpty ? null : o.tag;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo cargar la oferta: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _cargando = true);

    try {
      final oferta = OfertaModel(
        ofertaId: widget.ofertaId ?? '',
        institucionUid: '', // Se completa desde el servicio según la sesión.
        nombre: _nombreCtrl.text.trim(),
        descripcion: _descripcionCtrl.text.trim(),
        area: _area ?? '',
        nivel: _nivel ?? '',
        duracionAnios: int.tryParse(_duracionCtrl.text) ?? 0,
        modalidad: _modalidad ?? '',
        salidaLaboral: _salidaLaboralCtrl.text.trim(),
        requisitos: _requisitosCtrl.text.trim(),
        tag: _tag ?? '',
        estado: 'activa',
      );

      if (_esEdicion && widget.ofertaId != null) {
        await OfertasService.instance.actualizarOferta(
          widget.ofertaId!,
          oferta,
        );
      } else {
        await OfertasService.instance.crearOferta(oferta);
      }

      if (mounted) context.go('/institucion/ofertas');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar la oferta: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Widget _buildField(
    BuildContext context,
    CursarPalette p,
    TextEditingController ctrl, {
    String label = '',
    String? helper,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: ctrl,
          maxLines: maxLines,
          style: TextStyle(color: p.textPrimary),
          decoration: InputDecoration(labelText: label, helperText: helper),
          keyboardType: keyboardType,
          validator: validator,
        ),
      ],
    );
  }

  /// Select con las listas oficiales. Incluye [value] aunque no esté en la
  /// lista (por si hay datos viejos cargados a mano).
  Widget _buildDropdown({
    required CursarPalette p,
    required String label,
    required List<String> items,
    required String? value,
    required ValueChanged<String?> onChanged,
    String? Function(String?)? validator,
  }) {
    final opciones = <String>{...items, ?value}.toList();
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      style: TextStyle(color: p.textPrimary, fontSize: AppTokens.md2),
      dropdownColor: p.bgSurface,
      decoration: InputDecoration(labelText: label),
      items: [
        for (final item in opciones)
          DropdownMenuItem<String>(value: item, child: Text(item)),
      ],
      onChanged: onChanged,
      validator: validator,
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Form(
      key: _formKey,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          if (!_esEdicion)
            Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: p.warningSoft,
                borderRadius: BorderRadius.circular(AppTokens.radiusSm),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: p.warning),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'La oferta se publicará en la app una vez que el '
                      'administrador la apruebe.',
                      style: TextStyle(
                        color: p.warning,
                        fontSize: AppTokens.sm,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          _buildField(
            context,
            p,
            _nombreCtrl,
            label: 'Nombre de la carrera / curso',
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Ingresá el nombre' : null,
          ),
          const SizedBox(height: 10),
          _buildField(
            context,
            p,
            _descripcionCtrl,
            label: 'Descripción',
            maxLines: 3,
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Ingresá una descripción' : null,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  p: p,
                  label: 'Área',
                  items: _areas,
                  value: _area,
                  onChanged: (v) => setState(() => _area = v),
                  validator: (v) => v == null ? 'Elegí un área' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDropdown(
                  p: p,
                  label: 'Nivel',
                  items: _niveles,
                  value: _nivel,
                  onChanged: (v) => setState(() => _nivel = v),
                  validator: (v) => v == null ? 'Elegí un nivel' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildField(
                  context,
                  p,
                  _duracionCtrl,
                  label: 'Duración (años)',
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Ingresá la duración';
                    if (int.tryParse(v) == null) return 'Número válido';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDropdown(
                  p: p,
                  label: 'Modalidad',
                  items: _modalidades,
                  value: _modalidad,
                  onChanged: (v) => setState(() => _modalidad = v),
                  validator: (v) => v == null ? 'Elegí la modalidad' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildField(
            context,
            p,
            _salidaLaboralCtrl,
            label: 'Salida laboral',
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Ingresá la salida laboral' : null,
          ),
          const SizedBox(height: 10),
          _buildField(
            context,
            p,
            _requisitosCtrl,
            label: 'Requisitos',
            maxLines: 2,
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Ingresá los requisitos' : null,
          ),
          const SizedBox(height: 10),
          _buildDropdown(
            p: p,
            label: 'Etiqueta (tag)',
            items: _tagsDisponibles,
            value: _tag,
            onChanged: (v) => setState(() => _tag = v),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 38,
            child: ElevatedButton(
              onPressed: _cargando ? null : _guardar,
              style: ElevatedButton.styleFrom(
                backgroundColor: p.accent,
                foregroundColor: Colors.white,
              ),
              child: _cargando
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(_esEdicion ? 'Guardar cambios' : 'Crear oferta'),
            ),
          ),
          const SizedBox(height: 10),
          if (_esEdicion)
            SizedBox(
              width: double.infinity,
              height: 38,
              child: OutlinedButton(
                onPressed: _cargando ? null : () => context.pop(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: p.textSecondary,
                  side: BorderSide(color: p.borderSubtle),
                ),
                child: const Text('Cancelar'),
              ),
            ),
        ],
      ),
    );
  }
}

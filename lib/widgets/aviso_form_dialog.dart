import 'package:flutter/material.dart';

import '../core/theme/cursar_palette.dart';
import '../core/theme/cursar_tone.dart';
import '../core/theme/cursar_theme.dart';
import '../core/widgets/info_banner.dart';
import '../models/aviso_model.dart';
import '../services/avisos_service.dart';
import '../services/auth_service.dart';

/// Diálogo modal para crear o editar un aviso institucional.
///
/// Mismo funcionamiento que `OfertaFormDialog`: no navega a otra pantalla,
/// se abre desde la lista de Avisos y devuelve `true` al guardar.
class AvisoFormDialog extends StatefulWidget {
  final String? avisoId;
  final AvisoModel? avisoExistente;

  const AvisoFormDialog({super.key, this.avisoId, this.avisoExistente});

  @override
  State<AvisoFormDialog> createState() => _AvisoFormDialogState();
}

class _AvisoFormDialogState extends State<AvisoFormDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _guardando = false;
  String? _error;

  final _tituloCtrl = TextEditingController();
  final _mensajeCtrl = TextEditingController();
  final _linkCtrl = TextEditingController();
  String _tipo = 'noticia';

  static const _tipos = <String>[
    'noticia',
    'inscripcion',
    'consejo',
    'evento',
    'otro',
  ];

  bool get _esEdicion =>
      widget.avisoId != null || widget.avisoExistente != null;
  String? get _avisoId => widget.avisoId ?? widget.avisoExistente?.avisoId;

  @override
  void initState() {
    super.initState();
    final a = widget.avisoExistente;
    if (a != null) {
      _tituloCtrl.text = a.titulo;
      _mensajeCtrl.text = a.mensaje;
      _linkCtrl.text = a.link;
      _tipo = a.tipo;
    }
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _mensajeCtrl.dispose();
    _linkCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    final sesion = AuthService.instance.sesion;
    if (sesion == null) {
      setState(() => _error = 'No hay una sesión activa.');
      return;
    }
    setState(() => _guardando = true);
    try {
      if (!_esEdicion) {
        await AvisosService.instance.crearAviso(
          AvisoModel(
            avisoId: '',
            institucionUid: sesion.institucionUid,
            titulo: _tituloCtrl.text.trim(),
            mensaje: _mensajeCtrl.text.trim(),
            tipo: _tipo,
            link: _linkCtrl.text.trim(),
          ),
        );
      } else {
        if (_avisoId == null) throw Exception('Falta ID de aviso');
        await AvisosService.instance.actualizarAviso(
          _avisoId!,
          AvisoModel(
            avisoId: _avisoId!,
            institucionUid:
                widget.avisoExistente?.institucionUid ?? sesion.institucionUid,
            titulo: _tituloCtrl.text.trim(),
            mensaje: _mensajeCtrl.text.trim(),
            tipo: _tipo,
            link: _linkCtrl.text.trim(),
            createdAt: widget.avisoExistente?.createdAt,
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
        ? 640.0
        : width >= 600
        ? 560.0
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _esEdicion ? 'Editar aviso' : 'Nuevo aviso',
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
                Flexible(
                  child: SingleChildScrollView(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _campo(
                            'Título',
                            _tituloCtrl,
                            maxLines: 1,
                            requerido: true,
                          ),
                          const SizedBox(height: 10),
                          _dropdown(
                            'Tipo',
                            _tipos,
                            _tipo,
                            (v) => setState(() => _tipo = v ?? 'noticia'),
                          ),
                          const SizedBox(height: 10),
                          _campo(
                            'Link (opcional)',
                            _linkCtrl,
                            maxLines: 1,
                            hint: 'URL o ruta interna, ej. /map',
                          ),
                          const SizedBox(height: 10),
                          _campo(
                            'Mensaje',
                            _mensajeCtrl,
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
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save),
                      label: Text(
                        _esEdicion ? 'Guardar cambios' : 'Publicar aviso',
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
    String? hint,
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
            hintText: hint,
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
          initialValue: valor.isEmpty ? null : valor,
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
        ),
      ],
    );
  }
}

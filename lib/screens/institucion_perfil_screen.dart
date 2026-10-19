import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../core/theme/cursar_palette.dart';
import '../core/theme/cursar_theme.dart';
import '../services/auth_service.dart';
import '../services/logo_storage_service.dart';

/// Pantalla para editar los datos de la institución logueada.
///
/// Permite actualizar nombre, descripción, dirección, teléfono, email,
/// sitio web y logo URL. El logo se puede subir desde la galería
/// (se guarda en Firebase Storage) o pegando una URL directa.
/// Los cambios se guardan en Firestore en `instituciones/{institucionUid}`.
class InstitucionPerfilScreen extends StatefulWidget {
  const InstitucionPerfilScreen({super.key});

  @override
  State<InstitucionPerfilScreen> createState() =>
      _InstitucionPerfilScreenState();
}

class _InstitucionPerfilScreenState extends State<InstitucionPerfilScreen> {
  final _nombreCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();
  final _ciudadCtrl = TextEditingController();
  final _provinciaCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _sitioWebCtrl = TextEditingController();
  final _logoURLCtrl = TextEditingController();
  // Coordenadas para el mapa ("Cómo llegar") de la app.
  final _latCtrl = TextEditingController();
  final _lngCtrl = TextEditingController();

  bool _cargando = false;
  bool _subiendoLogo = false;
  String? _error;
  String? _mensajeExito;

  // Logo seleccionado desde galería (para subida a Storage).
  Uint8List? _logoBytes;
  String? _logoFileName;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final sesion = AuthService.instance.sesion;
    if (sesion?.institucionUid == null || sesion!.institucionUid.isEmpty)
      return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('instituciones')
          .doc(sesion.institucionUid)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        _nombreCtrl.text = data['nombre'] ?? '';
        _descripcionCtrl.text = data['descripcion'] ?? '';
        _direccionCtrl.text = data['direccion'] ?? '';
        _ciudadCtrl.text = data['ciudad'] ?? '';
        _provinciaCtrl.text = data['provincia'] ?? '';
        _telefonoCtrl.text = data['telefono'] ?? '';
        _emailCtrl.text = data['email'] ?? '';
        _sitioWebCtrl.text = data['sitioWeb'] ?? '';
        _logoURLCtrl.text = data['logoURL'] ?? '';
        // Coordenadas: acepta `latitud`/`longitud` numéricos o `ubicacion` (GeoPoint).
        final ubicacion = data['ubicacion'];
        double? lat = (data['latitud'] as num?)?.toDouble();
        double? lng = (data['longitud'] as num?)?.toDouble();
        if (ubicacion is GeoPoint) {
          lat ??= ubicacion.latitude;
          lng ??= ubicacion.longitude;
        }
        _latCtrl.text = lat?.toString() ?? '';
        _lngCtrl.text = lng?.toString() ?? '';
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Error al cargar datos: $e');
    }
  }

  /// Selecciona un archivo de imagen desde la galería.
  Future<void> _seleccionarLogo() async {
    final sesion = AuthService.instance.sesion;
    if (sesion?.institucionUid == null || sesion!.institucionUid.isEmpty) {
      setState(() => _error = 'No se pudo identificar la institución.');
      return;
    }

    setState(() {
      _error = null;
      _logoBytes = null;
      _logoFileName = null;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result == null) return; // El usuario canceló.

      final file = result.files.single;
      if (file.bytes == null) {
        setState(() => _error = 'No se pudo leer el archivo seleccionado.');
        return;
      }

      setState(() {
        _logoBytes = file.bytes;
        _logoFileName = file.name;
      });
    } catch (e) {
      if (mounted) setState(() => _error = 'Error al seleccionar archivo: $e');
    }
  }

  /// Sube el logo seleccionado a Firebase Storage y actualiza el campo URL.
  Future<void> _subirLogoSeleccionado() async {
    if (_logoBytes == null) return;

    final sesion = AuthService.instance.sesion;
    if (sesion?.institucionUid == null || sesion!.institucionUid.isEmpty) {
      setState(() => _error = 'No se pudo identificar la institución.');
      return;
    }

    setState(() {
      _subiendoLogo = true;
      _error = null;
    });

    try {
      final fileName =
          _logoFileName ?? 'logo_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final downloadUrl = await LogoStorageService.instance.subirLogo(
        bytes: _logoBytes!,
        institucionUid: sesion.institucionUid,
        fileName: fileName,
      );

      if (mounted) {
        setState(() {
          _logoURLCtrl.text = downloadUrl;
          _logoBytes = null;
          _logoFileName = null;
          _mensajeExito = 'Logo subido correctamente';
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Error al subir logo: $e');
    } finally {
      if (mounted) setState(() => _subiendoLogo = false);
    }
  }

  /// Elimina la selección de logo actual (sin subir).
  void _cancelarLogoSeleccionado() {
    setState(() {
      _logoBytes = null;
      _logoFileName = null;
    });
  }

  Future<void> _guardar() async {
    final sesion = AuthService.instance.sesion;
    if (sesion?.institucionUid == null || sesion!.institucionUid.isEmpty)
      return;

    setState(() {
      _cargando = true;
      _error = null;
      _mensajeExito = null;
    });

    try {
      final lat = double.tryParse(_latCtrl.text.trim().replaceAll(',', '.'));
      final lng = double.tryParse(_lngCtrl.text.trim().replaceAll(',', '.'));

      await FirebaseFirestore.instance
          .collection('instituciones')
          .doc(sesion.institucionUid)
          .update({
            'nombre': _nombreCtrl.text.trim(),
            'descripcion': _descripcionCtrl.text.trim(),
            'direccion': _direccionCtrl.text.trim(),
            'ciudad': _ciudadCtrl.text.trim(),
            'provincia': _provinciaCtrl.text.trim(),
            'telefono': _telefonoCtrl.text.trim(),
            'email': _emailCtrl.text.trim(),
            'sitioWeb': _sitioWebCtrl.text.trim(),
            'logoURL': _logoURLCtrl.text.trim(),
            'latitud': lat,
            'longitud': lng,
            'ubicacion': (lat != null && lng != null)
                ? GeoPoint(lat, lng)
                : null,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        setState(() => _mensajeExito = 'Perfil actualizado correctamente');
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Error al guardar: $e');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descripcionCtrl.dispose();
    _direccionCtrl.dispose();
    _ciudadCtrl.dispose();
    _provinciaCtrl.dispose();
    _telefonoCtrl.dispose();
    _emailCtrl.dispose();
    _sitioWebCtrl.dispose();
    _logoURLCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final sesion = AuthService.instance.sesion;
    final institucionUid = sesion?.institucionUid ?? '';

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Text(
          'Mi institución',
          style: TextStyle(
            color: p.textPrimary,
            fontSize: AppTokens.xxl,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Edita los datos de tu institución.',
          style: TextStyle(color: p.textSecondary),
        ),
        const SizedBox(height: 12),

        // Sección de logo.
        _seccionLogo(context, p, institucionUid),
        const SizedBox(height: 12),

        // Campos del formulario.
        _campoTexto(context, 'Nombre de la institución', _nombreCtrl, p),
        const SizedBox(height: 10),
        _campoTexto(context, 'Descripción', _descripcionCtrl, p, maxLines: 3),
        const SizedBox(height: 16),
        _campoTexto(context, 'Dirección', _direccionCtrl, p),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _campoTexto(context, 'Ciudad', _ciudadCtrl, p)),
            const SizedBox(width: 12),
            Expanded(
              child: _campoTexto(context, 'Provincia', _provinciaCtrl, p),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _campoTexto(
          context,
          'Teléfono',
          _telefonoCtrl,
          p,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 10),
        _campoTexto(
          context,
          'Email',
          _emailCtrl,
          p,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 10),
        _campoTexto(context, 'Sitio web', _sitioWebCtrl, p),
        const SizedBox(height: 10),
        // Coordenadas (mapa y "Cómo llegar" en la app).
        Row(
          children: [
            Expanded(
              child: _campoTexto(
                context,
                'Latitud',
                _latCtrl,
                p,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _campoTexto(
                context,
                'Longitud',
                _lngCtrl,
                p,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Se usan para ubicar la institución en el mapa de la app. '
          'Ej.: -34.6037 / -58.3816.',
          style: TextStyle(color: p.textMuted, fontSize: 11),
        ),
        const SizedBox(height: 10),
        _campoTexto(context, 'Logo URL', _logoURLCtrl, p),
        const SizedBox(height: 12),

        // Mensajes de feedback.
        if (_mensajeExito != null)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: p.successSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              _mensajeExito!,
              style: TextStyle(color: p.success, fontSize: AppTokens.md2),
            ),
          ),
        if (_error != null)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: p.dangerSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              _error!,
              style: TextStyle(color: p.danger, fontSize: AppTokens.md2),
            ),
          ),
        const SizedBox(height: 16),

        // Botón guardar.
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
                ? const CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  )
                : const Text('Guardar cambios'),
          ),
        ),
      ],
    );
  }

  /// Sección de carga de logo con preview, selección de archivo y subida.
  Widget _seccionLogo(
    BuildContext context,
    CursarPalette p,
    String institucionUid,
  ) {
    final tieneLogoURL = _logoURLCtrl.text.isNotEmpty;
    final tieneLogoSeleccionado = _logoBytes != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Logo de la institución',
          style: TextStyle(
            color: p.textPrimary,
            fontSize: AppTokens.lg,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),

        // Preview del logo actual (URL guardada).
        if (tieneLogoURL)
          Center(
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: p.bgInput,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: p.borderSubtle),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      _logoURLCtrl.text,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          const Icon(Icons.broken_image, size: 40),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Logo actual',
                  style: TextStyle(color: p.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
        if (tieneLogoSeleccionado && _logoBytes != null)
          Center(
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: p.bgInput,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: p.borderSubtle),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.memory(_logoBytes!, fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Logo seleccionado',
                  style: TextStyle(color: p.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Text(
                  _logoFileName ?? '',
                  style: TextStyle(
                    color: p.textMuted,
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 8),
                if (_subiendoLogo)
                  const CircularProgressIndicator(strokeWidth: 2)
                else
                  SizedBox(
                    width: double.infinity,
                    height: 36,
                    child: ElevatedButton.icon(
                      onPressed: _subiendoLogo ? null : _subirLogoSeleccionado,
                      icon: const Icon(Icons.cloud_upload, size: 18),
                      label: const Text('Subir logo a Storage'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: p.accent,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _cancelarLogoSeleccionado,
                  child: const Text('Cancelar selección'),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _subiendoLogo ? null : _seleccionarLogo,
                icon: const Icon(Icons.image, size: 18),
                label: const Text('Seleccionar archivo'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: p.textPrimary,
                  side: BorderSide(color: p.borderSubtle),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _logoURLCtrl,
                style: TextStyle(color: p.textPrimary),
                decoration: InputDecoration(
                  hintText: 'https://...logo.png',
                  labelText: 'O pegá URL del logo',
                  labelStyle: TextStyle(color: p.textSecondary),
                  hintStyle: TextStyle(color: p.textMuted),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: p.borderSubtle),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: p.borderSubtle),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: p.accent),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Podés subir una imagen desde tu galería o pegar una URL directa.',
          style: TextStyle(color: p.textMuted, fontSize: 11),
        ),
      ],
    );
  }

  Widget _campoTexto(
    BuildContext context,
    String label,
    TextEditingController ctrl,
    CursarPalette p, {
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: ctrl,
          maxLines: maxLines,
          style: TextStyle(color: p.textPrimary),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(color: p.textSecondary),
            hintStyle: TextStyle(color: p.textMuted),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: p.borderSubtle),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: p.borderSubtle),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: p.accent),
            ),
          ),
          keyboardType: keyboardType,
        ),
      ],
    );
  }
}

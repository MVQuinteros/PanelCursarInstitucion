import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/cursar_palette.dart';
import '../services/auth_service.dart';

/// Pantalla de registro de una nueva institución.
///
/// Crea la cuenta en Firebase Auth, el documento de institución con
/// `estado: 'pendiente'` y el documento de usuario vinculado.
class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  bool _cargando = false;
  String? _error;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descripcionCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _telefonoCtrl.dispose();
    super.dispose();
  }

  Future<void> _registrar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      await AuthService.instance.registrarInstitucion(
        nombre: _nombreCtrl.text.trim(),
        descripcion: _descripcionCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        telefono: _telefonoCtrl.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Institución registrada. Queda pendiente de activación por el administrador.',
            ),
          ),
        );
        context.go('/login');
      }
    } catch (e) {
      final mensaje = AuthService.instance.mensajeError(e);
      debugPrint('[RegistroScreen] Error de registro: $e');
      setState(() => _error = mensaje);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      backgroundColor: p.bgMain,
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Card(
              color: p.bgSurface,
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Registrar institución',
                        style: TextStyle(
                          color: p.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tu perfil quedará pendiente de activación por el administrador.',
                        style: TextStyle(
                          color: p.textSecondary,
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      if (_error != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          color: p.dangerSoft,
                          child: Text(
                            _error!,
                            style: TextStyle(
                              color: p.danger,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      TextFormField(
                        controller: _nombreCtrl,
                        style: TextStyle(color: p.textPrimary),
                        decoration: InputDecoration(
                          labelText: 'Nombre de la institución',
                          labelStyle: TextStyle(color: p.textSecondary),
                          hintStyle: TextStyle(color: p.textMuted),
                          prefixIconColor: p.textSecondary,
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
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Ingresá el nombre' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descripcionCtrl,
                        maxLines: 2,
                        style: TextStyle(color: p.textPrimary),
                        decoration: InputDecoration(
                          labelText: 'Descripción',
                          labelStyle: TextStyle(color: p.textSecondary),
                          hintStyle: TextStyle(color: p.textMuted),
                          prefixIconColor: p.textSecondary,
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
                        validator: (v) =>
                            (v == null || v.isEmpty)
                                ? 'Ingresá una descripción'
                                : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        style: TextStyle(color: p.textPrimary),
                        decoration: InputDecoration(
                          labelText: 'Correo electrónico',
                          labelStyle: TextStyle(color: p.textSecondary),
                          hintStyle: TextStyle(color: p.textMuted),
                          prefixIconColor: p.textSecondary,
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
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Ingresá tu email' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordCtrl,
                        obscureText: true,
                        style: TextStyle(color: p.textPrimary),
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          labelStyle: TextStyle(color: p.textSecondary),
                          hintStyle: TextStyle(color: p.textMuted),
                          prefixIconColor: p.textSecondary,
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
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Ingresá una contraseña';
                          }
                          if (v.length < 6) {
                            return 'Mínimo 6 caracteres';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _telefonoCtrl,
                        keyboardType: TextInputType.phone,
                        style: TextStyle(color: p.textPrimary),
                        decoration: InputDecoration(
                          labelText: 'Teléfono',
                          labelStyle: TextStyle(color: p.textSecondary),
                          hintStyle: TextStyle(color: p.textMuted),
                          prefixIconColor: p.textSecondary,
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
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _cargando ? null : _registrar,
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
                              : const Text('Registrar institución'),
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextButton(
                        onPressed: () => context.go('/login'),
                        child: const Text('Ya tenés cuenta? Iniciá sesión'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

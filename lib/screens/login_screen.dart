import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/cursar_palette.dart';
import '../services/auth_service.dart';

/// Pantalla de inicio de sesión (email / contraseña y Google).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _cargando = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _iniciarSesion() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      await AuthService.instance.iniciarSesion(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
      if (mounted) context.go('/institucion');
    } catch (e) {
      debugPrint('[LoginScreen] Error de login: $e');
      setState(() => _error = AuthService.instance.mensajeError(e));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _iniciarConGoogle() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      await AuthService.instance.iniciarSesionConGoogle();
      if (mounted) context.go('/institucion');
    } catch (e) {
      debugPrint('[LoginScreen] Error de login con Google: $e');
      setState(() => _error = AuthService.instance.mensajeError(e));
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
                        'Iniciar sesión',
                        style: TextStyle(
                          color: p.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
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
                        validator: (v) =>
                            (v == null || v.isEmpty)
                                ? 'Ingresá tu contraseña'
                                : null,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _cargando ? null : _iniciarSesion,
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
                              : const Text('Ingresar'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: _cargando ? null : _iniciarConGoogle,
                          icon: Image.asset(
                            'assets/imagenes/logoGoogle.png',
                            height: 20,
                          ),
                          label: const Text('Continuar con Google'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: p.textPrimary,
                            side: BorderSide(color: p.borderSubtle),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextButton(
                        onPressed: () => context.go('/registro'),
                        child: const Text('¿No tenés cuenta? Regístrate'),
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

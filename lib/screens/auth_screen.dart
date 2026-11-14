import 'package:material_ui/material_ui.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../services/auth_service.dart';
import 'dashboard_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  static const FlutterSecureStorage _credentialStorage = FlutterSecureStorage();
  static const String _savedEmailKey = 'remembered_login_email';
  static const String _savedPasswordKey = 'remembered_login_password';

  final AuthService _auth = AuthService();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool isRegister = false;
  bool loading = false;
  bool obscurePassword = true;
  bool rememberCredentials = true;
  bool _credentialsLoading = true;
  String? _credentialStorageWarning;

  @override
  void initState() {
    super.initState();
    _loadRememberedCredentials();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _loadRememberedCredentials() async {
    try {
      final email = await _credentialStorage.read(key: _savedEmailKey);
      final password = await _credentialStorage.read(key: _savedPasswordKey);

      if (!mounted) return;

      setState(() {
        if (email != null) _emailController.text = email;
        if (password != null) _passwordController.text = password;
        if (email != null && password != null) rememberCredentials = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _credentialStorageWarning =
            'No se pudieron cargar las credenciales guardadas: $e';
      });
    } finally {
      if (mounted) setState(() => _credentialsLoading = false);
    }
  }

  Future<void> _saveCredentials() async {
    if (rememberCredentials) {
      await _credentialStorage.write(
        key: _savedEmailKey,
        value: _emailController.text.trim(),
      );
      await _credentialStorage.write(
        key: _savedPasswordKey,
        value: _passwordController.text,
      );
    } else {
      await _credentialStorage.delete(key: _savedEmailKey);
      await _credentialStorage.delete(key: _savedPasswordKey);
    }
  }

  Future<void> submit() async {
    if (loading || _credentialsLoading) return;

    setState(() => loading = true);

    try {
      if (isRegister) {
        await _auth.register(
          name: _nameController.text,
          email: _emailController.text,
          password: _passwordController.text,
        );
      }

      final user = await _auth.login(
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (!mounted) return;

      if (user == null) {
        showMessage('Correo o contraseña incorrectos.');
        return;
      }

      String? storageWarning;
      try {
        await _saveCredentials();
      } catch (e) {
        storageWarning =
            'Iniciaste sesión, pero no se pudieron guardar las credenciales: $e';
      }

      if (!mounted) return;

      if (storageWarning != null) {
        await showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Sesión iniciada'),
            content: Text(storageWarning!),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Entendido'),
              ),
            ],
          ),
        );
      }

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const _SunWelcomeDialog(),
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => DashboardScreen(user: user)),
      );
    } catch (e) {
      if (mounted) {
        showMessage(e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFF8E1), Color(0xFFE2F2ED), Color(0xFFE4F3F4)],
          ),
        ),
        child: Stack(
          children: [
            const Positioned(
              top: 28,
              right: 12,
              child: Icon(Icons.wb_sunny, size: 150, color: Color(0x33E6A700)),
            ),
            const Positioned(
              bottom: 30,
              left: 18,
              child: Icon(
                Icons.trending_up,
                size: 110,
                color: Color(0x33168B70),
              ),
            ),
            const Positioned(
              bottom: 105,
              right: 22,
              child: Icon(
                Icons.savings_outlined,
                size: 72,
                color: Color(0x33168B70),
              ),
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Card(
                      color: const Color(0xF8FFFFFF),
                      elevation: 10,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Icon(
                              Icons.account_balance_wallet_rounded,
                              size: 75,
                              color: Color(0xFF168B70),
                            ),
                            const SizedBox(height: 15),
                            const Text(
                              'NuevoDia 🌞',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF168B70),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              isRegister
                                  ? 'Comienza a organizar tu dinero'
                                  : 'Administra mejor tu dinero',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 30),
                            if (isRegister) ...[
                              TextField(
                                controller: _nameController,
                                decoration: const InputDecoration(
                                  labelText: 'Nombre completo',
                                  prefixIcon: Icon(Icons.person_outline),
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 15),
                            ],
                            TextField(
                              controller: _emailController,
                              enabled: !_credentialsLoading,
                              keyboardType: TextInputType.emailAddress,
                              autofillHints: const [AutofillHints.email],
                              decoration: const InputDecoration(
                                labelText: 'Correo electrónico',
                                prefixIcon: Icon(Icons.email_outlined),
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 15),
                            TextField(
                              controller: _passwordController,
                              enabled: !_credentialsLoading,
                              obscureText: obscurePassword,
                              autofillHints: const [AutofillHints.password],
                              decoration: InputDecoration(
                                labelText: 'Contraseña',
                                prefixIcon: const Icon(Icons.lock_outline),
                                border: const OutlineInputBorder(),
                                suffixIcon: IconButton(
                                  onPressed: _credentialsLoading
                                      ? null
                                      : () {
                                          setState(() {
                                            obscurePassword = !obscurePassword;
                                          });
                                        },
                                  icon: Icon(
                                    obscurePassword
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                  ),
                                ),
                              ),
                            ),
                            CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              controlAffinity: ListTileControlAffinity.leading,
                              value: rememberCredentials,
                              onChanged: _credentialsLoading || loading
                                  ? null
                                  : (value) {
                                      setState(
                                        () => rememberCredentials =
                                            value ?? false,
                                      );
                                    },
                              title: const Text(
                                'Recordar mis credenciales en este dispositivo',
                              ),
                              dense: true,
                            ),
                            if (_credentialStorageWarning != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                _credentialStorageWarning!,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 50,
                              child: FilledButton(
                                onPressed: loading || _credentialsLoading
                                    ? null
                                    : submit,
                                child: loading || _credentialsLoading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        isRegister
                                            ? 'Crear cuenta'
                                            : 'Iniciar sesión',
                                      ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextButton(
                              onPressed: loading || _credentialsLoading
                                  ? null
                                  : () {
                                      setState(() {
                                        isRegister = !isRegister;
                                      });
                                    },
                              child: Text(
                                isRegister
                                    ? 'Ya tengo una cuenta'
                                    : '¿No tienes cuenta? Regístrate',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SunWelcomeDialog extends StatefulWidget {
  const _SunWelcomeDialog();

  @override
  State<_SunWelcomeDialog> createState() => _SunWelcomeDialogState();
}

class _SunWelcomeDialogState extends State<_SunWelcomeDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _scale = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _controller.forward();

    Future<void>.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) => Transform.rotate(
                angle: -0.12 + (_controller.value * 0.24),
                child: ScaleTransition(scale: _scale, child: child),
              ),
              child: const Text('🌞', style: TextStyle(fontSize: 82)),
            ),
            const SizedBox(height: 12),
            const Text(
              '¡Bienvenido!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text('Tu día financiero comienza ahora.'),
          ],
        ),
      ),
    );
  }
}

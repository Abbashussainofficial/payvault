import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'auth_provider.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login(AuthProvider auth) async {
    await auth.login(_passwordCtrl.text);
    if (mounted && auth.errorMessage == null) _passwordCtrl.clear();
  }

  void _openForgotPassword(AuthProvider auth) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ForgotPasswordDialog(auth: auth),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    if (auth.isFirstLaunch) return _SetupScreen(auth: auth);

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Logo(),
                    const SizedBox(height: 32),
                    Text('Welcome back', style: tt.headlineMedium),
                    const SizedBox(height: 4),
                    Text('Sign in to PayVault', style: tt.bodyMedium?.copyWith(color: cs.onSurface.withValues(alpha: 0.6))),
                    const SizedBox(height: 28),
                    TextField(
                      controller: _passwordCtrl,
                      obscureText: _obscure,
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      onSubmitted: (_) => _login(auth),
                    ),
                    if (auth.errorMessage != null) ...[
                      const SizedBox(height: 12),
                      _ErrorBanner(message: auth.errorMessage!),
                    ],
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => _login(auth),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 2),
                        child: Text('Sign In'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => _openForgotPassword(auth),
                      child: const Text('Forgot Password?'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── First-time Setup ────────────────────────────────────────────────────────

class _SetupScreen extends StatefulWidget {
  const _SetupScreen({required this.auth});
  final AuthProvider auth;

  @override
  State<_SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<_SetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _questionCtrl = TextEditingController();
  final _answerCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  static const _questions = [
    'What was the name of your first pet?',
    'What city were you born in?',
    'What is your mother\'s maiden name?',
    'What was the name of your first school?',
    'What is your favorite book?',
  ];

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _questionCtrl.dispose();
    _answerCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await widget.auth.setupFirstTime(
      _passwordCtrl.text,
      _questionCtrl.text,
      _answerCtrl.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Logo(),
                      const SizedBox(height: 32),
                      Text('Set Up PayVault', style: tt.headlineMedium),
                      const SizedBox(height: 4),
                      Text(
                        'Create a password to protect your payroll data.',
                        style: tt.bodyMedium?.copyWith(color: cs.onSurface.withValues(alpha: 0.6)),
                      ),
                      const SizedBox(height: 28),
                      TextFormField(
                        controller: _passwordCtrl,
                        obscureText: _obscurePass,
                        decoration: InputDecoration(
                          labelText: 'Create Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePass ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                            onPressed: () => setState(() => _obscurePass = !_obscurePass),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.length < 4) return 'Minimum 4 characters required.';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _confirmCtrl,
                        obscureText: _obscureConfirm,
                        decoration: InputDecoration(
                          labelText: 'Confirm Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(_obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                            onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                          ),
                        ),
                        validator: (v) {
                          if (v != _passwordCtrl.text) return 'Passwords do not match.';
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      Text('Recovery Question', style: tt.titleMedium),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _questionCtrl.text.isEmpty ? null : _questionCtrl.text,
                        decoration: const InputDecoration(
                          labelText: 'Security Question',
                          prefixIcon: Icon(Icons.help_outline),
                        ),
                        items: _questions
                            .map((q) => DropdownMenuItem(value: q, child: Text(q, overflow: TextOverflow.ellipsis)))
                            .toList(),
                        onChanged: (v) => setState(() => _questionCtrl.text = v ?? ''),
                        validator: (v) => (v == null || v.isEmpty) ? 'Please select a question.' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _answerCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Security Answer',
                          prefixIcon: Icon(Icons.question_answer_outlined),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Answer is required.' : null,
                      ),
                      if (widget.auth.errorMessage != null) ...[
                        const SizedBox(height: 16),
                        _ErrorBanner(message: widget.auth.errorMessage!),
                      ],
                      const SizedBox(height: 28),
                      ElevatedButton(
                        onPressed: _submit,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 2),
                          child: Text('Create Account'),
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
    );
  }
}

// ─── Forgot Password Dialog ──────────────────────────────────────────────────

class _ForgotPasswordDialog extends StatefulWidget {
  const _ForgotPasswordDialog({required this.auth});
  final AuthProvider auth;

  @override
  State<_ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<_ForgotPasswordDialog> {
  final _answerCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _answerVerified = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _answerCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _verifyAnswer() async {
    final ok = await widget.auth.verifySecurityAnswer(_answerCtrl.text);
    setState(() {
      _answerVerified = ok;
      _error = ok ? null : 'Incorrect answer. Please try again.';
    });
  }

  Future<void> _resetPassword() async {
    if (_newPassCtrl.text.length < 4) {
      setState(() => _error = 'Password must be at least 4 characters.');
      return;
    }
    if (_newPassCtrl.text != _confirmCtrl.text) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }
    final ok = await widget.auth.resetPassword(_newPassCtrl.text);
    if (ok && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return AlertDialog(
      title: const Text('Reset Password'),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!_answerVerified) ...[
              Text(
                widget.auth.securityQuestion ?? 'Security Question',
                style: tt.titleMedium,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _answerCtrl,
                decoration: const InputDecoration(
                  labelText: 'Your Answer',
                  prefixIcon: Icon(Icons.question_answer_outlined),
                ),
              ),
            ] else ...[
              Text('Enter a new password', style: tt.titleMedium),
              const SizedBox(height: 16),
              TextField(
                controller: _newPassCtrl,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _confirmCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm Password',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              _ErrorBanner(message: _error!),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.6))),
        ),
        ElevatedButton(
          onPressed: _answerVerified ? _resetPassword : _verifyAnswer,
          child: Text(_answerVerified ? 'Reset Password' : 'Verify'),
        ),
      ],
    );
  }
}

// ─── Shared Widgets ──────────────────────────────────────────────────────────

class _Logo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: cs.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.account_balance_wallet, color: Colors.white, size: 26),
        ),
        const SizedBox(width: 12),
        Text(
          'PayVault',
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
            color: cs.primary,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF3D1515) : const Color(0xFFFFF5F5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? const Color(0xFF822020) : const Color(0xFFFEB2B2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 16, color: Color(0xFFE53E3E)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: const TextStyle(color: Color(0xFFE53E3E), fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

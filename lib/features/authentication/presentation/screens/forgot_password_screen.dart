import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_routes.dart';
import '../../domain/services/password_rules.dart';
import '../providers/password_recovery_provider.dart';

/// Multi-step password recovery host.
class ForgotPasswordScreen extends ConsumerWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(passwordRecoveryProvider);

    return switch (state.step) {
      PasswordRecoveryStep.identifier => const _IdentifierStep(),
      PasswordRecoveryStep.recoveryKey => const _RecoveryKeyStep(),
      PasswordRecoveryStep.totp => const _TotpStep(),
      PasswordRecoveryStep.newPassword => const _NewPasswordStep(),
      PasswordRecoveryStep.success => const _SuccessStep(),
    };
  }
}

class _RecoveryScaffold extends StatelessWidget {
  const _RecoveryScaffold({
    required this.title,
    required this.subtitle,
    required this.child,
    this.onBack,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final horizontalPadding = width >= 600 ? 48.0 : 28.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Forgot Password'),
        leading: onBack == null
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: onBack,
              ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: 24,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 28),
                  child,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IdentifierStep extends ConsumerStatefulWidget {
  const _IdentifierStep();

  @override
  ConsumerState<_IdentifierStep> createState() => _IdentifierStepState();
}

class _IdentifierStepState extends ConsumerState<_IdentifierStep> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final ok = await ref
        .read(passwordRecoveryProvider.notifier)
        .submitIdentifier(_controller.text);
    if (!ok && mounted) {
      final message = ref.read(passwordRecoveryProvider).errorMessage;
      if (message != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(passwordRecoveryProvider).isLoading;

    return _RecoveryScaffold(
      title: 'Recover your account',
      subtitle:
          'Enter your Username or Velix User ID to begin password recovery.',
      onBack: () => context.go(AppRoutes.login),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _controller,
              enabled: !isLoading,
              textInputAction: TextInputAction.done,
              autocorrect: false,
              onFieldSubmitted: (_) => _submit(),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_@]')),
                TextInputFormatter.withFunction((oldValue, newValue) {
                  final cleaned = newValue.text.replaceAll('@', '');
                  final cursor = newValue.selection.end;
                  final removed = '@'
                      .allMatches(
                        newValue.text.substring(
                          0,
                          cursor.clamp(0, newValue.text.length),
                        ),
                      )
                      .length;
                  final next =
                      (cursor - removed).clamp(0, cleaned.length);
                  return TextEditingValue(
                    text: cleaned,
                    selection: TextSelection.collapsed(offset: next),
                  );
                }),
              ],
              decoration: const InputDecoration(
                labelText: 'Username or Velix User ID',
                hintText: 'username or username_VX…',
                prefixText: '@ ',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Invalid username';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: isLoading ? null : _submit,
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecoveryKeyStep extends ConsumerStatefulWidget {
  const _RecoveryKeyStep();

  @override
  ConsumerState<_RecoveryKeyStep> createState() => _RecoveryKeyStepState();
}

class _RecoveryKeyStepState extends ConsumerState<_RecoveryKeyStep> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final ok = await ref
        .read(passwordRecoveryProvider.notifier)
        .submitRecoveryKey(_controller.text);
    if (!ok && mounted) {
      final message = ref.read(passwordRecoveryProvider).errorMessage;
      if (message != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(passwordRecoveryProvider).isLoading;
    final account = ref.watch(passwordRecoveryProvider).account;

    return _RecoveryScaffold(
      title: 'Recovery Security Key',
      subtitle:
          'Enter the Recovery Security Key shown when you created '
          '${account?.username ?? 'your account'}.',
      onBack: () {
        ref.read(passwordRecoveryProvider.notifier).reset();
      },
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _controller,
              enabled: !isLoading,
              obscureText: _obscure,
              textInputAction: TextInputAction.done,
              textCapitalization: TextCapitalization.characters,
              onFieldSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: 'Recovery Security Key',
                hintText: 'RK-XXXX-XXXX-XXXX',
                prefixIcon: const Icon(Icons.vpn_key_outlined),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Invalid Recovery Security Key';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: isLoading ? null : _submit,
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Verify Key'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TotpStep extends ConsumerStatefulWidget {
  const _TotpStep();

  @override
  ConsumerState<_TotpStep> createState() => _TotpStepState();
}

class _TotpStepState extends ConsumerState<_TotpStep> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final ok =
        await ref.read(passwordRecoveryProvider.notifier).submitTotp(
              _controller.text,
            );
    if (!ok && mounted) {
      final message = ref.read(passwordRecoveryProvider).errorMessage;
      if (message != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(passwordRecoveryProvider).isLoading;

    return _RecoveryScaffold(
      title: 'Two-Step Verification',
      subtitle:
          'Enter the 6-digit code from Google Authenticator to continue.',
      onBack: () {
        ref.read(passwordRecoveryProvider.notifier).reset();
      },
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _controller,
              enabled: !isLoading,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              maxLength: 6,
              onFieldSubmitted: (_) => _submit(),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              decoration: const InputDecoration(
                labelText: 'Authenticator Code',
                hintText: '123456',
                counterText: '',
                prefixIcon: Icon(Icons.phonelink_lock_outlined),
              ),
              validator: (value) {
                if (value == null || value.trim().length != 6) {
                  return 'Invalid Google Authenticator OTP';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: isLoading ? null : _submit,
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Verify OTP'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NewPasswordStep extends ConsumerStatefulWidget {
  const _NewPasswordStep();

  @override
  ConsumerState<_NewPasswordStep> createState() => _NewPasswordStepState();
}

class _NewPasswordStepState extends ConsumerState<_NewPasswordStep> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final password = _passwordController.text;
    if (password != _confirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    final ok = await ref
        .read(passwordRecoveryProvider.notifier)
        .submitNewPassword(password);
    if (!ok && mounted) {
      final message = ref.read(passwordRecoveryProvider).errorMessage;
      if (message != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLoading = ref.watch(passwordRecoveryProvider).isLoading;
    final password = _passwordController.text;
    final strength = PasswordRules.strengthOf(password);

    return _RecoveryScaffold(
      title: 'Create New Password',
      subtitle: 'Choose a strong password for your Velix account.',
      onBack: () {
        ref.read(passwordRecoveryProvider.notifier).reset();
      },
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _passwordController,
              enabled: !isLoading,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.next,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'New Password',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              validator: (value) {
                final error = PasswordRules.validationError(value ?? '');
                if (error != null) return error;
                if (PasswordRules.strengthOf(value ?? '') !=
                    PasswordStrength.strong) {
                  return 'Weak password';
                }
                return null;
              },
            ),
            const SizedBox(height: 10),
            Text(
              'Password strength: ${strength.name[0].toUpperCase()}${strength.name.substring(1)}',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmController,
              enabled: !isLoading,
              obscureText: _obscureConfirm,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() => _obscureConfirm = !_obscureConfirm);
                  },
                  icon: Icon(
                    _obscureConfirm
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Confirm your password';
                }
                if (value != _passwordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: isLoading ? null : _submit,
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Update Password'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuccessStep extends ConsumerWidget {
  const _SuccessStep();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    size: 72,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Password Updated Successfully',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'You can now sign in with your new password.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 32),
                  FilledButton(
                    onPressed: () {
                      ref.read(passwordRecoveryProvider.notifier).reset();
                      context.go(AppRoutes.login);
                    },
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Back to Login'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

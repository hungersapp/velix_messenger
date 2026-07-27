import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_routes.dart';
import '../../../../core/security/secure_storage_providers.dart';
import '../../../../core/security/session_security_gate.dart';
import '../../../settings/presentation/providers/settings_feature_providers.dart';
import '../../../user/presentation/providers/current_user_provider.dart';
import '../providers/auth_provider.dart';

/// Velix authentication login UI.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _identifierController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Ensures a single leading `@` for username or Velix User ID.
  String _toStoredIdentifier(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return '';
    final withoutAts = trimmed.replaceFirst(RegExp(r'^@+'), '');
    return '@$withoutAts';
  }

  Future<void> _onLogin() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authProvider.notifier).signIn(
          velixId: _toStoredIdentifier(_identifierController.text),
          password: _passwordController.text,
        );

    if (!mounted) return;

    if (!success) {
      final error = ref.read(authProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorText(error))),
      );
      return;
    }

    ref.invalidate(currentUserProvider);
    await ref.read(currentUserProvider.notifier).refreshUser();
    final user = ref.read(currentUserProvider).valueOrNull;

    if (!mounted) return;

    if (user != null) {
      final enabled = await ref
          .read(settingsRepositoryProvider)
          .isTwoFactorEnabled(user.uid);
      final secure = ref.read(secureStorageServiceProvider);
      await secure.setTotpEnabled(enabled);
      if (enabled) {
        final otp = await _promptTotp();
        if (otp == null || otp.isEmpty) {
          await ref.read(authRepositoryProvider).signOut();
          return;
        }
        final ok =
            await ref.read(settingsRepositoryProvider).verifyLoginTotp(otp);
        if (!ok) {
          await ref.read(authRepositoryProvider).signOut();
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid authenticator code')),
          );
          return;
        }
      }
      await secure.setAuthSession(uid: user.uid);
    }

    SessionSecurityGate.markSecondFactorVerified();

    if (!mounted) return;
    context.go(AppRoutes.home);
  }

  Future<String?> _promptTotp() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Two-Factor Authentication'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            maxLength: 6,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Authenticator code',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Verify'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    return result;
  }

  String _errorText(Object? error) {
    if (error == null) return 'Login failed';
    return error.toString().replaceFirst('Exception: ', '');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final width = MediaQuery.sizeOf(context).width;
    final horizontalPadding = width >= 600 ? 48.0 : 28.0;
    final isLoading = ref.watch(authProvider).isLoading;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: 24,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(theme),
                    const SizedBox(height: 36),
                    _buildIdentifierField(isLoading),
                    const SizedBox(height: 16),
                    _buildPasswordField(isLoading),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: isLoading
                            ? null
                            : () => context.push(AppRoutes.forgotPassword),
                        child: Text(
                          'Forgot Password?',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: isLoading ? null : _onLogin,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(double.infinity, 54),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Login',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: isLoading
                          ? null
                          : () => context.go(AppRoutes.register),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 54),
                        foregroundColor: colorScheme.onSurface,
                        side: BorderSide(
                          color: colorScheme.outline.withValues(alpha: 0.35),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Create Account',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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

  Widget _buildHeader(ThemeData theme) {
    return Column(
      children: [
        Image.asset(
          'assets/images/app_logo.png',
          height: 112,
        ),
        const SizedBox(height: 22),
        Text(
          'Velix',
          style: theme.textTheme.headlineLarge?.copyWith(
            fontSize: 40,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Connect Beyond Limits',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildIdentifierField(bool isLoading) {
    return TextFormField(
      controller: _identifierController,
      enabled: !isLoading,
      textInputAction: TextInputAction.next,
      keyboardType: TextInputType.text,
      autocorrect: false,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_@]')),
        TextInputFormatter.withFunction((oldValue, newValue) {
          // Fixed '@' prefix is visual only — never allow typed '@'.
          final cleaned = newValue.text.replaceAll('@', '');
          final cursor = newValue.selection.end;
          final removedBeforeCursor = '@'
              .allMatches(newValue.text.substring(0, cursor.clamp(0, newValue.text.length)))
              .length;
          final nextOffset =
              (cursor - removedBeforeCursor).clamp(0, cleaned.length);
          return TextEditingValue(
            text: cleaned,
            selection: TextSelection.collapsed(offset: nextOffset),
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
          return 'Enter your username or Velix User ID';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField(bool isLoading) {
    return TextFormField(
      controller: _passwordController,
      enabled: !isLoading,
      textInputAction: TextInputAction.done,
      obscureText: _obscurePassword,
      onFieldSubmitted: (_) {
        if (!isLoading) _onLogin();
      },
      decoration: InputDecoration(
        labelText: 'Password',
        hintText: 'Enter your password',
        prefixIcon: const Icon(Icons.lock_outline_rounded),
        suffixIcon: IconButton(
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
          icon: Icon(
            _obscurePassword
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
          ),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Enter your password';
        }
        return null;
      },
    );
  }
}

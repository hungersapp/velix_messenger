import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_routes.dart';
import '../../domain/entities/registration_request.dart';
import '../../domain/services/password_rules.dart';
import '../../domain/services/username_rules.dart';
import '../models/account_created_args.dart';
import '../providers/auth_provider.dart';

/// Velix V1 registration UI.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _ageConfirmed = false;
  bool _termsAccepted = false;

  UsernameAvailability _usernameAvailability = UsernameAvailability.idle;
  Timer? _usernameDebounce;
  int _usernameCheckToken = 0;

  late final TapGestureRecognizer _termsRecognizer;
  late final TapGestureRecognizer _privacyRecognizer;

  @override
  void initState() {
    super.initState();
    _termsRecognizer = TapGestureRecognizer()
      ..onTap = () => context.push(AppRoutes.terms);
    _privacyRecognizer = TapGestureRecognizer()
      ..onTap = () => context.push(AppRoutes.privacy);
  }

  @override
  void dispose() {
    _usernameDebounce?.cancel();
    _termsRecognizer.dispose();
    _privacyRecognizer.dispose();
    _displayNameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String get _storedUsername =>
      UsernameRules.normalize(_usernameController.text);

  bool get _isDisplayNameValid {
    final name = _displayNameController.text.trim();
    return name.isNotEmpty && name.length <= 40;
  }

  bool get _isUsernameValid => UsernameRules.isValid(_storedUsername);

  bool get _isPasswordStrong =>
      PasswordRules.isValid(_passwordController.text) &&
      PasswordRules.strengthOf(_passwordController.text) ==
          PasswordStrength.strong;

  bool get _doPasswordsMatch {
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;
    return password.isNotEmpty && password == confirm;
  }

  bool _isReadyToSubmit(bool isLoading) {
    return !isLoading &&
        _isDisplayNameValid &&
        _isUsernameValid &&
        _usernameAvailability == UsernameAvailability.available &&
        _isPasswordStrong &&
        _doPasswordsMatch &&
        _ageConfirmed &&
        _termsAccepted;
  }

  void _onUsernameChanged(String value) {
    _usernameDebounce?.cancel();

    final normalized = UsernameRules.normalize(value);
    if (!UsernameRules.isValid(normalized)) {
      setState(() {
        _usernameAvailability = value.trim().isEmpty
            ? UsernameAvailability.idle
            : UsernameAvailability.invalid;
      });
      return;
    }

    setState(() {
      _usernameAvailability = UsernameAvailability.checking;
    });

    final token = ++_usernameCheckToken;
    _usernameDebounce = Timer(const Duration(milliseconds: 450), () async {
      final result =
          await ref.read(authProvider.notifier).checkUsername(normalized);
      if (!mounted || token != _usernameCheckToken) return;
      setState(() {
        _usernameAvailability = result;
      });
    });
  }

  Future<void> _onCreateAccount() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    if (!_isReadyToSubmit(ref.read(authProvider).isLoading)) return;

    final displayName = _displayNameController.text.trim();
    final username = _storedUsername;
    final password = _passwordController.text;

    final result = await ref.read(authProvider.notifier).register(
          RegistrationRequest(
            displayName: displayName,
            username: username,
            password: password,
            ageConfirmed: _ageConfirmed,
          ),
        );

    if (!mounted) return;

    if (result == null) {
      final error = ref.read(authProvider).error;
      _showMessage(_errorText(error));
      return;
    }

    context.go(
      AppRoutes.accountCreated,
      extra: AccountCreatedArgs(
        displayName: displayName,
        username: username,
        velixId: result.velixId,
        recoverySecurityKey: result.recoverySecurityKey,
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _errorText(Object? error) {
    if (error == null) return 'Registration failed';
    return error.toString().replaceFirst('Exception: ', '');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final width = MediaQuery.sizeOf(context).width;
    final horizontalPadding = width >= 600 ? 48.0 : 28.0;
    final isLoading = ref.watch(authProvider).isLoading;
    final password = _passwordController.text;

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
                    const SizedBox(height: 32),
                    _buildDisplayNameField(isLoading),
                    const SizedBox(height: 16),
                    _buildUsernameField(isLoading),
                    _buildUsernameAvailability(theme),
                    const SizedBox(height: 16),
                    _buildPasswordField(isLoading),
                    const SizedBox(height: 10),
                    _PasswordStrengthIndicator(password: password),
                    const SizedBox(height: 16),
                    _buildConfirmPasswordField(isLoading),
                    const SizedBox(height: 18),
                    _buildAgeConfirmation(theme, isLoading),
                    const SizedBox(height: 4),
                    _buildTermsConfirmation(theme, isLoading),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _isReadyToSubmit(isLoading)
                          ? _onCreateAccount
                          : null,
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
                              'Create Account',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                    const SizedBox(height: 14),
                    TextButton(
                      onPressed: isLoading
                          ? null
                          : () => context.go(AppRoutes.login),
                      child: Text(
                        'Already have an account? Login',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.primary,
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
          height: 96,
        ),
        const SizedBox(height: 20),
        Text(
          'Create Account',
          style: theme.textTheme.headlineLarge?.copyWith(
            fontSize: 30,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Choose a username. We generate your permanent Velix User ID.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildDisplayNameField(bool isLoading) {
    return TextFormField(
      controller: _displayNameController,
      enabled: !isLoading,
      textInputAction: TextInputAction.next,
      textCapitalization: TextCapitalization.words,
      maxLength: 40,
      onChanged: (_) => setState(() {}),
      decoration: const InputDecoration(
        labelText: 'Display Name',
        hintText: 'How you appear to others',
        prefixIcon: Icon(Icons.badge_outlined),
        counterText: '',
      ),
      validator: (value) {
        final name = value?.trim() ?? '';
        if (name.isEmpty) return 'Enter your display name';
        if (name.length > 40) return 'Maximum 40 characters';
        return null;
      },
    );
  }

  Widget _buildUsernameField(bool isLoading) {
    return TextFormField(
      controller: _usernameController,
      enabled: !isLoading,
      textInputAction: TextInputAction.next,
      keyboardType: TextInputType.text,
      autocorrect: false,
      onChanged: (value) {
        _onUsernameChanged(value);
        setState(() {});
      },
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_]')),
        TextInputFormatter.withFunction((oldValue, newValue) {
          return newValue.copyWith(
            text: newValue.text.toLowerCase(),
            selection: newValue.selection,
          );
        }),
      ],
      decoration: const InputDecoration(
        labelText: 'Username',
        hintText: 'username',
        prefixText: '@ ',
        prefixIcon: Icon(Icons.alternate_email_rounded),
        helperText: '3–20 characters · lowercase · numbers · underscore',
      ),
      validator: (value) {
        final normalized = UsernameRules.normalize(value ?? '');
        if (!UsernameRules.isValid(normalized)) {
          return 'Enter a valid username (3–20 characters)';
        }
        if (_usernameAvailability == UsernameAvailability.taken) {
          return 'Username already taken';
        }
        return null;
      },
    );
  }

  Widget _buildUsernameAvailability(ThemeData theme) {
    switch (_usernameAvailability) {
      case UsernameAvailability.idle:
      case UsernameAvailability.invalid:
        return const SizedBox(height: 4);
      case UsernameAvailability.checking:
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            children: [
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Checking username…',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        );
      case UsernameAvailability.available:
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            '🟢 Username Available',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF1B7F3A),
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      case UsernameAvailability.taken:
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            '🔴 Username Already Taken',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
    }
  }

  Widget _buildPasswordField(bool isLoading) {
    return TextFormField(
      controller: _passwordController,
      enabled: !isLoading,
      textInputAction: TextInputAction.next,
      obscureText: _obscurePassword,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        labelText: 'Password',
        hintText: 'Create a strong password',
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
        final password = value ?? '';
        final error = PasswordRules.validationError(password);
        if (error != null) return error;
        if (PasswordRules.strengthOf(password) != PasswordStrength.strong) {
          return 'Use at least 12 characters to reach Strong';
        }
        return null;
      },
    );
  }

  Widget _buildConfirmPasswordField(bool isLoading) {
    return TextFormField(
      controller: _confirmPasswordController,
      enabled: !isLoading,
      textInputAction: TextInputAction.done,
      obscureText: _obscureConfirmPassword,
      onChanged: (_) => setState(() {}),
      onFieldSubmitted: (_) {
        if (_isReadyToSubmit(ref.read(authProvider).isLoading)) {
          _onCreateAccount();
        }
      },
      decoration: InputDecoration(
        labelText: 'Confirm Password',
        hintText: 'Re-enter your password',
        prefixIcon: const Icon(Icons.lock_outline_rounded),
        suffixIcon: IconButton(
          onPressed: () {
            setState(() {
              _obscureConfirmPassword = !_obscureConfirmPassword;
            });
          },
          icon: Icon(
            _obscureConfirmPassword
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
    );
  }

  Widget _buildAgeConfirmation(ThemeData theme, bool isLoading) {
    return _CheckboxRow(
      value: _ageConfirmed,
      enabled: !isLoading,
      onChanged: (value) {
        setState(() {
          _ageConfirmed = value;
        });
      },
      child: Text(
        'I confirm that I am 18 years or older.',
        style: theme.textTheme.bodyMedium,
      ),
    );
  }

  Widget _buildTermsConfirmation(ThemeData theme, bool isLoading) {
    final linkStyle = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.primary,
      fontWeight: FontWeight.w700,
      decoration: TextDecoration.underline,
      decorationColor: theme.colorScheme.primary,
    );

    return _CheckboxRow(
      value: _termsAccepted,
      enabled: !isLoading,
      onChanged: (value) {
        setState(() {
          _termsAccepted = value;
        });
      },
      child: Text.rich(
        TextSpan(
          style: theme.textTheme.bodyMedium,
          children: [
            const TextSpan(
              text: 'I have read and agree to the ',
            ),
            TextSpan(
              text: 'Terms & Conditions',
              style: linkStyle,
              recognizer: _termsRecognizer,
            ),
            const TextSpan(text: ' and '),
            TextSpan(
              text: 'Privacy Policy',
              style: linkStyle,
              recognizer: _privacyRecognizer,
            ),
            const TextSpan(text: '.'),
          ],
        ),
      ),
    );
  }
}

class _CheckboxRow extends StatelessWidget {
  const _CheckboxRow({
    required this.value,
    required this.enabled,
    required this.onChanged,
    required this.child,
  });

  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: enabled ? () => onChanged(!value) : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: value,
            onChanged: enabled
                ? (checked) => onChanged(checked ?? false)
                : null,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 12, right: 8),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

class _PasswordStrengthIndicator extends StatelessWidget {
  const _PasswordStrengthIndicator({required this.password});

  final String password;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strength = PasswordRules.strengthOf(password);
    final label = switch (strength) {
      PasswordStrength.weak => 'Weak',
      PasswordStrength.fair => 'Fair',
      PasswordStrength.good => 'Good',
      PasswordStrength.strong => 'Strong',
    };
    final color = switch (strength) {
      PasswordStrength.weak => theme.colorScheme.error,
      PasswordStrength.fair => const Color(0xFFD97706),
      PasswordStrength.good => const Color(0xFF2563EB),
      PasswordStrength.strong => const Color(0xFF1B7F3A),
    };
    final progress = switch (strength) {
      PasswordStrength.weak => 0.25,
      PasswordStrength.fair => 0.5,
      PasswordStrength.good => 0.75,
      PasswordStrength.strong => 1.0,
    };

    if (password.isEmpty) {
      return Text(
        'Use 12+ characters with upper, lower, number, and special character.',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            color: color,
          ),
        ),
        const SizedBox(height: 6),
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: (theme.textTheme.bodySmall ?? const TextStyle()).copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
          child: Text('Password strength: $label'),
        ),
      ],
    );
  }
}

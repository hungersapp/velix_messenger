import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../user/presentation/providers/current_user_provider.dart';
import '../providers/settings_feature_providers.dart';

class TwoFactorSettingsScreen extends ConsumerStatefulWidget {
  const TwoFactorSettingsScreen({super.key});

  @override
  ConsumerState<TwoFactorSettingsScreen> createState() =>
      _TwoFactorSettingsScreenState();
}

class _TwoFactorSettingsScreenState
    extends ConsumerState<TwoFactorSettingsScreen> {
  final _otpController = TextEditingController();
  String? _pendingSecret;
  bool _busy = false;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabledAsync = ref.watch(twoFactorEnabledProvider);
    final theme = Theme.of(context);
    final enabled = enabledAsync.valueOrNull ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Two-Factor Authentication'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            enabled
                ? 'Two-factor authentication is enabled. Sign-in and recovery will require a Google Authenticator code.'
                : 'Add an extra layer of security with Google Authenticator (TOTP), using the existing Velix auth architecture.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          if (_pendingSecret != null) ...[
            SelectableText(
              _pendingSecret!,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add this secret in Google Authenticator, then enter a 6-digit code to confirm.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Authenticator code',
              ),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _busy ? null : _confirmEnable,
              child: const Text('Confirm & Enable'),
            ),
          ] else if (enabled) ...[
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Authenticator code to disable',
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _busy ? null : _disable,
              child: const Text('Disable 2FA'),
            ),
          ] else
            FilledButton(
              onPressed: _busy ? null : _beginEnable,
              child: const Text('Enable 2FA'),
            ),
        ],
      ),
    );
  }

  Future<void> _beginEnable() async {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;
    setState(() => _busy = true);
    try {
      final secret = await ref
          .read(settingsRepositoryProvider)
          .beginTwoFactorEnrollment(user.uid);
      setState(() => _pendingSecret = secret);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmEnable() async {
    final user = ref.read(currentUserProvider).valueOrNull;
    final secret = _pendingSecret;
    if (user == null || secret == null) return;
    setState(() => _busy = true);
    try {
      await ref.read(settingsRepositoryProvider).confirmTwoFactor(
            userId: user.uid,
            secret: secret,
            otp: _otpController.text,
          );
      _otpController.clear();
      setState(() => _pendingSecret = null);
      ref.invalidate(twoFactorEnabledProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Two-factor authentication enabled')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _disable() async {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;
    setState(() => _busy = true);
    try {
      await ref.read(settingsRepositoryProvider).disableTwoFactor(
            userId: user.uid,
            otp: _otpController.text,
          );
      _otpController.clear();
      ref.invalidate(twoFactorEnabledProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Two-factor authentication disabled')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

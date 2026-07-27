import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/security/secure_storage_providers.dart';
import '../../../../core/security/secure_storage_service.dart';
import '../../domain/entities/recovery_account.dart';
import '../../domain/usecases/find_account_for_recovery_usecase.dart';
import '../../domain/usecases/reset_password_usecase.dart';
import '../../domain/usecases/verify_recovery_key_usecase.dart';
import '../../domain/usecases/verify_totp_usecase.dart';
import 'auth_provider.dart';

enum PasswordRecoveryStep {
  identifier,
  recoveryKey,
  totp,
  newPassword,
  success,
}

class PasswordRecoveryState {
  const PasswordRecoveryState({
    this.step = PasswordRecoveryStep.identifier,
    this.account,
    this.recoverySecurityKey = '',
    this.recoveryKeyVerified = false,
    this.totpVerified = false,
    this.isLoading = false,
    this.errorMessage,
  });

  final PasswordRecoveryStep step;
  final RecoveryAccount? account;

  /// Held in memory only for the active recovery flow — never written to disk.
  final String recoverySecurityKey;
  final bool recoveryKeyVerified;
  final bool totpVerified;
  final bool isLoading;
  final String? errorMessage;

  PasswordRecoveryState copyWith({
    PasswordRecoveryStep? step,
    RecoveryAccount? account,
    String? recoverySecurityKey,
    bool? recoveryKeyVerified,
    bool? totpVerified,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    bool clearAccount = false,
  }) {
    return PasswordRecoveryState(
      step: step ?? this.step,
      account: clearAccount ? null : (account ?? this.account),
      recoverySecurityKey:
          recoverySecurityKey ?? this.recoverySecurityKey,
      recoveryKeyVerified:
          recoveryKeyVerified ?? this.recoveryKeyVerified,
      totpVerified: totpVerified ?? this.totpVerified,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

final findAccountForRecoveryUseCaseProvider =
    Provider<FindAccountForRecoveryUseCase>((ref) {
  return FindAccountForRecoveryUseCase(ref.read(authRepositoryProvider));
});

final verifyRecoveryKeyUseCaseProvider =
    Provider<VerifyRecoveryKeyUseCase>((ref) {
  return VerifyRecoveryKeyUseCase(ref.read(authRepositoryProvider));
});

final verifyTotpUseCaseProvider = Provider<VerifyTotpUseCase>((ref) {
  return VerifyTotpUseCase(ref.read(authRepositoryProvider));
});

final resetPasswordUseCaseProvider = Provider<ResetPasswordUseCase>((ref) {
  return ResetPasswordUseCase(ref.read(authRepositoryProvider));
});

final passwordRecoveryProvider = StateNotifierProvider.autoDispose<
    PasswordRecoveryNotifier, PasswordRecoveryState>((ref) {
  return PasswordRecoveryNotifier(
    findAccount: ref.read(findAccountForRecoveryUseCaseProvider),
    verifyRecoveryKey: ref.read(verifyRecoveryKeyUseCaseProvider),
    verifyTotp: ref.read(verifyTotpUseCaseProvider),
    resetPassword: ref.read(resetPasswordUseCaseProvider),
    secureStorage: ref.read(secureStorageServiceProvider),
  );
});

class PasswordRecoveryNotifier extends StateNotifier<PasswordRecoveryState> {
  PasswordRecoveryNotifier({
    required this.findAccount,
    required this.verifyRecoveryKey,
    required this.verifyTotp,
    required this.resetPassword,
    required this.secureStorage,
  }) : super(const PasswordRecoveryState());

  final FindAccountForRecoveryUseCase findAccount;
  final VerifyRecoveryKeyUseCase verifyRecoveryKey;
  final VerifyTotpUseCase verifyTotp;
  final ResetPasswordUseCase resetPassword;
  final SecureStorageService secureStorage;

  Future<void> _persistProgress() async {
    final account = state.account;
    if (account == null) return;
    await secureStorage.saveRecoveryProgress(
      uid: account.uid,
      velixId: account.velixId,
      username: account.username,
      step: state.step.name,
      twoStepEnabled: account.twoStepVerificationEnabled,
      recoveryKeyVerified: state.recoveryKeyVerified,
      totpVerified: state.totpVerified,
    );
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  Future<void> reset() async {
    state = const PasswordRecoveryState();
    await secureStorage.clearRecoveryProgress();
  }

  Future<bool> submitIdentifier(String identifier) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final account = await findAccount(identifier);
      state = state.copyWith(
        isLoading: false,
        account: account,
        step: PasswordRecoveryStep.recoveryKey,
        recoveryKeyVerified: false,
        totpVerified: false,
        recoverySecurityKey: '',
      );
      await _persistProgress();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _message(e),
      );
      return false;
    }
  }

  Future<bool> submitRecoveryKey(String recoverySecurityKey) async {
    final account = state.account;
    if (account == null) {
      state = state.copyWith(errorMessage: 'Account not found');
      return false;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await verifyRecoveryKey(
        velixId: account.velixId,
        recoverySecurityKey: recoverySecurityKey,
      );

      final nextStep = account.twoStepVerificationEnabled
          ? PasswordRecoveryStep.totp
          : PasswordRecoveryStep.newPassword;

      state = state.copyWith(
        isLoading: false,
        // Memory only — never persisted to secure storage.
        recoverySecurityKey: recoverySecurityKey.trim(),
        recoveryKeyVerified: true,
        step: nextStep,
      );
      await _persistProgress();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _message(e),
      );
      return false;
    }
  }

  Future<bool> submitTotp(String otp) async {
    final account = state.account;
    if (account == null) {
      state = state.copyWith(errorMessage: 'Account not found');
      return false;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await verifyTotp(velixId: account.velixId, otp: otp);
      state = state.copyWith(
        isLoading: false,
        totpVerified: true,
        step: PasswordRecoveryStep.newPassword,
      );
      await _persistProgress();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _message(e),
      );
      return false;
    }
  }

  Future<bool> submitNewPassword(String newPassword) async {
    final account = state.account;
    if (account == null) {
      state = state.copyWith(errorMessage: 'Account not found');
      return false;
    }
    if (!state.recoveryKeyVerified || state.recoverySecurityKey.isEmpty) {
      state = state.copyWith(errorMessage: 'Invalid Recovery Security Key');
      return false;
    }
    if (account.twoStepVerificationEnabled && !state.totpVerified) {
      state = state.copyWith(
        errorMessage: 'Invalid Google Authenticator OTP',
      );
      return false;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await resetPassword(
        velixId: account.velixId,
        recoverySecurityKey: state.recoverySecurityKey,
        newPassword: newPassword,
      );
      state = state.copyWith(
        isLoading: false,
        step: PasswordRecoveryStep.success,
        recoverySecurityKey: '',
      );
      await secureStorage.clearRecoveryProgress();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _message(e),
      );
      return false;
    }
  }

  String _message(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }
}

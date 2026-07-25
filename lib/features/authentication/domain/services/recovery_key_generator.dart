import 'dart:math';

/// Generates a one-time Recovery Security Key: `RK-7FQ9-KP4M-ZX82`.
class RecoveryKeyGenerator {
  RecoveryKeyGenerator({Random? random}) : _random = random ?? Random.secure();

  final Random _random;

  static const _alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  String generate() {
    String segment() => List.generate(
          4,
          (_) => _alphabet[_random.nextInt(_alphabet.length)],
        ).join();

    return 'RK-${segment()}-${segment()}-${segment()}';
  }
}

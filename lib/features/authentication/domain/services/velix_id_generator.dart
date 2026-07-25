import 'dart:math';

/// Builds a permanent Velix User ID: `@{username}_VX{7 alphanumeric}`.
class VelixIdGenerator {
  VelixIdGenerator({Random? random}) : _random = random ?? Random.secure();

  final Random _random;

  static const _alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

  /// [username] must include the leading `@`, e.g. `@murali007`.
  String generate(String username) {
    final suffix = List.generate(
      7,
      (_) => _alphabet[_random.nextInt(_alphabet.length)],
    ).join();

    return '${username}_VX$suffix';
  }
}

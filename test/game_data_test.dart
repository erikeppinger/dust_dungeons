import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The generated catalog, texts and art must match game/*.toml and
/// assets/art, and the tool's own checks must pass: if this fails, run
/// `python tool/build_game_data.py`.
void main() {
  Future<ProcessResult> python(List<String> args) async {
    for (final exe in ['python3', 'python']) {
      try {
        final result = await Process.run(exe, args);
        // Windows has a `python3` stub that only opens the Store.
        if (result.exitCode != 9009) return result;
      } on ProcessException {
        // Try the next name.
      }
    }
    fail('Python 3.11+ is needed for the game data tool');
  }

  test('generated game data is up to date', () async {
    final result = await python(['tool/build_game_data.py', '--check']);
    expect(result.exitCode, 0, reason: '${result.stdout}${result.stderr}');
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('the tool rejects broken data', () async {
    final result = await python([
      '-m',
      'unittest',
      'tool/test_build_game_data.py',
    ]);
    expect(result.exitCode, 0, reason: '${result.stdout}${result.stderr}');
  });
}

import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:homework_and_chores/app/art/art.dart';

/// The generated `lib/app/art/art.g.dart` must match the PNG and palette
/// files in `assets/art`: if this fails, run `python tool/build_art.py`.
void main() {
  const digits =
      '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
  final manifest = jsonDecode(
    File('assets/art/art.json').readAsStringSync(),
  ) as Map<String, dynamic>;

  /// (r, g, b) values of a GIMP palette, in file order.
  List<(int, int, int)> readGpl(String name) => [
    for (final line in File(
      'assets/art/palettes/$name.gpl',
    ).readAsLinesSync().skip(1))
      if (RegExp(r'^\s*\d+\s+\d+\s+\d+').hasMatch(line))
        () {
          final p = line.trim().split(RegExp(r'\s+'));
          return (int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
        }(),
  ];

  test('generated palettes match the .gpl files', () {
    final groups = manifest['palettes'] as Map<String, dynamic>;
    for (final MapEntry(key: group, value: spec) in groups.entries) {
      for (final variant in (spec as Map)['variants'] as List) {
        final colors = paletteGroups[group]![variant]!;
        expect(
          [for (final c in colors) (c.r * 255, c.g * 255, c.b * 255)],
          [
            for (final (r, g, b) in readGpl(variant as String))
              (r.toDouble(), g.toDouble(), b.toDouble()),
          ],
          reason: '$variant.gpl',
        );
      }
    }
  });

  testWidgets('generated sprites match the PNG files', (tester) async {
    final sprites = manifest['sprites'] as Map<String, dynamic>;
    final groups = manifest['palettes'] as Map<String, dynamic>;
    expect(Sprites.all.keys, sprites.keys);
    for (final MapEntry(key: name, value: spec as Map) in sprites.entries) {
      final source = readGpl(
        (groups[spec['palette']] as Map)['source'] as String,
      );
      final variants = spec['variants'] as int?;
      final frames = (spec['frames'] as int?) ?? 1;
      final [w, h] = (spec['size'] as List).cast<int>();
      final files = variants == null
          ? ['assets/art/$name.png']
          : [for (var i = 0; i < variants; i++) 'assets/art/${name}_$i.png'];
      final expected = <List<String>>[];
      for (final file in files) {
        final rgba = await tester.runAsync(() async {
          final codec = await ui.instantiateImageCodec(
            File(file).readAsBytesSync(),
          );
          final image = (await codec.getNextFrame()).image;
          expect((image.width, image.height), (w * frames, h), reason: file);
          final data = await image.toByteData();
          image.dispose();
          return data!;
        });
        final rows = [
          for (var y = 0; y < h; y++)
            [
              for (var x = 0; x < w * frames; x++)
                () {
                  final i = (y * w * frames + x) * 4;
                  if (rgba!.getUint8(i + 3) == 0) return '.';
                  final index = source.indexOf((
                    rgba.getUint8(i),
                    rgba.getUint8(i + 1),
                    rgba.getUint8(i + 2),
                  ));
                  expect(index, isNonNegative, reason: '$file ($x, $y)');
                  return digits[index];
                }(),
            ].join(),
        ];
        for (var f = 0; f < frames; f++) {
          expected.add([for (final r in rows) r.substring(f * w, (f + 1) * w)]);
        }
      }
      expect(
        [for (final s in Sprites.all[name]!.$1) s.rows],
        expected,
        reason: '$name: run python tool/build_art.py',
      );
    }
  });
}

import 'dart:ui';

import 'package:flutter/foundation.dart';

part 'art_data.dart';

/// One picture of pixel art, generated from a PNG in `assets/art` by
/// `tool/build_art.py`. Each row has one character per pixel: `.` is
/// transparent, any other is an index into the palette it's painted with,
/// so the same sprite can be painted in every palette of its group (map
/// seasons, day and night).
@immutable
class Sprite {
  const Sprite(this.rows);

  final List<String> rows;

  int get width => rows.first.length;
  int get height => rows.length;

  static const _digits =
      '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';

  /// Paints the sprite with its top left at [offset], one canvas unit per
  /// pixel. Recorded once per palette and replayed after that.
  void paint(
    Canvas canvas,
    List<Color> palette, [
    Offset offset = Offset.zero,
  ]) {
    final key = _Key(this, palette);
    var picture = _pictures[key];
    if (picture == null) {
      // Tints animate through many colors while the theme changes; start
      // over instead of keeping them all. Pictures already drawn stay
      // valid, they're only no longer reused.
      if (_pictures.length >= _maxPictures) _pictures.clear();
      picture = _pictures[key] = _record(palette);
    }
    if (offset == Offset.zero) {
      canvas.drawPicture(picture);
    } else {
      canvas
        ..save()
        ..translate(offset.dx, offset.dy)
        ..drawPicture(picture)
        ..restore();
    }
  }

  Picture _record(List<Color> palette) {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()..isAntiAlias = false;
    for (var y = 0; y < rows.length; y++) {
      final row = rows[y];
      var x = 0;
      while (x < row.length) {
        final ch = row[x];
        var end = x + 1;
        // Runs of one color become one rectangle.
        while (end < row.length && row[end] == ch) {
          end++;
        }
        if (ch != '.') {
          paint.color = palette[_digits.indexOf(ch)];
          canvas.drawRect(
            Rect.fromLTWH(x.toDouble(), y.toDouble(), (end - x).toDouble(), 1),
            paint,
          );
        }
        x = end;
      }
    }
    return recorder.endRecording();
  }

  // Every sprite in every palette of its group is about 100 pictures, plus
  // a few tints for icons.
  static final _pictures = <_Key, Picture>{};
  static const _maxPictures = 256;
}

class _Key {
  _Key(this.sprite, this.palette);

  final Sprite sprite;
  final List<Color> palette;

  @override
  bool operator ==(Object other) =>
      other is _Key &&
      identical(other.sprite, sprite) &&
      listEquals(other.palette, palette);

  @override
  int get hashCode =>
      Object.hash(identityHashCode(sprite), Object.hashAll(palette));
}

import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/art/art.dart';
import '../../app/theme/app_theme.dart';
import '../../app/theme/chore_palette.dart';
import '../../app/theme/pixel.dart';
import '../../l10n/app_localizations.dart';
import 'widget_quests.dart';

/// The three home screen widgets (docs/design/scheduling.md). The name is
/// part of the picture's file name, which the Android side reads.
enum WidgetStyle {
  /// Quest board: icon tiles in rows, with badges.
  board(320, 176),

  /// Board-game path: tiles joined by arrows.
  path(320, 150),

  /// The next quest large, the following ones small.
  next(320, 150);

  const WidgetStyle(this.width, this.height);

  /// Logical size; pictures are drawn at [WidgetArt.scale] times this.
  final double width, height;
}

/// The colors of one look (day or night), taken from the app's theme so the
/// widget matches the app.
class WidgetLook {
  WidgetLook(Brightness brightness, {required bool colorblindSafe})
    : this._(
        buildAppTheme(brightness: brightness, colorblindSafe: colorblindSafe),
      );

  WidgetLook._(ThemeData theme)
    : scheme = theme.colorScheme,
      pixels = theme.extension<PixelColors>()!,
      chores = theme.extension<ChorePalette>()!;

  final ColorScheme scheme;
  final PixelColors pixels;
  final ChorePalette chores;
}

/// Draws a widget picture as PNG bytes.
class WidgetArt {
  WidgetArt({
    required this.l10n,
    required this.look,
    required this.person,
    required this.points,
    required this.today,
  }) : _weekday = DateFormat.E(l10n.localeName),
       _date = DateFormat.Md(l10n.localeName);

  final AppLocalizations l10n;
  final WidgetLook look;
  final String person;
  final int points;

  /// The day the pictures are for: later days within a week of it show as
  /// a weekday, others as a date.
  final DateTime today;
  final DateFormat _weekday;
  final DateFormat _date;

  static const scale = 3.0;

  ColorScheme get _s => look.scheme;

  Future<Uint8List> render(WidgetStyle style, List<WidgetQuest> quests) =>
      _png(style.width, style.height, (c) {
        _panel(c, style);
        switch (style) {
          case WidgetStyle.board:
            _board(c, quests);
          case WidgetStyle.path:
            _path(c, quests);
          case WidgetStyle.next:
            _next(c, quests);
        }
      });

  /// The list of all quests is a real, scrolling list on the Android side,
  /// built from pictures: this heading, and one picture per row. Each has
  /// the panel's color behind it, so it stays readable while Android still
  /// shows day pictures on its night panel (or the other way round), until
  /// the widget is next refreshed.
  static const listWidth = 320.0, listHeaderHeight = 32.0, listRowHeight = 36.0;

  Future<Uint8List> renderListHeader() =>
      _png(listWidth, listHeaderHeight, (c) {
        _listPanel(c, listHeaderHeight);
        _header(c, '${l10n.widgetListTitle} · $person', listWidth);
        c.drawRect(
          const Rect.fromLTWH(10, 29, listWidth - 20, 2),
          Paint()..color = look.pixels.frame,
        );
      });

  /// A row of the list. With [done], as it looks once ticked off in the
  /// widget: faded, crossed out, and the badge offers to undo.
  Future<Uint8List> renderListRow(WidgetQuest q, {bool done = false}) =>
      _png(listWidth, listRowHeight, (c) {
        _listPanel(c, listRowHeight);
        _tile(c, const Rect.fromLTWH(12, 4, 28, 28), q, faded: done);
        final (bg, fg) = done
            ? (_s.surfaceContainerLowest, _s.onSurfaceVariant)
            : _colors(q.status);
        final badge = _badge(
          c,
          done ? '✓ ${l10n.undo}' : _badgeText(q),
          listWidth - 12,
          18,
          bg,
          fg,
          play: !done && q.status == WidgetStatus.now,
        );
        final title = _text(
          c,
          q.title,
          const Offset(48, 10),
          size: 14,
          color: done ? _s.onSurfaceVariant : null,
          maxWidth: listWidth - 48 - badge - 20,
        );
        if (done) {
          // Crossed out: done is never shown by color alone.
          c.drawRect(
            Rect.fromLTWH(48, 10 + title.height / 2, title.width, 1.5),
            Paint()..color = _s.onSurfaceVariant,
          );
        }
      });

  void _listPanel(Canvas c, double height) => c.drawRect(
    Rect.fromLTWH(0, 0, listWidth, height),
    Paint()..color = _s.surfaceContainerLow,
  );

  /// What a screen reader says for a row of the list.
  String listRowLabel(WidgetQuest q) =>
      '${q.title}, ${_statusLine(q)}, ${l10n.pointsValue(q.points)}';

  /// The same for a row ticked off in the widget.
  String listRowDoneLabel(WidgetQuest q) =>
      l10n.widgetRowDone(q.title, l10n.undo);

  Future<Uint8List> _png(
    double width,
    double height,
    void Function(Canvas c) draw,
  ) async {
    final recorder = ui.PictureRecorder();
    final c = Canvas(recorder)..scale(scale);
    draw(c);
    final image = await recorder.endRecording().toImage(
      (width * scale).round(),
      (height * scale).round(),
    );
    try {
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      return png!.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  }

  // --- Building blocks -------------------------------------------------

  void _panel(Canvas c, WidgetStyle style) {
    final r = Rect.fromLTWH(0, 0, style.width, style.height);
    c.drawRect(r, Paint()..color = _s.surfaceContainerLow);
    // Light top-left and shaded bottom-right edge, then the ink frame.
    final inner = r.deflate(3);
    c
      ..drawRect(
        Rect.fromLTWH(inner.left, inner.top, inner.width, 2),
        Paint()..color = const Color(0x40FFFFFF),
      )
      ..drawRect(
        Rect.fromLTWH(inner.left, inner.bottom - 3, inner.width, 3),
        Paint()..color = const Color(0x26000000),
      )
      ..drawRect(
        r.deflate(1.5),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = look.pixels.frame,
      );
  }

  /// Draws [text] with its top left at [at]; returns its size.
  Size _text(
    Canvas c,
    String text,
    Offset at, {
    double size = 13,
    Color? color,
    bool pixel = false,
    double maxWidth = 1000,
    bool bold = false,
    TextAlign align = TextAlign.left,
    String? fontFamily,
  }) {
    final family = fontFamily ?? (pixel ? pixelFont : null);
    final builder =
        ui.ParagraphBuilder(
            ui.ParagraphStyle(
              fontFamily: family,
              fontSize: size,
              maxLines: 1,
              ellipsis: '…',
              textAlign: align,
            ),
          )
          ..pushStyle(
            ui.TextStyle(
              color: color ?? _s.onSurface,
              fontFamily: family,
              fontSize: size,
              fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
            ),
          )
          ..addText(text);
    final p = builder.build()..layout(ui.ParagraphConstraints(width: maxWidth));
    c.drawParagraph(p, at);
    return Size(p.longestLine, p.height);
  }

  /// The heading: [title] in the pixel font, and the coin with points.
  void _header(
    Canvas c,
    String title,
    double width, {
    Color? color,
    bool arrow = false,
  }) {
    final coin = '$points';
    final coinWidth = _measure(coin, 9, pixel: true);
    final drawn = _text(
      c,
      title.toUpperCase(),
      const Offset(12, 11),
      size: 9,
      pixel: true,
      color: color ?? _s.primary,
      maxWidth: width - coinWidth - 60,
    );
    if (arrow) {
      _triangle(c, Offset(12 + drawn.width + 6, 15.5), 9, color ?? _s.primary);
    }
    c.save();
    c.translate(width - coinWidth - 32, 8);
    c.scale(14 / 12);
    Sprites.coin.paint(c, look.pixels.palette.colors);
    c.restore();
    _text(c, coin, Offset(width - coinWidth - 14, 11), size: 9, pixel: true);
  }

  double _measure(String text, double size, {bool pixel = false}) {
    final b =
        ui.ParagraphBuilder(
            ui.ParagraphStyle(
              fontFamily: pixel ? pixelFont : null,
              fontSize: size,
            ),
          )
          ..pushStyle(
            ui.TextStyle(fontFamily: pixel ? pixelFont : null, fontSize: size),
          )
          ..addText(text);
    return (b.build()..layout(const ui.ParagraphConstraints(width: 1000)))
        .longestLine;
  }

  /// A quest's icon tile: its color, an ink frame, the icon.
  void _tile(Canvas c, Rect r, WidgetQuest q, {bool faded = false}) {
    final fill = look.chores.colorFor(q.colorKey);
    c.drawRect(r, Paint()..color = faded ? fill.withValues(alpha: 0.55) : fill);
    c.drawRect(
      r.deflate(1),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = look.pixels.frame,
    );
    // The pixel icon by whole pixels, centered, in the tile's ink.
    final sprite = q.icon;
    final cell = max(1, (r.height * 0.6 / sprite.height).floorToDouble());
    c
      ..save()
      ..translate(
        (r.center.dx - cell * sprite.width / 2).roundToDouble(),
        (r.center.dy - cell * sprite.height / 2).roundToDouble(),
      )
      ..scale(cell.toDouble());
    sprite.paint(c, [look.chores.onColorFor(q.colorKey)]);
    c.restore();
  }

  /// A pixel triangle pointing right, [size] tall, with its left edge at
  /// [at] and centered on its y. Drawn rather than a "▶" character: the
  /// phone's font may not have one, and Android then shows an emoji.
  void _triangle(Canvas c, Offset at, double size, Color color) {
    // Hard edges (no smoothing), so it reads as pixel art.
    final w = size * 0.9;
    c.drawPath(
      Path()
        ..moveTo(at.dx, at.dy - size / 2)
        ..lineTo(at.dx + w, at.dy)
        ..lineTo(at.dx, at.dy + size / 2)
        ..close(),
      Paint()
        ..color = color
        ..isAntiAlias = false,
    );
  }

  /// A badge ending at [right], centered on [cy]; returns its width. With
  /// [play], a triangle comes before the text.
  double _badge(
    Canvas c,
    String text,
    double right,
    double cy,
    Color bg,
    Color fg, {
    bool play = false,
  }) {
    final lead = play ? 13.0 : 0.0;
    final w = _measure(text, 11) + 12 + lead;
    final r = Rect.fromLTWH(right - w, cy - 10, w, 20);
    c.drawRect(r, Paint()..color = bg);
    c.drawRect(
      r.deflate(1),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = look.pixels.frame,
    );
    if (play) _triangle(c, Offset(r.left + 6, cy), 9, fg);
    _text(c, text, Offset(r.left + 6 + lead, cy - 7.5), size: 11, color: fg);
    return w;
  }

  String _time(int minutes) =>
      '${(minutes ~/ 60).toString().padLeft(2, '0')}:'
      '${(minutes % 60).toString().padLeft(2, '0')}';

  (Color, Color) _colors(WidgetStatus status) => switch (status) {
    WidgetStatus.late => (_s.errorContainer, _s.onErrorContainer),
    WidgetStatus.now => (_s.primaryContainer, _s.onPrimaryContainer),
    WidgetStatus.at => (_s.secondaryContainer, _s.onSecondaryContainer),
    WidgetStatus.upcoming ||
    WidgetStatus.anytime => (_s.surfaceContainerLowest, _s.onSurfaceVariant),
  };

  /// A later day: its weekday within a week of [today], else its date
  /// ("Thu", "24.11.").
  String _day(DateTime day) => day.difference(today).inDays.abs() < 7
      ? _weekday.format(day)
      : _date.format(day);

  /// The badge text: "! 2 days late", "▶ today", "18:00", "→ Thu".
  String _badgeText(WidgetQuest q) => switch (q.status) {
    WidgetStatus.late =>
      q.lateDays == 0 ? l10n.widgetTimeUp : l10n.widgetLate(q.lateDays),
    WidgetStatus.now => l10n.widgetToday,
    WidgetStatus.at => _time(q.atMinutes ?? 0),
    WidgetStatus.upcoming => '→ ${_day(q.day!)}',
    WidgetStatus.anytime => l10n.statusAnytime,
  };

  /// The longer line for the next-quest card.
  String _statusLine(WidgetQuest q) => switch (q.status) {
    WidgetStatus.late =>
      q.lateDays == 0 ? l10n.widgetTimeUp : l10n.statusOverdue(q.lateDays),
    WidgetStatus.now => l10n.statusDueToday,
    WidgetStatus.at => l10n.statusTodayFrom(_time(q.atMinutes ?? 0)),
    WidgetStatus.upcoming => '→ ${_day(q.day!)}',
    WidgetStatus.anytime => l10n.statusAnytime,
  };

  void _empty(Canvas c, double top, double width) => _text(
    c,
    l10n.widgetNothingOpen,
    Offset(12, top),
    size: 13,
    color: _s.onSurfaceVariant,
    maxWidth: width - 24,
  );

  // --- The three styles --------------------------------------------------

  void _board(Canvas c, List<WidgetQuest> quests) {
    const width = 320.0;
    _header(c, '${l10n.navToday} · $person', width);
    c.drawRect(
      const Rect.fromLTWH(10, 30, width - 20, 2),
      Paint()..color = look.pixels.frame,
    );
    if (quests.isEmpty) return _empty(c, 44, width);
    const rows = 4;
    final shown = quests.length > rows ? rows - 1 : quests.length;
    for (var i = 0; i < shown; i++) {
      final q = quests[i];
      final top = 38.0 + i * 34;
      _tile(c, Rect.fromLTWH(12, top, 28, 28), q);
      final (bg, fg) = _colors(q.status);
      final badge = _badge(
        c,
        _badgeText(q),
        width - 12,
        top + 14,
        bg,
        fg,
        play: q.status == WidgetStatus.now,
      );
      _text(
        c,
        q.title,
        Offset(48, top + 6),
        size: 14,
        maxWidth: width - 48 - badge - 20,
      );
    }
    if (quests.length > rows) {
      _text(
        c,
        l10n.widgetMore(quests.length - shown),
        Offset(48, 38.0 + shown * 34 + 6),
        size: 13,
        color: _s.onSurfaceVariant,
      );
    }
  }

  void _path(Canvas c, List<WidgetQuest> quests) {
    const width = 320.0;
    _header(c, l10n.widgetPathTitle(person), width);
    if (quests.isEmpty) return _empty(c, 44, width);
    const steps = 4, size = 44.0, gap = 28.0;
    final shown = quests.take(steps).toList();
    for (final (i, q) in shown.indexed) {
      final left = 14.0 + i * (size + gap);
      _tile(
        c,
        Rect.fromLTWH(left, 34, size, size),
        q,
        faded: q.status == WidgetStatus.upcoming,
      );
      if (q.status == WidgetStatus.late) {
        // Late tiles get a second, red frame: also marked "!" below.
        c.drawRect(
          Rect.fromLTWH(left - 3, 31, size + 6, size + 6),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3
            ..color = _s.error,
        );
      }
      final label = switch (q.status) {
        WidgetStatus.late => l10n.widgetPathLate(q.lateDays),
        WidgetStatus.now => l10n.widgetPathNow,
        WidgetStatus.at => _time(q.atMinutes ?? 0),
        WidgetStatus.upcoming => _weekday.format(q.day!),
        WidgetStatus.anytime => l10n.statusAnytime,
      };
      _text(
        c,
        label.toUpperCase(),
        Offset(left - gap / 2, 34 + size + 7),
        size: 7,
        pixel: true,
        maxWidth: size + gap,
        align: TextAlign.center,
        color: q.status == WidgetStatus.late ? _s.error : _s.onSurface,
      );
      if (i < shown.length - 1) {
        _triangle(
          c,
          Offset(left + size + 9, 34 + size / 2),
          12,
          // Muted text color: the frame color vanishes on the night panel.
          _s.onSurfaceVariant,
        );
      }
    }
    final first = quests.first;
    _text(
      c,
      '${first.title} · ${_statusLine(first)}',
      const Offset(12, 124),
      size: 12,
      color: _s.onSurfaceVariant,
      maxWidth: width - 24,
    );
  }

  void _next(Canvas c, List<WidgetQuest> quests) {
    const width = 320.0;
    final first = quests.firstOrNull;
    _header(
      c,
      l10n.widgetNextTitle,
      width,
      color: first?.status == WidgetStatus.late ? _s.error : _s.primary,
      arrow: true,
    );
    if (first == null) return _empty(c, 44, width);
    final (bg, fg) = _colors(first.status);
    const card = Rect.fromLTWH(10, 32, width - 20, 62);
    c.drawRect(card, Paint()..color = bg);
    c.drawRect(
      card.deflate(1),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = look.pixels.frame,
    );
    _tile(c, const Rect.fromLTWH(20, 41, 44, 44), first);
    _text(
      c,
      first.title,
      const Offset(74, 44),
      size: 16,
      bold: true,
      color: fg,
      maxWidth: width - 100,
    );
    _text(
      c,
      '${first.status == WidgetStatus.late ? '! ' : ''}'
      '${_statusLine(first)} · ${l10n.pointsValue(first.points)}',
      const Offset(74, 66),
      size: 12,
      color: fg,
      maxWidth: width - 100,
    );
    final rest = quests.skip(1).toList();
    if (rest.isEmpty) return;
    final then = _text(
      c,
      l10n.widgetThen,
      const Offset(12, 112),
      size: 12,
      color: _s.onSurfaceVariant,
    );
    var left = 12 + then.width + 8;
    const small = 26.0;
    for (final q in rest.take(5)) {
      _tile(c, Rect.fromLTWH(left, 106, small, small), q);
      left += small + 6;
    }
    if (rest.length > 5) {
      _text(
        c,
        '+${rest.length - 5}',
        Offset(left + 2, 114),
        size: 9,
        pixel: true,
        color: _s.onSurfaceVariant,
      );
    }
  }
}

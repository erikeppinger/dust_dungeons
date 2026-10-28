import 'package:flutter_test/flutter_test.dart';
import 'package:homework_and_chores/features/notifications/notification_service.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

void main() {
  setUpAll(tzdata.initializeTimeZones);

  test('known names are used as is', () {
    expect(
      resolveLocation('Europe/Berlin', const Duration(hours: 1)).name,
      'Europe/Berlin',
    );
  });

  test('aliases reported by some devices resolve (GMT, UTC)', () {
    expect(resolveLocation('GMT', Duration.zero), isNot(tz.UTC));
    expect(() => resolveLocation('UTC', Duration.zero), returnsNormally);
  });

  test('unknown names fall back to the current offset', () {
    expect(
      resolveLocation('Mars/Olympus', const Duration(hours: 2)).name,
      'Etc/GMT-2',
    );
    expect(resolveLocation(null, const Duration(hours: -5)).name, 'Etc/GMT+5');
    expect(resolveLocation(null, Duration.zero).name, 'Etc/UTC');
  });

  test('half-hour offsets without a known name fall back to UTC', () {
    expect(
      resolveLocation(null, const Duration(hours: 5, minutes: 30)),
      tz.UTC,
    );
  });
}

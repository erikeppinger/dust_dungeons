import 'package:flutter_test/flutter_test.dart';
import 'package:homework_and_chores/domain/screen_time.dart';

void main() {
  test('quests earn a minute per 5 points, up to the cap', () {
    expect(earnedScreenMinutes(17, 30), 3);
    expect(earnedScreenMinutes(4, 30), 0);
    expect(earnedScreenMinutes(400, 30), 30);
    expect(earnedScreenMinutes(400, 0), 0, reason: 'earning switched off');
    expect(earnedScreenMinutes(-10, 30), 0, reason: 'never negative');
  });

  test('budget, left, low and over', () {
    const b = ScreenBudget(base: 60, earned: 15, vouchers: 10, used: 52);
    expect(b.total, 85);
    expect(b.left, 33);
    expect((b.low, b.over), (false, false));
    const low = ScreenBudget(base: 60, earned: 0, vouchers: 0, used: 50);
    expect((low.left, low.low, low.over), (10, true, false));
    const over = ScreenBudget(base: 60, earned: 0, vouchers: 0, used: 70);
    expect((over.left, over.low, over.over), (-10, false, true));
    const exactly = ScreenBudget(base: 60, earned: 0, vouchers: 0, used: 60);
    expect(exactly.over, isFalse, reason: 'using it all is not over');
  });

  test('tired takes one heart, never the last', () {
    expect(tiredMaxHp(5, tired: true), 4);
    expect(tiredMaxHp(5, tired: false), 5);
    expect(tiredMaxHp(1, tired: true), 1);
  });
}

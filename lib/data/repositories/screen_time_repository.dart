import 'package:drift/drift.dart';

import '../../domain/dates.dart';
import '../../domain/fight/shop.dart';
import '../db/app_database.dart';
import 'shop_repository.dart';

/// Daily screen-time totals and voucher use.
class ScreenTimeRepository {
  ScreenTimeRepository(this._db);

  final AppDatabase _db;

  /// Saved days of a profile, oldest first.
  Stream<List<ScreenDay>> watchDays(int profileId) =>
      (_db.select(_db.screenDays)
            ..where((d) => d.profileId.equals(profileId))
            ..orderBy([(d) => OrderingTerm.asc(d.day)]))
          .watch();

  Future<ScreenDay?> _row(int profileId, DateTime day) =>
      (_db.select(_db.screenDays)..where(
            (d) => d.profileId.equals(profileId) & d.day.equals(dayOf(day)),
          ))
          .getSingleOrNull();

  /// Saves a day's use and budget; voucher minutes already booked stay.
  Future<void> saveDay(
    int profileId,
    DateTime day, {
    required int usedMinutes,
    required int budgetMinutes,
  }) => _db
      .into(_db.screenDays)
      .insert(
        ScreenDaysCompanion.insert(
          profileId: profileId,
          day: dayOf(day),
          usedMinutes: Value(usedMinutes),
          budgetMinutes: Value(budgetMinutes),
        ),
        onConflict: DoUpdate(
          (_) => ScreenDaysCompanion(
            usedMinutes: Value(usedMinutes),
            budgetMinutes: Value(budgetMinutes),
          ),
        ),
      );

  /// Uses one [voucher] for [day]: takes it from the inventory and books
  /// its minutes in one transaction. `false` if none was owned.
  Future<bool> useVoucher(int profileId, ShopItem voucher, DateTime day) =>
      _db.transaction(() async {
        if (!await ShopRepository(_db).use(profileId, voucher)) return false;
        final row = await _row(profileId, day);
        final minutes = (row?.voucherMinutes ?? 0) + voucher.minutes;
        await _db
            .into(_db.screenDays)
            .insert(
              ScreenDaysCompanion.insert(
                profileId: profileId,
                day: dayOf(day),
                voucherMinutes: Value(minutes),
              ),
              onConflict: DoUpdate(
                (_) => ScreenDaysCompanion(voucherMinutes: Value(minutes)),
              ),
            );
        return true;
      });
}

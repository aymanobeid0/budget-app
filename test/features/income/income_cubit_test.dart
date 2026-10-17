import 'package:budget_app/core/database/app_database.dart';
import 'package:budget_app/features/income/cubit/income_cubit.dart';
import 'package:budget_app/features/income/cubit/income_state.dart';
import 'package:budget_app/features/income/income_ledger.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  late AppDatabase db;
  late IncomeCubit cubit;

  setUp(() async {
    db = await AppDatabase.open(factory: databaseFactoryFfi, path: inMemoryDatabasePath);
    cubit = IncomeCubit(IncomeLedger(db));
    await cubit.load();
  });

  tearDown(() async {
    await cubit.close();
    await db.close();
  });

  IncomeLoaded loaded() => cubit.state as IncomeLoaded;

  test('totals Income per day and overall, ignoring deleted Income', () async {
    await cubit.addIncome(amountMinor: 100000, sourceId: 'src_salary', paidOn: DateTime.utc(2026, 10, 15));
    await cubit.addIncome(amountMinor: 25000, sourceId: 'src_other', paidOn: DateTime.utc(2026, 10, 15));
    await cubit.addIncome(amountMinor: 7000, sourceId: 'src_freelance', paidOn: DateTime.utc(2026, 10, 12));

    expect(loaded().totalMinor, 132000);
    expect(loaded().dayTotals, {'2026-10-15': 125000, '2026-10-12': 7000});

    final freelance = loaded().income.firstWhere((i) => i.sourceId == 'src_freelance');
    await cubit.deleteIncome(freelance.id);

    expect(loaded().totalMinor, 125000);
    expect(loaded().dayTotals, {'2026-10-15': 125000});
  });

  test('editing an Income updates the totals', () async {
    await cubit.addIncome(amountMinor: 100000, sourceId: 'src_salary', paidOn: DateTime.utc(2026, 10, 15));

    await cubit.updateIncome(loaded().income.single.copyWith(amountMinor: 90000));

    expect(loaded().totalMinor, 90000);
  });
}

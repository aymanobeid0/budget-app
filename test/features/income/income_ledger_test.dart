import 'package:budget_app/core/database/app_database.dart';
import 'package:budget_app/features/income/income.dart';
import 'package:budget_app/features/income/income_ledger.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  late AppDatabase db;
  late IncomeLedger ledger;

  setUp(() async {
    db = await AppDatabase.open(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );
    ledger = IncomeLedger(db);
  });

  tearDown(() => db.close());

  Income income(String id, int amountMinor, DateTime paidOn, {String sourceId = 'src_salary'}) {
    final now = DateTime.now();
    return Income(
      id: id,
      amountMinor: amountMinor,
      sourceId: sourceId,
      paidOn: paidOn,
      createdAt: now,
      updatedAt: now,
    );
  }

  test('starts with Salary, Freelance and Other as Income Sources', () async {
    final sources = await ledger.loadSources();
    expect(sources.map((s) => s.name), containsAll(<String>['Salary', 'Freelance', 'Other']));
    expect(sources, hasLength(3));
  });

  test('does not seed sources while an account download is pending', () async {
    final guarded = IncomeLedger(db, canSeedDefaults: () => false);
    expect(await guarded.loadSources(), isEmpty);

    // Once allowed, the empty table gets the presets.
    expect(await ledger.loadSources(), hasLength(3));
  });

  test('logs Income and loads it newest first', () async {
    await ledger.loadSources();
    await ledger.logIncome(income('i1', 500000, DateTime.utc(2026, 10, 1)));
    await ledger.logIncome(income('i2', 25000, DateTime.utc(2026, 10, 15), sourceId: 'src_other'));
    await ledger.logIncome(income('i3', 12000, DateTime.utc(2026, 10, 8), sourceId: 'src_freelance'));

    final list = await ledger.loadIncome();
    expect(list.map((i) => i.id), ['i2', 'i3', 'i1']);
    expect(list.first.amountMinor, 25000);
    expect(list.first.sourceId, 'src_other');
    expect(list.first.paidOn, DateTime.utc(2026, 10, 15));
  });

  test('watchIncome emits the list after each new Income', () async {
    await ledger.loadSources();
    final emissions = <List<Income>>[];
    final sub = ledger.watchIncome().listen(emissions.add);

    await ledger.logIncome(income('i1', 1000, DateTime.utc(2026, 10, 17)));
    await pumpEventQueue();

    expect(emissions.last.map((i) => i.id), ['i1']);
    await sub.cancel();
  });
}

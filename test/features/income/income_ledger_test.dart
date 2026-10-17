import 'package:budget_app/core/database/app_database.dart';
import 'package:budget_app/features/income/income.dart';
import 'package:budget_app/features/income/income_ledger.dart';
import 'package:budget_app/features/income/income_source.dart';
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

  test('editing an Income changes its amount, date and source', () async {
    await ledger.loadSources();
    await ledger.logIncome(income('i1', 1000, DateTime.utc(2026, 10, 1)));
    await ledger.logIncome(income('i2', 2000, DateTime.utc(2026, 10, 5)));

    final original = (await ledger.loadIncome()).firstWhere((i) => i.id == 'i1');
    await ledger.updateIncome(original.copyWith(
      amountMinor: 1500,
      sourceId: 'src_freelance',
      paidOn: DateTime.utc(2026, 10, 9),
    ));

    final list = await ledger.loadIncome();
    expect(list.map((i) => i.id), ['i1', 'i2']); // now the newest
    expect(list.first.amountMinor, 1500);
    expect(list.first.sourceId, 'src_freelance');
  });

  test('deleting an Income removes it from the list', () async {
    await ledger.loadSources();
    await ledger.logIncome(income('i1', 1000, DateTime.utc(2026, 10, 1)));
    await ledger.logIncome(income('i2', 2000, DateTime.utc(2026, 10, 5)));

    await ledger.deleteIncome('i1');

    expect((await ledger.loadIncome()).map((i) => i.id), ['i2']);
  });

  test('creates, renames and recolours an Income Source', () async {
    await ledger.loadSources();
    final now = DateTime.now();
    await ledger.saveSource(IncomeSource(
      id: 'src_clinic',
      name: 'Clinic',
      icon: 'local_hospital',
      color: 0xFF0F766E,
      createdAt: now,
      updatedAt: now,
    ));
    var clinic = (await ledger.loadSources()).firstWhere((s) => s.id == 'src_clinic');
    expect(clinic.name, 'Clinic');

    await ledger.saveSource(clinic.copyWith(name: 'Dental clinic', icon: 'work', color: 0xFFDB2777));
    clinic = (await ledger.loadSources()).firstWhere((s) => s.id == 'src_clinic');
    expect(clinic.name, 'Dental clinic');
    expect(clinic.icon, 'work');
    expect(clinic.color, 0xFFDB2777);
    expect(await ledger.loadSources(), hasLength(4));
  });

  test('deleting a source hides it but keeps its past Income, which still resolves the source', () async {
    await ledger.loadSources();
    await ledger.logIncome(income('i1', 500000, DateTime.utc(2026, 9, 30)));

    await ledger.deleteSource('src_salary');

    expect((await ledger.loadSources()).map((s) => s.id), isNot(contains('src_salary')));
    expect((await ledger.loadIncome()).single.sourceId, 'src_salary');
    final all = await ledger.loadSources(includeDeleted: true);
    final salary = all.firstWhere((s) => s.id == 'src_salary');
    expect(salary.name, 'Salary');
    expect(salary.isDeleted, isTrue);
  });

  test('deleting every source does not bring the presets back', () async {
    for (final s in await ledger.loadSources()) {
      await ledger.deleteSource(s.id);
    }
    expect(await ledger.loadSources(), isEmpty);
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

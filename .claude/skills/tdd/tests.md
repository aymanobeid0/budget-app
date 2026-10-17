# Good and Bad Tests

Examples use this repo's stack: `flutter_test`, `bloc_test`, and a real in-memory SQLite database through `sqflite_common_ffi` (see `test/features/income/income_cubit_test.dart` for the house pattern).

## Good Tests

**Integration-style**: Test through real interfaces, not mocks of internal parts.

```dart
// GOOD: Tests observable behavior through the Cubit and a real ledger
test('deleting an Income drops it from the total', () async {
  final cubit = IncomeCubit(IncomeLedger(db));
  await cubit.load();
  await cubit.addIncome(amountMinor: 100000, sourceId: 'src_salary', paidOn: DateTime.utc(2026, 10, 15));

  await cubit.deleteIncome((cubit.state as IncomeLoaded).income.single.id);

  expect((cubit.state as IncomeLoaded).totalMinor, 0);
});
```

Characteristics:

- Tests behavior users/callers care about
- Uses public API only
- Survives internal refactors
- Describes WHAT, not HOW
- One logical assertion per test

## Bad Tests

**Implementation-detail tests**: Coupled to internal structure.

```dart
// BAD: Tests implementation details
test('addIncome calls ledger.logIncome', () async {
  final ledger = MockIncomeLedger();
  await IncomeCubit(ledger).addIncome(amountMinor: 500, sourceId: 'src_other', paidOn: today);
  verify(() => ledger.logIncome(any())).called(1);
});
```

Red flags:

- Mocking internal collaborators
- Testing private methods
- Asserting on call counts/order
- Test breaks when refactoring without behavior change
- Test name describes HOW not WHAT
- Verifying through external means instead of interface

```dart
// BAD: Bypasses the ledger to verify
test('logIncome saves to database', () async {
  await ledger.logIncome(income);
  final rows = await db.raw.query('income', where: 'id = ?', whereArgs: [income.id]);
  expect(rows, isNotEmpty);
});

// GOOD: Verifies through the interface
test('logged Income can be loaded back', () async {
  await ledger.logIncome(income);
  expect((await ledger.loadIncome()).single.amountMinor, income.amountMinor);
});
```

**Tautological tests**: Expected value restates the implementation, so the test passes by construction.

```dart
// BAD: Expected value is recomputed the way the code computes it
test('Net is Income minus Expenses', () {
  final net = calculateNet(income: income, expenses: expenses, period: NetPeriod.allTime, today: today);
  final expected = income.fold(0, (s, i) => s + i.amountMinor) - expenses.fold(0, (s, e) => s + e.amountMinor);
  expect(net.netMinor, expected);
});

// GOOD: Expected value is an independent, known literal
test('spending more than you make gives a negative Net', () {
  final net = calculateNet(
    income: [income(1000, wednesday)],
    expenses: [expense(1500, wednesday)],
    period: NetPeriod.month,
    today: wednesday,
  );
  expect(net.netMinor, -500);
});
```

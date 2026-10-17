import 'package:budget_app/core/format/money.dart';
import 'package:budget_app/features/settings/cubit/currency_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('first launch shows MRU', () {
    final cubit = CurrencyCubit();
    addTearDown(cubit.close);

    expect(cubit.state, Currency.mru);
  });

  test('a picked Currency is remembered on the device', () async {
    final storage = InMemoryCurrencyStorage();
    final cubit = CurrencyCubit(storage: storage);
    addTearDown(cubit.close);

    cubit.select(Currency.egp);

    expect(cubit.state, Currency.egp);
    expect(await storage.read(), Currency.egp);
  });
}

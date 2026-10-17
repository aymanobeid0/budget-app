import 'dart:async';

import 'package:budget_app/core/database/app_database.dart';
import 'package:budget_app/core/format/money.dart';
import 'package:budget_app/features/categories/category_store.dart';
import 'package:budget_app/features/consultant/cubit/consultant_cubit.dart';
import 'package:budget_app/features/consultant/data/consultant_client.dart';
import 'package:budget_app/features/consultant/models/chat_message.dart';
import 'package:budget_app/features/expenses/expense.dart';
import 'package:budget_app/features/expenses/expense_ledger.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class FakeConsultantClient implements ConsultantClient {
  FakeConsultantClient({this.chunks = const ['You spent ', '\$50 ', 'on food.']});

  final List<String> chunks;
  String? lastPrompt;
  String? lastContextSummary;
  Currency? lastCurrency;

  @override
  Stream<String> streamConsultantResponse({
    required String prompt,
    required String contextSummary,
    required Currency currency,
    List<ChatMessage> conversationHistory = const [],
  }) async* {
    lastPrompt = prompt;
    lastContextSummary = contextSummary;
    lastCurrency = currency;
    for (final chunk in chunks) {
      yield chunk;
    }
  }
}

void main() {
  setUpAll(sqfliteFfiInit);

  late AppDatabase db;
  late ExpenseLedger ledger;
  late CategoryStore store;
  late FakeConsultantClient client;
  late ConsultantCubit cubit;

  setUp(() async {
    db = await AppDatabase.open(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );
    ledger = ExpenseLedger(db);
    store = CategoryStore(db);
    client = FakeConsultantClient();
    cubit = ConsultantCubit(
      ledger: ledger,
      categoryStore: store,
      client: client,
    );
  });

  tearDown(() async {
    await cubit.close();
    await db.close();
  });

  test('initial state contains empty messages and default suggestion chips', () {
    expect(cubit.state.messages, isEmpty);
    expect(cubit.state.suggestedPrompts, isNotEmpty);
    expect(cubit.state.suggestedPrompts, contains('Where did I spend the most?'));
  });

  test('sending a prompt streams tokens and appends to assistant message', () async {
    // Seed an expense
    await store.loadCategories();
    await ledger.logExpense(Expense(
      id: 'e1',
      amountMinor: 5000,
      categoryId: 'cat_food',
      spentOn: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));

    await cubit.sendMessage('Where did I spend the most?');

    // Wait for stream to finish
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(cubit.state.messages.length, 2);
    // User message
    expect(cubit.state.messages[0].isUser, isTrue);
    expect(cubit.state.messages[0].text, 'Where did I spend the most?');

    // Assistant message
    expect(cubit.state.messages[1].isUser, isFalse);
    expect(cubit.state.messages[1].text, 'You spent \$50 on food.');
    expect(cubit.state.messages[1].isStreaming, isFalse);

    // Verify context summary had the expense
    expect(client.lastContextSummary, contains('Food: 50 MRU'));
  });

  test('the consultant is told amounts are in the chosen Currency', () async {
    var currency = Currency.egp;
    final cubitWithCurrency = ConsultantCubit(
      ledger: ledger,
      categoryStore: store,
      client: client,
      currency: () => currency,
    );
    addTearDown(cubitWithCurrency.close);
    await store.loadCategories();
    await ledger.logExpense(Expense(
      id: 'e1',
      amountMinor: 5000,
      categoryId: 'cat_food',
      spentOn: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));

    await cubitWithCurrency.sendMessage('Where did I spend the most?');
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(client.lastContextSummary, contains('Food: 50 EGP'));
    expect(client.lastCurrency, Currency.egp);

    currency = Currency.sar;
    await cubitWithCurrency.sendMessage('And now?');
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(client.lastContextSummary, contains('Food: 50 SAR'));
    expect(client.lastCurrency, Currency.sar);
  });

  test('the system prompt names the chosen Currency, not dollars', () {
    final prompt = consultantSystemInstruction(contextSummary: 'Total recorded expenses: 0 EUR', currency: Currency.eur);

    expect(prompt, contains('EUR'));
    expect(prompt, contains('25 EUR'));
    expect(prompt, isNot(contains('\$')));
  });
}

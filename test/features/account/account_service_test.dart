import 'dart:io';

import 'package:budget_app/core/database/app_database.dart';
import 'package:budget_app/core/sync/cloud_sync_client.dart';
import 'package:budget_app/core/sync/sync_engine.dart';
import 'package:budget_app/features/account/account_service.dart';
import 'package:budget_app/features/account/data/account_prefs.dart';
import 'package:budget_app/features/account/data/auth_gateway.dart';
import 'package:budget_app/features/categories/category_store.dart';
import 'package:budget_app/features/expenses/expense.dart';
import 'package:budget_app/features/expenses/expense_ledger.dart';
import 'package:budget_app/features/income/income.dart';
import 'package:budget_app/features/income/income_ledger.dart';
import 'package:budget_app/core/theme/app_theme.dart';
import 'package:budget_app/core/theme/theme_cubit.dart';
import 'package:budget_app/features/account/cubit/account_cubit.dart';
import 'package:budget_app/features/settings/ui/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// In-memory stand-in for Supabase: auth users + per-user rows keyed by
/// (user_id, id), like the new composite primary keys.
class FakeServer {
  final users = <String, String>{}; // email -> password
  final ids = <String, String>{}; // email -> user id
  final categories = <String, Map<String, Map<String, dynamic>>>{}; // uid -> id -> row
  final expenses = <String, Map<String, Map<String, dynamic>>>{};
  final incomeSources = <String, Map<String, Map<String, dynamic>>>{};
  final income = <String, Map<String, Map<String, dynamic>>>{};
  int _anon = 0;
  bool offline = false;

  String newAnonId() => 'anon-${++_anon}';
}

class FakeAuth implements AuthGateway {
  FakeAuth(this.server) : uid = server.newAnonId();
  final FakeServer server;
  String? uid;
  String? email;

  /// Test hook run right after a successful sign-in.
  void Function()? onSignedIn;

  @override
  String? get accountEmail => email;

  @override
  Future<void> signUp({required String email, required String password}) async {
    if (server.offline) throw Exception('SocketException');
    if (server.users.containsKey(email)) {
      throw const AccountException('That username is taken. Try another one, or sign in instead.');
    }
    server.users[email] = password;
    server.ids[email] = 'user-${server.ids.length + 1}';
    uid = server.ids[email];
    this.email = email;
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    if (server.offline) throw Exception('SocketException');
    if (server.users[email] != password) throw const AccountException('Wrong username or password.');
    uid = server.ids[email];
    this.email = email;
    onSignedIn?.call();
  }

  @override
  Future<void> signOut() async {
    uid = null;
    email = null;
  }

  @override
  Future<void> signInAsGuest() async {
    uid = server.newAnonId();
    email = null;
  }
}

class FakeCloud implements CloudSyncClient {
  FakeCloud(this.server, this.auth);
  final FakeServer server;
  final FakeAuth auth;

  void _online() {
    if (server.offline) throw Exception('Network unreachable');
  }

  @override
  String? get currentUserId => auth.uid;

  @override
  Future<String?> ensureAuthenticated() async {
    _online();
    auth.uid ??= server.newAnonId();
    return auth.uid;
  }

  @override
  Future<void> upsertCategories(List<Map<String, dynamic>> rows) async {
    _online();
    for (final r in rows) {
      server.categories.putIfAbsent(r['user_id'] as String, () => {})[r['id'] as String] = Map.of(r);
    }
  }

  @override
  Future<void> upsertExpenses(List<Map<String, dynamic>> rows) async {
    _online();
    for (final r in rows) {
      server.expenses.putIfAbsent(r['user_id'] as String, () => {})[r['id'] as String] = Map.of(r);
    }
  }

  void _store(Map<String, Map<String, Map<String, dynamic>>> table, List<Map<String, dynamic>> rows) {
    for (final r in rows) {
      table.putIfAbsent(r['user_id'] as String, () => {})[r['id'] as String] = Map.of(r);
    }
  }

  @override
  Future<void> upsertIncomeSources(List<Map<String, dynamic>> rows) async {
    _online();
    _store(server.incomeSources, rows);
  }

  @override
  Future<void> upsertIncome(List<Map<String, dynamic>> rows) async {
    _online();
    _store(server.income, rows);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchIncomeSources() async {
    _online();
    return (server.incomeSources[auth.uid] ?? {}).values.toList();
  }

  @override
  Future<List<Map<String, dynamic>>> fetchIncome() async {
    _online();
    return (server.income[auth.uid] ?? {}).values.toList();
  }

  @override
  Future<List<Map<String, dynamic>>> fetchCategories() async {
    _online();
    return (server.categories[auth.uid] ?? {}).values.toList();
  }

  @override
  Future<List<Map<String, dynamic>>> fetchExpenses() async {
    _online();
    return (server.expenses[auth.uid] ?? {}).values.toList();
  }
}

/// One installed copy of the app on a phone.
class Phone {
  Phone._(this.db, this.auth, this.service, this.ledger, this.store, this.incomeLedger);

  final AppDatabase db;
  final FakeAuth auth;
  final AccountService service;
  final ExpenseLedger ledger;
  final CategoryStore store;
  final IncomeLedger incomeLedger;

  static Future<Phone> install(FakeServer server) async {
    // A separate file per phone: in-memory databases are shared by path.
    final dir = await Directory.systemTemp.createTemp('phone');
    final db = await AppDatabase.open(factory: databaseFactoryFfiNoIsolate, path: '${dir.path}/app.db');
    final auth = FakeAuth(server);
    final engine = SyncEngine(db: db, client: FakeCloud(server, auth));
    final service = AccountService(
      db: db,
      auth: auth,
      syncEngine: engine,
      prefsStorage: InMemoryAccountPrefsStorage(),
    );
    await service.init();
    final store = CategoryStore(db, syncEngine: engine, canSeedDefaults: service.canSeedDefaults);
    final ledger = ExpenseLedger(db, syncEngine: engine);
    final incomeLedger = IncomeLedger(db, syncEngine: engine, canSeedDefaults: service.canSeedDefaults);
    await store.loadCategories(); // seeds defaults like a fresh launch
    await incomeLedger.loadSources();
    return Phone._(db, auth, service, ledger, store, incomeLedger);
  }

  Future<void> addIncome(String id, int minor) async {
    final now = DateTime.now();
    await incomeLedger.logIncome(Income(
      id: id,
      amountMinor: minor,
      sourceId: 'src_salary',
      paidOn: now,
      createdAt: now,
      updatedAt: now,
    ));
  }

  Future<List<int>> incomeAmounts() async =>
      (await incomeLedger.loadIncome()).map((i) => i.amountMinor).toList()..sort();

  Future<void> addExpense(String id, int minor) async {
    final now = DateTime.now();
    await ledger.logExpense(Expense(
      id: id,
      amountMinor: minor,
      categoryId: 'cat_food',
      spentOn: now,
      createdAt: now,
      updatedAt: now,
    ));
  }

  Future<List<int>> amounts() async => (await ledger.loadExpenses()).map((e) => e.amountMinor).toList();
}

void main() {
  setUpAll(sqfliteFfiInit);

  late FakeServer server;
  setUp(() => server = FakeServer());

  test('username rules and email mapping', () {
    expect(AccountService.validateUsername('Ay'), isNotNull);
    expect(AccountService.validateUsername('ayman.o'), isNull);
    expect(AccountService.validateUsername('has space'), isNotNull);
    expect(AccountService.validatePassword('12345'), isNotNull);
    expect(AccountService.emailFor(' Ayman '), 'ayman@budgetapp.local');
    expect(AccountService.usernameFromEmail('ayman@budgetapp.local'), 'ayman');
  });

  test('creating an account moves the guest data into it', () async {
    final phone = await Phone.install(server);
    await phone.addExpense('e1', 4500);

    final warning = await phone.service.createAccount(username: 'ayman', password: 'secret1');

    expect(warning, isNull);
    expect(phone.service.currentUsername, 'ayman');
    final uid = server.ids['ayman@budgetapp.local']!;
    expect(server.expenses[uid]!.keys, ['e1']);
    expect(server.categories[uid]!.containsKey('cat_food'), isTrue);
    expect(await phone.amounts(), [4500]);
  });

  test('after a reinstall, signing in brings the data back', () async {
    final first = await Phone.install(server);
    await first.addExpense('e1', 4500);
    await first.service.createAccount(username: 'ayman', password: 'secret1');

    final reinstalled = await Phone.install(server); // fresh guest, empty
    expect(await reinstalled.amounts(), isEmpty);

    final warning = await reinstalled.service.signIn(username: 'ayman', password: 'secret1');

    expect(warning, isNull);
    expect(reinstalled.service.currentUsername, 'ayman');
    expect(await reinstalled.amounts(), [4500]);
  });

  test('two accounts can both own the default categories (cat_food)', () async {
    final a = await Phone.install(server);
    await a.service.createAccount(username: 'alice', password: 'secret1');
    final b = await Phone.install(server);
    await b.service.createAccount(username: 'bob', password: 'secret2');

    expect(server.categories[server.ids['alice@budgetapp.local']]!.containsKey('cat_food'), isTrue);
    expect(server.categories[server.ids['bob@budgetapp.local']]!.containsKey('cat_food'), isTrue);
  });

  test('switching accounts uploads pending changes, then shows only the new account', () async {
    final setup = await Phone.install(server);
    await setup.addExpense('b1', 900);
    await setup.service.createAccount(username: 'bob', password: 'secret2');

    final phone = await Phone.install(server);
    await phone.addExpense('a1', 100);
    await phone.service.createAccount(username: 'alice', password: 'secret1');
    await phone.addExpense('a2', 200); // made while signed in as alice

    await phone.service.signIn(username: 'bob', password: 'secret2');

    expect(phone.service.currentUsername, 'bob');
    expect(await phone.amounts(), [900]);
    final alice = server.ids['alice@budgetapp.local']!;
    expect(server.expenses[alice]!.keys.toSet(), {'a1', 'a2'});

    await phone.service.signIn(username: 'alice', password: 'secret1');
    expect((await phone.amounts())..sort(), [100, 200]);
  });

  test('creating an account moves guest Income into it', () async {
    final phone = await Phone.install(server);
    await phone.addIncome('g1', 350000);

    await phone.service.createAccount(username: 'ayman', password: 'secret1');

    final uid = server.ids['ayman@budgetapp.local']!;
    expect(server.income[uid]!.keys, ['g1']);
    expect(server.incomeSources[uid]!.keys, containsAll(<String>['src_salary', 'src_freelance', 'src_other']));
  });

  test('switching accounts shows only the new account\'s Income', () async {
    final setup = await Phone.install(server);
    await setup.addIncome('b1', 900);
    await setup.service.createAccount(username: 'bob', password: 'secret2');

    final phone = await Phone.install(server);
    await phone.addIncome('a1', 100);
    await phone.service.createAccount(username: 'alice', password: 'secret1');

    await phone.service.signIn(username: 'bob', password: 'secret2');
    expect(await phone.incomeAmounts(), [900]);

    await phone.service.signIn(username: 'alice', password: 'secret1');
    expect(await phone.incomeAmounts(), [100]);

    await phone.service.signOut();
    expect(await phone.incomeAmounts(), isEmpty);
  });

  test('wrong password changes nothing', () async {
    final setup = await Phone.install(server);
    await setup.service.createAccount(username: 'ayman', password: 'secret1');

    final phone = await Phone.install(server);
    await phone.addExpense('g1', 300);

    expect(
      () => phone.service.signIn(username: 'ayman', password: 'nope123'),
      throwsA(isA<AccountException>()),
    );
    await Future<void>.delayed(Duration.zero);
    expect(phone.service.currentUsername, isNull);
    expect(await phone.amounts(), [300]);
  });

  test('switching away is refused when the current account cannot upload', () async {
    final setup = await Phone.install(server);
    await setup.service.createAccount(username: 'bob', password: 'secret2');

    final phone = await Phone.install(server);
    await phone.service.createAccount(username: 'alice', password: 'secret1');
    server.offline = true;
    await phone.addExpense('a1', 100);

    await expectLater(
      phone.service.signIn(username: 'bob', password: 'secret2'),
      throwsA(isA<AccountException>()),
    );
    expect(phone.service.currentUsername, 'alice');
    expect(await phone.amounts(), [100]);
  });

  test('signing out clears the phone and continues as a guest', () async {
    final phone = await Phone.install(server);
    await phone.addExpense('e1', 4500);
    await phone.service.createAccount(username: 'ayman', password: 'secret1');

    await phone.service.signOut();

    expect(phone.service.currentUsername, isNull);
    expect(await phone.amounts(), isEmpty);
    // Fresh guest gets the default categories again.
    expect((await phone.store.loadCategories()).map((c) => c.id), contains('cat_food'));
  });

  test('if the download fails after sign-in, defaults are not re-seeded and it resumes later', () async {
    final setup = await Phone.install(server);
    await setup.service.createAccount(username: 'ayman', password: 'secret1');
    // Rename Food on the server so we can tell server data from seeded data.
    final uid = server.ids['ayman@budgetapp.local']!;
    server.categories[uid]!['cat_food']!['name'] = 'Groceries';
    server.categories[uid]!['cat_food']!['updated_at'] = DateTime.now().toUtc().toIso8601String();

    final phone = await Phone.install(server);
    // Fail only the download step by going offline right after sign-in.
    phone.auth.onSignedIn = () => server.offline = true;

    final warning = await phone.service.signIn(username: 'ayman', password: 'secret1');
    expect(warning, isNotNull);
    expect(phone.service.awaitingInitialPull, isTrue);
    expect(await phone.store.loadCategories(), isEmpty); // not re-seeded

    server.offline = false;
    expect(await phone.service.resumeInitialPullIfNeeded(), isTrue);
    final names = (await phone.store.loadCategories()).map((c) => c.name);
    expect(names, contains('Groceries'));
    expect(names, isNot(contains('Food')));
  });

  group('Settings account UI', () {
    Future<(Phone, AccountCubit)> pumpSettings(WidgetTester tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      final phone = (await tester.runAsync(() => Phone.install(server)))!;
      final cubit = AccountCubit(phone.service);
      addTearDown(cubit.close);
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light(),
        home: MultiBlocProvider(
          providers: [
            BlocProvider<ThemeCubit>(create: (_) => ThemeCubit()),
            BlocProvider<AccountCubit>.value(value: cubit),
          ],
          child: const SettingsScreen(),
        ),
      ));
      await tester.pumpAndSettle();
      return (phone, cubit);
    }

    testWidgets('guest sees Create account and Sign in', (tester) async {
      await pumpSettings(tester);
      expect(find.byKey(const Key('account-guest-row')), findsOneWidget);
      expect(find.byKey(const Key('create-account-btn')), findsOneWidget);
      expect(find.byKey(const Key('sign-in-btn')), findsOneWidget);
    });

    testWidgets('create account form validates, then signs in', (tester) async {
      final (_, cubit) = await pumpSettings(tester);

      await tester.tap(find.byKey(const Key('create-account-btn')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('account-username-field')), 'ayman');
      await tester.enterText(find.byKey(const Key('account-password-field')), 'secret1');
      await tester.enterText(find.byKey(const Key('account-confirm-field')), 'different');
      await tester.tap(find.byKey(const Key('account-submit-btn')));
      await tester.pumpAndSettle();
      expect(find.text("Passwords don't match"), findsOneWidget);

      await tester.enterText(find.byKey(const Key('account-confirm-field')), 'secret1');
      await tester.tap(find.byKey(const Key('account-submit-btn')));
      // The flow does real SQLite I/O: let it run outside the fake clock.
      for (var i = 0; i < 100 && cubit.state.status != AccountStatus.signedIn; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
        await tester.pump();
      }
      await tester.pumpAndSettle();

      expect(cubit.state.status, AccountStatus.signedIn);
      expect(find.byKey(const Key('account-signed-in-row')), findsOneWidget);
      expect(find.text('ayman'), findsOneWidget);
      expect(find.byKey(const Key('switch-account-btn')), findsOneWidget);
      expect(find.byKey(const Key('sign-out-btn')), findsOneWidget);

      await tester.tap(find.byKey(const Key('switch-account-btn')));
      await tester.pumpAndSettle();
      expect(find.text('Switch account'), findsWidgets);
    });

    testWidgets('signing in as a guest with expenses warns they will be replaced', (tester) async {
      final (phone, _) = await pumpSettings(tester);
      await tester.runAsync(() => phone.addExpense('g1', 300));

      await tester.tap(find.byKey(const Key('sign-in-btn')));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('guest-data-warning')), findsOneWidget);
    });
  });
}

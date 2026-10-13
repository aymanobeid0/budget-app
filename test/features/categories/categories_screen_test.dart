import 'package:budget_app/core/database/app_database.dart';
import 'package:budget_app/features/categories/category_store.dart';
import 'package:budget_app/features/categories/cubit/category_cubit.dart';
import 'package:budget_app/features/categories/ui/categories_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  late AppDatabase db;
  late CategoryStore store;
  late CategoryCubit cubit;

  setUp(() async {
    db = await AppDatabase.open(
      factory: databaseFactoryFfiNoIsolate,
      path: inMemoryDatabasePath,
    );
    store = CategoryStore(db);
    cubit = CategoryCubit(store);
  });

  tearDown(() async {
    await cubit.close();
    await db.close();
  });

  Widget buildTestWidget() {
    return MaterialApp(
      home: BlocProvider<CategoryCubit>.value(
        value: cubit,
        child: const CategoriesScreen(),
      ),
    );
  }

  testWidgets('renders preloaded default categories in list', (tester) async {
    await cubit.load();
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('Food'), findsOneWidget);
    expect(find.text('Transport'), findsOneWidget);
    expect(find.text('Utilities'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });

  testWidgets('tapping Add Category opens form sheet and adds a new category', (tester) async {
    await cubit.load();
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    // Tap the FAB to open the Add Category sheet
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('New Category'), findsOneWidget);

    // Enter name
    await tester.enterText(find.byKey(const Key('category-name-field')), 'Groceries');
    await tester.pumpAndSettle();

    // Tap Save
    await tester.tap(find.byKey(const Key('save-category-btn')));
    await tester.pumpAndSettle();

    // Verify 'Groceries' now appears in the list
    expect(find.text('Groceries'), findsOneWidget);
  });
}

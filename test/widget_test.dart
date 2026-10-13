import 'package:budget_app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shell shows three tabs and starts on Expenses', (tester) async {
    await tester.pumpWidget(const BudgetApp());
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.widgetWithText(NavigationDestination, 'Expenses'), findsOneWidget);
    expect(find.widgetWithText(NavigationDestination, 'Categories'), findsOneWidget);
    expect(find.widgetWithText(NavigationDestination, 'Consultant'), findsOneWidget);
    expect(find.byKey(const Key('expenses-screen')), findsOneWidget);
  });

  testWidgets('tapping a tab switches the visible screen', (tester) async {
    await tester.pumpWidget(const BudgetApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Consultant'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('consultant-screen')), findsOneWidget);

    await tester.tap(find.text('Categories'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('categories-screen')), findsOneWidget);
  });
}

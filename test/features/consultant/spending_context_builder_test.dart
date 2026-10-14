import 'package:budget_app/features/categories/category.dart';
import 'package:budget_app/features/consultant/data/spending_context_builder.dart';
import 'package:budget_app/features/expenses/expense.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SpendingContextBuilder', () {
    final categories = [
      Category(
        id: 'cat_food',
        name: 'Food',
        icon: 'restaurant',
        color: 0xFFEF4444,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      ),
      Category(
        id: 'cat_transport',
        name: 'Transport',
        icon: 'directions_car',
        color: 0xFF3B82F6,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      ),
    ];

    test('builds empty context when no expenses exist', () {
      final contextText = SpendingContextBuilder.build(
        expenses: [],
        categories: categories,
      );

      expect(contextText, contains('Total recorded expenses: \$0.00'));
      expect(contextText, contains('No expenses recorded yet'));
    });

    test('accurately calculates category totals and summary lines', () {
      final expenses = [
        Expense(
          id: 'e1',
          amountMinor: 2500, // $25.00
          categoryId: 'cat_food',
          spentOn: DateTime(2026, 10, 10),
          createdAt: DateTime(2026, 10, 10),
          updatedAt: DateTime(2026, 10, 10),
        ),
        Expense(
          id: 'e2',
          amountMinor: 1550, // $15.50
          categoryId: 'cat_food',
          spentOn: DateTime(2026, 10, 11),
          createdAt: DateTime(2026, 10, 11),
          updatedAt: DateTime(2026, 10, 11),
        ),
        Expense(
          id: 'e3',
          amountMinor: 1000, // $10.00
          categoryId: 'cat_transport',
          spentOn: DateTime(2026, 10, 12),
          createdAt: DateTime(2026, 10, 12),
          updatedAt: DateTime(2026, 10, 12),
        ),
      ];

      final contextText = SpendingContextBuilder.build(
        expenses: expenses,
        categories: categories,
      );

      // Total is $50.50
      expect(contextText, contains('Total recorded expenses: \$50.50'));
      // Food total is $40.50
      expect(contextText, contains('Food: \$40.50'));
      // Transport total is $10.00
      expect(contextText, contains('Transport: \$10.00'));
      // Top category is Food
      expect(contextText, contains('Highest spending category: Food'));
    });
  });
}

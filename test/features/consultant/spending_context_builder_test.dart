import 'package:budget_app/features/categories/category.dart';
import 'package:budget_app/features/consultant/data/spending_context_builder.dart';
import 'package:budget_app/features/expenses/expense.dart';
import 'package:budget_app/features/income/income.dart';
import 'package:budget_app/features/income/income_source.dart';
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
  
    group('income section', () {
      final stamp = DateTime(2026, 1, 1);
      final sources = [
        IncomeSource(id: 'src_salary', name: 'Salary', icon: 'work', color: 0, createdAt: stamp, updatedAt: stamp),
        IncomeSource(
          id: 'src_clinic',
          name: 'Dental clinic',
          icon: 'work',
          color: 0,
          createdAt: stamp,
          updatedAt: stamp,
          deletedAt: stamp, // deleted, but its past Income still has a name
        ),
      ];
      Income income(String id, int minor, String sourceId, DateTime paidOn) => Income(
            id: id,
            amountMinor: minor,
            sourceId: sourceId,
            paidOn: paidOn,
            createdAt: stamp,
            updatedAt: stamp,
          );
      final octoberExpense = Expense(
        id: 'e1',
        amountMinor: 30000, // $300.00
        categoryId: 'cat_food',
        spentOn: DateTime.utc(2026, 10, 3),
        createdAt: stamp,
        updatedAt: stamp,
      );

      test('totals Income by source, lists recent Income and gives this month\'s Net', () {
        final text = SpendingContextBuilder.build(
          expenses: [octoberExpense],
          categories: categories,
          income: [
            income('i1', 100000, 'src_salary', DateTime.utc(2026, 10, 1)), // $1000.00
            income('i2', 25000, 'src_clinic', DateTime.utc(2026, 10, 12)), // $250.00
            income('i3', 100000, 'src_salary', DateTime.utc(2026, 9, 1)), // last month
          ],
          incomeSources: sources,
          today: DateTime(2026, 10, 17),
        );

        expect(text, contains('[USER INCOME SUMMARY]'));
        expect(text, contains('Total recorded income: \$2250.00'));
        expect(text, contains('- Salary: \$2000.00'));
        expect(text, contains('- Dental clinic: \$250.00'));
        expect(text, contains('- 2026-10-12: \$250.00 (Dental clinic)'));
        // October: 1250.00 in, 300.00 out.
        expect(text, contains('Net this month (income minus expenses): \$950.00'));
      });

      test('a negative Net is shown with a minus sign', () {
        final text = SpendingContextBuilder.build(
          expenses: [octoberExpense],
          categories: categories,
          income: [income('i1', 10000, 'src_salary', DateTime.utc(2026, 10, 1))],
          incomeSources: sources,
          today: DateTime(2026, 10, 17),
        );

        expect(text, contains('Net this month (income minus expenses): -\$200.00'));
      });

      test('with no Income the section says so and spending is still summarised', () {
        final text = SpendingContextBuilder.build(
          expenses: [octoberExpense],
          categories: categories,
          incomeSources: sources,
          today: DateTime(2026, 10, 17),
        );

        expect(text, contains('Total recorded expenses: \$300.00'));
        expect(text, contains('[USER INCOME SUMMARY]'));
        expect(text, contains('No income recorded yet'));
        expect(text, isNot(contains('Net this month')));
      });
    });
  });
}

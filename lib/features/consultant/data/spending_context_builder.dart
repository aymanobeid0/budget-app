import '../../categories/category.dart';
import '../../expenses/expense.dart';

/// Formats the user's spending ledger into a concise, structured text summary
/// suitable for injection into the Google Gemini consultant context.
class SpendingContextBuilder {
  const SpendingContextBuilder._();

  static String build({
    required List<Expense> expenses,
    required List<Category> categories,
  }) {
    if (expenses.isEmpty) {
      return '''
[USER SPENDING SUMMARY]
Total recorded expenses: \$0.00
No expenses recorded yet.
''';
    }

    final categoryMap = {for (final c in categories) c.id: c.name};

    var totalMinor = 0;
    final categoryTotalsMinor = <String, int>{};
    final recentExpenses = expenses.toList()
      ..sort((a, b) => b.spentOn.compareTo(a.spentOn));

    for (final exp in expenses) {
      totalMinor += exp.amountMinor;
      final catName = categoryMap[exp.categoryId] ?? 'Uncategorized';
      categoryTotalsMinor[catName] = (categoryTotalsMinor[catName] ?? 0) + exp.amountMinor;
    }

    final totalDollars = (totalMinor / 100.0).toStringAsFixed(2);

    // Sort categories by highest spend
    final sortedCategories = categoryTotalsMinor.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final highestCategory = sortedCategories.isNotEmpty ? sortedCategories.first.key : 'None';

    final buffer = StringBuffer()
      ..writeln('[USER SPENDING SUMMARY]')
      ..writeln('Total recorded expenses: \$$totalDollars')
      ..writeln('Highest spending category: $highestCategory')
      ..writeln('')
      ..writeln('Category Breakdown:');

    for (final entry in sortedCategories) {
      final amount = (entry.value / 100.0).toStringAsFixed(2);
      final pct = totalMinor > 0 ? ((entry.value / totalMinor) * 100).toStringAsFixed(1) : '0.0';
      buffer.writeln('- ${entry.key}: \$$amount ($pct%)');
    }

    buffer
      ..writeln('')
      ..writeln('Recent Expenses:');

    for (final exp in recentExpenses.take(10)) {
      final cat = categoryMap[exp.categoryId] ?? 'Uncategorized';
      final amount = (exp.amountMinor / 100.0).toStringAsFixed(2);
      buffer.writeln('- ${exp.spentOnIso}: \$$amount ($cat)');
    }

    return buffer.toString();
  }
}

import '../../../core/format/money.dart';
import '../../categories/category.dart';
import '../../expenses/expense.dart';
import '../../income/income.dart';
import '../../income/income_source.dart';
import '../../income/net.dart';

/// Formats the user's spending ledger, and their Income, into a concise,
/// structured text summary suitable for injection into the Google Gemini
/// consultant context.
class SpendingContextBuilder {
  const SpendingContextBuilder._();

  /// [incomeSources] should include deleted sources so past Income keeps
  /// its source's name. [today] fixes "this month" (defaults to now).
  static String build({
    required List<Expense> expenses,
    required List<Category> categories,
    List<Income> income = const [],
    List<IncomeSource> incomeSources = const [],
    DateTime? today,
  }) {
    return '${_spending(expenses, categories)}\n'
        '${_income(income, incomeSources, expenses, today ?? DateTime.now())}';
  }

  /// Amounts in the configured Currency, as the rest of the app shows them.
  static String _money(int minor) => Money.withLabel(minor);

  /// Income totals by source, recent Income and this month's Net, so the
  /// consultant can judge affordability and spot changes in income.
  static String _income(List<Income> income, List<IncomeSource> sources, List<Expense> expenses, DateTime today) {
    final buffer = StringBuffer()..writeln('[USER INCOME SUMMARY]');
    if (income.isEmpty) {
      buffer.writeln('No income recorded yet, so affordability cannot be judged from income.');
      return buffer.toString();
    }

    final sourceNames = {for (final s in sources) s.id: s.name};
    String nameOf(Income i) => sourceNames[i.sourceId] ?? 'Unknown source';

    var totalMinor = 0;
    final bySource = <String, int>{};
    for (final i in income) {
      totalMinor += i.amountMinor;
      bySource[nameOf(i)] = (bySource[nameOf(i)] ?? 0) + i.amountMinor;
    }
    final sortedSources = bySource.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final recent = income.toList()..sort((a, b) => b.paidOn.compareTo(a.paidOn));
    final month = calculateNet(income: income, expenses: expenses, period: NetPeriod.month, today: today);

    buffer
      ..writeln('Total recorded income: ${_money(totalMinor)}')
      ..writeln('Net this month (income minus expenses): ${_money(month.netMinor)} '
          '(income ${_money(month.incomeMinor)}, expenses ${_money(month.expensesMinor)})')
      ..writeln('')
      ..writeln('Income by Source:');
    for (final entry in sortedSources) {
      buffer.writeln('- ${entry.key}: ${_money(entry.value)}');
    }
    buffer
      ..writeln('')
      ..writeln('Income by Month and Source (latest 3 months):');
    final byMonth = <String, Map<String, int>>{};
    for (final i in recent) {
      final month = i.paidOnIso.substring(0, 7);
      final sources = byMonth.putIfAbsent(month, () => {});
      sources[nameOf(i)] = (sources[nameOf(i)] ?? 0) + i.amountMinor;
    }
    for (final month in byMonth.entries.take(3)) {
      final parts = month.value.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      buffer.writeln('- ${month.key}: ${parts.map((e) => '${e.key} ${_money(e.value)}').join(', ')}');
    }

    buffer
      ..writeln('')
      ..writeln('Recent Income:');
    for (final i in recent.take(10)) {
      buffer.writeln('- ${i.paidOnIso}: ${_money(i.amountMinor)} (${nameOf(i)})');
    }
    return buffer.toString();
  }

  static String _spending(List<Expense> expenses, List<Category> categories) {
    if (expenses.isEmpty) {
      return '''
[USER SPENDING SUMMARY]
Total recorded expenses: ${_money(0)}
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

    // Sort categories by highest spend
    final sortedCategories = categoryTotalsMinor.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final highestCategory = sortedCategories.isNotEmpty ? sortedCategories.first.key : 'None';

    final buffer = StringBuffer()
      ..writeln('[USER SPENDING SUMMARY]')
      ..writeln('Total recorded expenses: ${_money(totalMinor)}')
      ..writeln('Highest spending category: $highestCategory')
      ..writeln('')
      ..writeln('Category Breakdown:');

    for (final entry in sortedCategories) {
      final pct = totalMinor > 0 ? ((entry.value / totalMinor) * 100).toStringAsFixed(1) : '0.0';
      buffer.writeln('- ${entry.key}: ${_money(entry.value)} ($pct%)');
    }

    buffer
      ..writeln('')
      ..writeln('Recent Expenses:');

    for (final exp in recentExpenses.take(10)) {
      final cat = categoryMap[exp.categoryId] ?? 'Uncategorized';
      buffer.writeln('- ${exp.spentOnIso}: ${_money(exp.amountMinor)} ($cat)');
    }

    return buffer.toString();
  }
}

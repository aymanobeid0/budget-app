import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/format/money.dart';
import '../../../core/theme/app_theme.dart';
import '../cubit/currency_cubit.dart';

/// Lets the user pick the Currency every amount is labelled with. Closes on
/// a pick.
Future<void> showCurrencyPicker(BuildContext context) {
  final cubit = context.read<CurrencyCubit>();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true, // as tall as the list, scrolling on short screens
    useSafeArea: true,
    useRootNavigator: true, // above the nav bar
    builder: (sheetContext) {
      final scheme = Theme.of(sheetContext).colorScheme;
      return SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpace.gutter, 20, AppSpace.gutter, 4),
              child: Text('Currency', style: AppType.title.copyWith(color: scheme.onSurface)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpace.gutter, 0, AppSpace.gutter, 8),
              child: Text(
                'Shown next to every amount. Amounts are not converted.',
                style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
              ),
            ),
            for (final c in Currency.values)
              ListTile(
                key: Key('currency-option-${c.name}'),
                title: Text(c.code, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(c.label),
                trailing: c == cubit.state ? Icon(Icons.check_rounded, color: scheme.primary) : null,
                onTap: () {
                  cubit.select(c);
                  Navigator.of(sheetContext).pop();
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}

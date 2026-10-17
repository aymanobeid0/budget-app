import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/widgets.dart';
import '../../categories/ui/category_form_sheet.dart';
import '../../categories/ui/category_icon_helper.dart';
import '../cubit/income_cubit.dart';
import '../cubit/income_state.dart';
import '../income_source.dart';

/// Income Sources as a menu, styled like Categories. Reached from Profile.
class IncomeSourcesScreen extends StatelessWidget {
  const IncomeSourcesScreen({super.key});

  void _openSheet(BuildContext context, [IncomeSource? source]) {
    final cubit = context.read<IncomeCubit>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      useRootNavigator: true, // above the nav bar, so Save is never covered
      backgroundColor: Colors.transparent,
      builder: (_) => CategoryFormSheet(
        noun: 'Income Source',
        nameHint: 'e.g. Salary, Dental clinic',
        initialName: source?.name,
        initialIcon: source?.icon ?? 'work',
        initialColor: source?.color,
        onSave: (name, icon, color) {
          if (source == null) {
            cubit.addSource(name: name, icon: icon, color: color);
          } else {
            cubit.updateSource(source.copyWith(name: name, icon: icon, color: color));
          }
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, IncomeSource source) {
    final cubit = context.read<IncomeCubit>();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete Income Source?', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text('"${source.name}" leaves the picker. Income you already logged from it stays.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogCtx).pop(), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.expense,
              minimumSize: const Size(88, 44),
              padding: const EdgeInsets.symmetric(horizontal: 20),
            ),
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              cubit.deleteSource(source.id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      key: const Key('income-sources-screen'),
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<IncomeCubit, IncomeState>(
          builder: (context, state) {
            final header = ScreenHeader(
              title: 'Income Sources',
              leading: canPop
                  ? IconButton(
                      tooltip: 'Back',
                      icon: const Icon(Icons.arrow_back_rounded),
                      onPressed: () => context.pop(),
                    )
                  : null,
              trailing: SquareIconButton(
                key: const Key('add-income-source-btn'),
                icon: Icons.add_rounded,
                tooltip: 'Add Income Source',
                onTap: () => _openSheet(context),
              ),
            );

            if (state is IncomeError) {
              return Column(children: [
                header,
                Expanded(child: Center(child: Text('Error: ${state.message}', style: TextStyle(color: scheme.error)))),
              ]);
            }
            if (state is! IncomeLoaded) {
              return Column(children: [header, const Expanded(child: Center(child: CircularProgressIndicator()))]);
            }

            final sources = state.sources;
            return ListView(
              padding: const EdgeInsets.only(bottom: 130),
              children: [
                header,
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpace.gutter, 18, AppSpace.gutter, 8),
                  child: Text(
                    sources.isEmpty
                        ? 'No Income Sources yet'
                        : '${sources.length} ${sources.length == 1 ? 'source' : 'sources'} · tap one to edit',
                    style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      for (final s in sources) ...[
                        MenuRow(
                          key: Key('income-source-item-${s.id}'),
                          icon: CategoryIconHelper.getIcon(s.icon),
                          color: Color(s.color),
                          title: s.name,
                          showDivider: false,
                          onTap: () => _openSheet(context, s),
                          trailing: _RowMenu(
                            onEdit: () => _openSheet(context, s),
                            onDelete: () => _confirmDelete(context, s),
                          ),
                        ),
                        Divider(height: 1, indent: 8 + 36 + 14, endIndent: 8, color: scheme.outlineVariant),
                      ],
                      MenuRow(
                        key: const Key('add-income-source-row'),
                        icon: Icons.add_rounded,
                        color: scheme.primary,
                        title: 'Add Income Source',
                        showDivider: false,
                        onTap: () => _openSheet(context),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _RowMenu extends StatelessWidget {
  const _RowMenu({required this.onEdit, required this.onDelete});
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return PopupMenuButton<String>(
      tooltip: 'More options',
      icon: Icon(Icons.more_horiz_rounded, color: scheme.onSurfaceVariant),
      position: PopupMenuPosition.under,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      elevation: 6,
      onSelected: (v) => v == 'edit' ? onEdit() : onDelete(),
      itemBuilder: (_) => const [
        PopupMenuItem(
          value: 'edit',
          child: Row(children: [Icon(Icons.edit_outlined, size: 18), SizedBox(width: 10), Text('Edit')]),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(children: [
            Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.expense),
            SizedBox(width: 10),
            Text('Delete', style: TextStyle(color: AppColors.expense)),
          ]),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/widgets.dart';
import '../cubit/ai_provider_cubit.dart';
import '../models/ai_provider.dart';
import 'ai_provider_screen.dart';

/// Connect one AI Provider: paste the key, Test it (lists the models), pick
/// a model and Save (checks the model answers). A key can be saved even
/// when the check fails, after confirming.
class ProviderEditorSheet extends StatefulWidget {
  const ProviderEditorSheet({super.key, required this.kind});

  final AiProviderKind kind;

  @override
  State<ProviderEditorSheet> createState() => _ProviderEditorSheetState();
}

class _ProviderEditorSheetState extends State<ProviderEditorSheet> {
  final _keyController = TextEditingController();
  late final AiProviderCubit _cubit = context.read<AiProviderCubit>();
  late final SavedProvider? _saved = _cubit.state.saved[widget.kind];
  late String _model = _saved?.model ?? widget.kind.defaultModel;

  List<String>? _models;
  ProviderFailure? _testFailure;
  bool _tested = false;
  bool _busy = false;

  /// The key typed in the field, or null to keep the saved one.
  String? get _typedKey {
    final key = _keyController.text.trim();
    return key.isEmpty ? null : key;
  }

  bool get _hasKey => _typedKey != null || _saved != null;

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  void _keyChanged() => setState(() {
        _tested = false;
        _testFailure = null;
        _models = null;
      });

  Future<void> _test() async {
    setState(() => _busy = true);
    try {
      final models = await _cubit.listModels(widget.kind, _typedKey);
      if (!mounted) return;
      setState(() {
        _models = models;
        _testFailure = null;
        if (!models.contains(_model) && models.isNotEmpty) {
          _model = models.contains(widget.kind.defaultModel) ? widget.kind.defaultModel : models.first;
        }
      });
    } on ProviderFailure catch (failure) {
      if (mounted) setState(() => _testFailure = failure);
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _tested = true;
        });
      }
    }
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    final failure = await _cubit.store.check(widget.kind, _model, _typedKey);
    if (!mounted) return;
    setState(() => _busy = false);
    if (failure != null && !await _confirmSaveAnyway(failure)) return;
    await _cubit.save(widget.kind, apiKey: _typedKey, model: _model, failure: failure);
    if (mounted) Navigator.of(context).pop();
  }

  Future<bool> _confirmSaveAnyway(ProviderFailure failure) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(failure.outcome.label, style: const TextStyle(fontWeight: FontWeight.w700)),
        content: Text(
          '${widget.kind.displayName} didn\'t answer with $_model.'
          '${failure.message.isEmpty ? '' : '\n\n${failure.message}'}\n\nSave the key anyway?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogCtx).pop(false), child: const Text('Cancel')),
          FilledButton(
            key: const Key('save-anyway-btn'),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text('Save anyway'),
          ),
        ],
      ),
    );
    return yes ?? false;
  }

  Future<void> _remove() async {
    await _cubit.remove(widget.kind);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final models = _models;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
      ),
      padding: EdgeInsets.only(left: 24, right: 24, top: 14, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBorder : AppColors.handle,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.kind.displayName,
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, fontSize: 20),
                  ),
                ),
                if (_saved != null) KeyStatusChip(provider: _saved),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              key: const Key('provider-key-field'),
              controller: _keyController,
              obscureText: true,
              autocorrect: false,
              enableSuggestions: false,
              onChanged: (_) => _keyChanged(),
              decoration: InputDecoration(
                labelText: 'API key',
                hintText: _saved == null ? 'Paste your key' : 'Saved ${_saved.maskedKey} · paste to replace',
                helperText: 'Get one at ${widget.kind.keyUrl}',
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              key: const Key('test-connection-btn'),
              onPressed: _busy || !_hasKey ? null : _test,
              icon: const Icon(Icons.wifi_tethering_rounded),
              label: const Text('Test connection'),
            ),
            if (_tested) ...[
              const SizedBox(height: 12),
              _TestResult(failure: _testFailure, modelCount: models?.length ?? 0),
            ],
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              // Keyed by the model so a Test that picks another one shows it.
              key: ValueKey('provider-model-field-$_model'),
              initialValue: _model,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Model',
                helperText: models == null ? 'Test the key to see every model' : null,
              ),
              items: [
                for (final m in {...?models, _model}) DropdownMenuItem(value: m, child: Text(m, overflow: TextOverflow.ellipsis)),
              ],
              onChanged: models == null ? null : (m) => setState(() => _model = m ?? _model),
            ),
            const SizedBox(height: 16),
            Text(
              'When you chat, your Expense and Income summary is sent to ${widget.kind.displayName} under your own account.',
              style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              key: const Key('save-provider-btn'),
              label: 'Save',
              busy: _busy,
              onPressed: _hasKey ? _save : null,
            ),
            if (_saved != null) ...[
              const SizedBox(height: 8),
              TextButton(
                key: const Key('remove-key-btn'),
                onPressed: _busy ? null : _remove,
                style: TextButton.styleFrom(foregroundColor: AppColors.expense),
                child: const Text('Remove key'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TestResult extends StatelessWidget {
  const _TestResult({required this.failure, required this.modelCount});

  final ProviderFailure? failure;
  final int modelCount;

  @override
  Widget build(BuildContext context) {
    final ok = failure == null;
    final color = ok ? AppColors.income : AppColors.expense;
    return Container(
      key: const Key('test-result'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(AppRadius.md)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(ok ? Icons.check_circle_rounded : Icons.error_outline_rounded, size: 20, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ok ? 'Connected · $modelCount models' : failure!.outcome.label,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color),
                ),
                if (!ok && failure!.message.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(failure!.message, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

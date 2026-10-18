import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'sync_engine.dart';
import 'sync_status.dart';

/// The app's [SyncEngine], or null in a local-only build (no Supabase).
SyncEngine? maybeSyncEngine(BuildContext context) {
  try {
    return RepositoryProvider.of<SyncEngine>(context);
  } catch (_) {
    return null;
  }
}

/// Rebuilds with the engine's live [SyncState].
class SyncStateBuilder extends StatelessWidget {
  const SyncStateBuilder({super.key, required this.engine, required this.builder});

  final SyncEngine engine;
  final Widget Function(BuildContext context, SyncState state) builder;

  @override
  Widget build(BuildContext context) => StreamBuilder<SyncState>(
        stream: engine.statusStream,
        initialData: engine.currentState,
        builder: (context, snap) => builder(context, snap.data ?? engine.currentState),
      );
}

/// Offline or a failed sync: the data is safe on the phone but not yet in
/// the account.
bool syncNeedsAttention(SyncState state) => state == SyncState.offline || state == SyncState.error;

/// One line saying where the user's data is. [short] drops the "not yet in
/// your account" tail, for Home's chip.
String syncStateLabel(SyncState state, {bool short = false}) => switch (state) {
      SyncState.idle => 'Waiting to sync',
      SyncState.syncing => 'Syncing…',
      SyncState.success => 'Synced · your data is in your account',
      SyncState.offline || SyncState.error =>
        '${state == SyncState.offline ? 'Offline' : "Couldn't sync"} · saved on this phone'
            '${short ? '' : ', not yet in your account'}',
    };

/// Home's quiet "not synced" chip, shown only while [syncNeedsAttention].
class SyncAttentionIndicator extends StatelessWidget {
  const SyncAttentionIndicator({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final engine = maybeSyncEngine(context);
    if (engine == null) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return SyncStateBuilder(
      engine: engine,
      builder: (context, state) {
        if (!syncNeedsAttention(state)) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Center(
            child: InkWell(
              key: const Key('sync-attention'),
              onTap: onTap,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cloud_off_rounded, size: 16, color: scheme.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        syncStateLabel(state, short: true),
                        style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

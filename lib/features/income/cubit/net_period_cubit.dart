import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../net.dart';

/// Where the Net period picked on Home is remembered between launches.
abstract class NetPeriodStorage {
  Future<NetPeriod?> read();
  Future<void> write(NetPeriod period);
}

/// Keeps the choice in memory only (tests).
class InMemoryNetPeriodStorage implements NetPeriodStorage {
  NetPeriod? _period;

  @override
  Future<NetPeriod?> read() async => _period;

  @override
  Future<void> write(NetPeriod period) async => _period = period;
}

/// Persists the choice as a one-word file next to the other local prefs.
class FileNetPeriodStorage implements NetPeriodStorage {
  Future<File> _file() async {
    final dir = await getApplicationSupportDirectory();
    return File(p.join(dir.path, 'net_period.txt'));
  }

  @override
  Future<NetPeriod?> read() async {
    try {
      final file = await _file();
      if (!await file.exists()) return null;
      final name = (await file.readAsString()).trim();
      return NetPeriod.values.where((v) => v.name == name).firstOrNull;
    } catch (_) {
      return null; // unreadable → fall back to the default
    }
  }

  @override
  Future<void> write(NetPeriod period) async {
    try {
      final file = await _file();
      await file.parent.create(recursive: true);
      await file.writeAsString(period.name);
    } catch (_) {
      // The switch still works for this session even if saving fails.
    }
  }
}

/// The period Home shows the Net for. This month until the user picks
/// another; then their last pick.
class NetPeriodCubit extends Cubit<NetPeriod> {
  NetPeriodCubit({NetPeriodStorage? storage, NetPeriod initial = NetPeriod.month})
      : _storage = storage ?? InMemoryNetPeriodStorage(),
        super(initial);

  final NetPeriodStorage _storage;

  void select(NetPeriod period) {
    if (period == state) return;
    emit(period);
    _storage.write(period);
  }
}

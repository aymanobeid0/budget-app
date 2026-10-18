import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/prefs/text_pref.dart';
import '../net.dart';

/// Where the Net period picked on Home is remembered between launches.
class NetPeriodStorage extends EnumPref<NetPeriod> {
  NetPeriodStorage(TextPref text) : super(NetPeriod.values, text);

  /// On the device, as `net_period.txt` next to the other local prefs.
  NetPeriodStorage.file() : this(FileTextPref('net_period.txt'));

  /// In memory only (tests).
  NetPeriodStorage.inMemory() : this(InMemoryTextPref());
}

/// The period Home shows the Net for. This month until the user picks
/// another; then their last pick.
class NetPeriodCubit extends Cubit<NetPeriod> {
  NetPeriodCubit({NetPeriodStorage? storage, NetPeriod initial = NetPeriod.month})
      : _storage = storage ?? NetPeriodStorage.inMemory(),
        super(initial);

  final NetPeriodStorage _storage;

  void select(NetPeriod period) {
    if (period == state) return;
    emit(period);
    _storage.write(period);
  }
}

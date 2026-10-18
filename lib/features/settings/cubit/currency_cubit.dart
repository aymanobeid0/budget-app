import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/format/money.dart';
import '../../../core/prefs/text_pref.dart';

/// Where the Currency picked in Settings is remembered between launches.
class CurrencyStorage extends EnumPref<Currency> {
  CurrencyStorage(TextPref text) : super(Currency.values, text);

  /// On the device, as `currency.txt` next to the other local prefs.
  CurrencyStorage.file() : this(FileTextPref('currency.txt'));

  /// In memory only (tests), optionally with a choice already [saved].
  CurrencyStorage.inMemory([Currency? saved]) : this(InMemoryTextPref(saved?.name));
}

/// The Currency every amount label shows. [Currency.fallback] until the user
/// picks another; then their last pick.
class CurrencyCubit extends Cubit<Currency> {
  CurrencyCubit({CurrencyStorage? storage, Currency initial = Currency.fallback})
      : _storage = storage ?? CurrencyStorage.inMemory(),
        super(initial);

  final CurrencyStorage _storage;

  void select(Currency currency) {
    if (currency == state) return;
    emit(currency);
    _storage.write(currency);
  }
}

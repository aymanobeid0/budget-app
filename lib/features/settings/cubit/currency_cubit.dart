import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/format/money.dart';

/// Where the Currency picked in Settings is remembered between launches.
abstract class CurrencyStorage {
  Future<Currency?> read();
  Future<void> write(Currency currency);
}

/// Keeps the choice in memory only (tests).
class InMemoryCurrencyStorage implements CurrencyStorage {
  InMemoryCurrencyStorage([this._currency]);

  Currency? _currency;

  @override
  Future<Currency?> read() async => _currency;

  @override
  Future<void> write(Currency currency) async => _currency = currency;
}

/// Persists the choice as a one-word file next to the other local prefs.
class FileCurrencyStorage implements CurrencyStorage {
  Future<File> _file() async {
    final dir = await getApplicationSupportDirectory();
    return File(p.join(dir.path, 'currency.txt'));
  }

  @override
  Future<Currency?> read() async {
    try {
      final file = await _file();
      if (!await file.exists()) return null;
      final name = (await file.readAsString()).trim();
      return Currency.values.where((v) => v.name == name).firstOrNull;
    } catch (_) {
      return null; // unreadable → fall back to the default
    }
  }

  @override
  Future<void> write(Currency currency) async {
    try {
      final file = await _file();
      await file.parent.create(recursive: true);
      await file.writeAsString(currency.name);
    } catch (_) {
      // The choice still works for this session even if saving fails.
    }
  }
}

/// The Currency every amount label shows. MRU until the user picks another;
/// then their last pick.
class CurrencyCubit extends Cubit<Currency> {
  CurrencyCubit({CurrencyStorage? storage, Currency initial = Currency.mru})
      : _storage = storage ?? InMemoryCurrencyStorage(),
        super(initial);

  final CurrencyStorage _storage;

  void select(Currency currency) {
    if (currency == state) return;
    emit(currency);
    _storage.write(currency);
  }
}

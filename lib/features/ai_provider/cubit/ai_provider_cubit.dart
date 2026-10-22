import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/ai_provider_store.dart';
import '../models/ai_provider.dart';

/// The saved AI Providers for Settings and the Consultant; every change goes
/// through [AiProviderStore].
class AiProviderCubit extends Cubit<AiProviderSettings> {
  AiProviderCubit(this.store) : super(store.settings) {
    // A chat call can change a key's status while Settings is open.
    _changes = store.changes.listen(emit);
  }

  final AiProviderStore store;
  late final StreamSubscription<AiProviderSettings> _changes;

  /// The providers this build can talk to, in display order.
  List<AiProviderKind> get providers => store.providers;

  Future<void> load() async => emit(await store.load());

  /// Lists [kind]'s models with [apiKey] (or the saved key, whose status
  /// then follows the result). Throws a `ProviderFailure`.
  Future<List<String>> listModels(AiProviderKind kind, [String? apiKey]) async {
    try {
      return await store.listModels(kind, apiKey);
    } finally {
      if (!isClosed) emit(store.settings);
    }
  }

  /// Checks [apiKey] (or the saved key) and that the typed [model] exists,
  /// for a provider whose model is typed. Throws a `ProviderFailure`.
  Future<void> testModel(AiProviderKind kind, String model, [String? apiKey]) async {
    try {
      await store.testModel(kind, model, apiKey);
    } finally {
      if (!isClosed) emit(store.settings);
    }
  }

  /// The check before saving: a one-token request to [model] with [apiKey]
  /// (or the saved key). Null when it answered, otherwise why not.
  Future<ProviderFailure?> ping(AiProviderKind kind, String model, [String? apiKey]) =>
      store.ping(kind, model, apiKey);

  Future<void> save(AiProviderKind kind, {String? apiKey, required String model, ProviderFailure? failure}) async =>
      emit(await store.save(kind, apiKey: apiKey, model: model, failure: failure));

  Future<void> remove(AiProviderKind kind) async => emit(await store.remove(kind));

  /// Makes [kind], already saved, the provider the Consultant answers with.
  Future<void> setActive(AiProviderKind kind) async => emit(await store.setActive(kind));

  @override
  Future<void> close() async {
    await _changes.cancel();
    return super.close();
  }
}

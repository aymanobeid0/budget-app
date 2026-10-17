import 'package:supabase_flutter/supabase_flutter.dart';

/// Contract for communicating with the remote Supabase PostgreSQL backend.
abstract class CloudSyncClient {
  String? get currentUserId;
  Future<String?> ensureAuthenticated();
  Future<void> upsertCategories(List<Map<String, dynamic>> categories);
  Future<void> upsertExpenses(List<Map<String, dynamic>> expenses);
  Future<List<Map<String, dynamic>>> fetchCategories();
  Future<List<Map<String, dynamic>>> fetchExpenses();
  Future<void> upsertIncomeSources(List<Map<String, dynamic>> incomeSources);
  Future<void> upsertIncome(List<Map<String, dynamic>> income);
  Future<List<Map<String, dynamic>>> fetchIncomeSources();
  Future<List<Map<String, dynamic>>> fetchIncome();
}

/// Production Supabase implementation adhering strictly to RLS policies.
class SupabaseCloudSyncClient implements CloudSyncClient {
  SupabaseCloudSyncClient(this._client);

  final SupabaseClient _client;

  @override
  String? get currentUserId => _client.auth.currentUser?.id;

  @override
  Future<String?> ensureAuthenticated() async {
    final current = _client.auth.currentUser;
    if (current != null) return current.id;

    // Anonymous authentication handshake
    final authResponse = await _client.auth.signInAnonymously();
    return authResponse.user?.id;
  }

  @override
  Future<void> upsertCategories(List<Map<String, dynamic>> categories) async {
    if (categories.isEmpty) return;
    // Composite key (see migration 20261016000000_per_user_keys.sql).
    await _client.from('categories').upsert(categories, onConflict: 'user_id,id');
  }

  @override
  Future<void> upsertExpenses(List<Map<String, dynamic>> expenses) async {
    if (expenses.isEmpty) return;
    // Composite key (see migration 20261016000000_per_user_keys.sql).
    await _client.from('expenses').upsert(expenses, onConflict: 'user_id,id');
  }

  @override
  Future<List<Map<String, dynamic>>> fetchCategories() async {
    final response = await _client.from('categories').select();
    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchExpenses() async {
    final response = await _client.from('expenses').select();
    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Future<void> upsertIncomeSources(List<Map<String, dynamic>> incomeSources) async {
    if (incomeSources.isEmpty) return;
    // See migration 20261017000000_income.sql.
    await _client.from('income_sources').upsert(incomeSources, onConflict: 'user_id,id');
  }

  @override
  Future<void> upsertIncome(List<Map<String, dynamic>> income) async {
    if (income.isEmpty) return;
    await _client.from('income').upsert(income, onConflict: 'user_id,id');
  }

  @override
  Future<List<Map<String, dynamic>>> fetchIncomeSources() async {
    final response = await _client.from('income_sources').select();
    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchIncome() async {
    final response = await _client.from('income').select();
    return List<Map<String, dynamic>>.from(response);
  }
}

# When to Mock

Mock at **system boundaries** only:

- External APIs (in this repo: Supabase through `CloudSyncClient` and `AuthGateway`, Gemini through `ConsultantClient`)
- Databases (sometimes - prefer test DB: here, a real in-memory SQLite via `AppDatabase.open(factory: databaseFactoryFfi, path: inMemoryDatabasePath)`)
- Time/randomness
- File system (sometimes)

Don't mock:

- Your own classes/modules (`ExpenseLedger`, `IncomeLedger`, `CategoryStore`, Cubits)
- Internal collaborators
- Anything you control

Prefer a hand-written fake that `implements` the boundary interface (the repo's `FakeCloud implements CloudSyncClient` records what was pushed and serves remote rows) over a mocking library. No mocking package is a dependency, and adding one is a decision for the user.

## Designing for Mockability

At system boundaries, design interfaces that are easy to mock:

**1. Use dependency injection**

Pass external dependencies in through the constructor rather than creating them internally:

```dart
// Easy to fake (how SyncEngine is built)
class SyncEngine {
  SyncEngine({required this.db, required this.client});
  final AppDatabase db;
  final CloudSyncClient client;
}

// Hard to fake
class SyncEngine {
  final client = SupabaseCloudSyncClient(Supabase.instance.client);
}
```

**2. Prefer SDK-style interfaces over generic fetchers**

Create specific methods for each external operation instead of one generic method with conditional logic:

```dart
// GOOD: Each method is independently fakeable
abstract class CloudSyncClient {
  Future<void> upsertExpenses(List<Map<String, dynamic>> rows);
  Future<List<Map<String, dynamic>>> fetchExpenses();
}

// BAD: Faking requires conditional logic inside the fake
abstract class CloudSyncClient {
  Future<Object?> call(String table, String op, [Object? body]);
}
```

The SDK approach means:
- Each fake returns one specific shape
- No conditional logic in test setup
- Easier to see which endpoints a test exercises
- Type safety per endpoint

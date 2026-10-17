enum SyncState {
  idle,
  syncing,
  success,
  error,
  offline,
}

class SyncResult {
  const SyncResult({
    required this.isSuccess,
    this.categoriesSynced = 0,
    this.expensesSynced = 0,
    this.incomeSourcesSynced = 0,
    this.incomeSynced = 0,
    this.errorMessage,
  });

  final bool isSuccess;
  final int categoriesSynced;
  final int expensesSynced;
  final int incomeSourcesSynced;
  final int incomeSynced;
  final String? errorMessage;

  factory SyncResult.success({int categories = 0, int expenses = 0, int incomeSources = 0, int income = 0}) {
    return SyncResult(
      isSuccess: true,
      categoriesSynced: categories,
      expensesSynced: expenses,
      incomeSourcesSynced: incomeSources,
      incomeSynced: income,
    );
  }

  factory SyncResult.failure(String message) {
    return SyncResult(
      isSuccess: false,
      errorMessage: message,
    );
  }
}

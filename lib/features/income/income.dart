import 'package:equatable/equatable.dart';

/// Money received, logged by the user (GLOSSARY.md: Income).
///
/// Same shape as an Expense but its own record (ADR 0006): amount, Income
/// Source and the calendar date it was paid on. No notes, percentages or
/// recurrence.
class Income extends Equatable {
  const Income({
    required this.id,
    required this.amountMinor,
    required this.sourceId,
    required this.paidOn,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.syncedAt,
  });

  final String id;

  /// Amount in integer minor units, always above zero.
  final int amountMinor;

  final String sourceId;

  /// The calendar date the money was paid on.
  final DateTime paidOn;

  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final DateTime? syncedAt;

  /// Formatted date string (YYYY-MM-DD) for SQLite index ordering.
  String get paidOnIso =>
      '${paidOn.year.toString().padLeft(4, '0')}-'
      '${paidOn.month.toString().padLeft(2, '0')}-'
      '${paidOn.day.toString().padLeft(2, '0')}';

  Income copyWith({
    int? amountMinor,
    String? sourceId,
    DateTime? paidOn,
    DateTime? updatedAt,
  }) {
    return Income(
      id: id,
      amountMinor: amountMinor ?? this.amountMinor,
      sourceId: sourceId ?? this.sourceId,
      paidOn: paidOn ?? this.paidOn,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt,
      syncedAt: syncedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount_minor': amountMinor,
      'source_id': sourceId,
      'paid_on': paidOnIso,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
      'deleted_at': deletedAt?.millisecondsSinceEpoch,
      'synced_at': syncedAt?.millisecondsSinceEpoch,
    };
  }

  factory Income.fromMap(Map<String, dynamic> map) {
    final parts = (map['paid_on'] as String).split('-');
    DateTime? millis(Object? v) => v == null ? null : DateTime.fromMillisecondsSinceEpoch(v as int);
    return Income(
      id: map['id'] as String,
      amountMinor: map['amount_minor'] as int,
      sourceId: map['source_id'] as String,
      paidOn: DateTime.utc(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2])),
      createdAt: millis(map['created_at'])!,
      updatedAt: millis(map['updated_at'])!,
      deletedAt: millis(map['deleted_at']),
      syncedAt: millis(map['synced_at']),
    );
  }

  @override
  List<Object?> get props => [id, amountMinor, sourceId, paidOn, createdAt, updatedAt, deletedAt, syncedAt];
}

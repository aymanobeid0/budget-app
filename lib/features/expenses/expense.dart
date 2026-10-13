import 'package:equatable/equatable.dart';

/// Domain entity representing a recorded expense.
///
/// Follows ADR 0002: strictly minimalist schema capturing only
/// amount, category, and date (no notes, receipts, or caps).
class Expense extends Equatable {
  const Expense({
    required this.id,
    required this.amountMinor,
    required this.categoryId,
    required this.spentOn,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.syncedAt,
  });

  final String id;

  /// Amount in integer minor units (e.g., cents, $15.50 -> 1550).
  final int amountMinor;

  final String categoryId;

  /// The calendar date on which the expense was incurred.
  final DateTime spentOn;

  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final DateTime? syncedAt;

  /// Amount formatted as a standard decimal value.
  double get amount => amountMinor / 100.0;

  /// Formatted date string (YYYY-MM-DD) for SQLite index ordering.
  String get spentOnIso =>
      '${spentOn.year.toString().padLeft(4, '0')}-'
      '${spentOn.month.toString().padLeft(2, '0')}-'
      '${spentOn.day.toString().padLeft(2, '0')}';

  Expense copyWith({
    String? id,
    int? amountMinor,
    String? categoryId,
    DateTime? spentOn,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    DateTime? syncedAt,
  }) {
    return Expense(
      id: id ?? this.id,
      amountMinor: amountMinor ?? this.amountMinor,
      categoryId: categoryId ?? this.categoryId,
      spentOn: spentOn ?? this.spentOn,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      syncedAt: syncedAt ?? this.syncedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount_minor': amountMinor,
      'category_id': categoryId,
      'spent_on': spentOnIso,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
      'deleted_at': deletedAt?.millisecondsSinceEpoch,
      'synced_at': syncedAt?.millisecondsSinceEpoch,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    final spentOnParts = (map['spent_on'] as String).split('-');
    final spentOnDate = DateTime.utc(
      int.parse(spentOnParts[0]),
      int.parse(spentOnParts[1]),
      int.parse(spentOnParts[2]),
    );

    return Expense(
      id: map['id'] as String,
      amountMinor: map['amount_minor'] as int,
      categoryId: map['category_id'] as String,
      spentOn: spentOnDate,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
      deletedAt: map['deleted_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['deleted_at'] as int)
          : null,
      syncedAt: map['synced_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['synced_at'] as int)
          : null,
    );
  }

  @override
  List<Object?> get props => [
        id,
        amountMinor,
        categoryId,
        spentOn,
        createdAt,
        updatedAt,
        deletedAt,
        syncedAt,
      ];
}

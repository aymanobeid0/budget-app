import 'package:equatable/equatable.dart';

/// Where an Income came from, e.g. Salary or Dental clinic
/// (GLOSSARY.md: Income Source). Shaped like a Category but never shared
/// with Categories (ADR 0006).
class IncomeSource extends Equatable {
  const IncomeSource({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  final String id;
  final String name;
  final String icon;
  final int color;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  IncomeSource copyWith({String? name, String? icon, int? color, DateTime? updatedAt}) {
    return IncomeSource(
      id: id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'color': color,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
      'deleted_at': deletedAt?.millisecondsSinceEpoch,
    };
  }

  factory IncomeSource.fromMap(Map<String, dynamic> map) {
    return IncomeSource(
      id: map['id'] as String,
      name: map['name'] as String,
      icon: map['icon'] as String,
      color: map['color'] as int,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
      deletedAt: map['deleted_at'] != null ? DateTime.fromMillisecondsSinceEpoch(map['deleted_at'] as int) : null,
    );
  }

  @override
  List<Object?> get props => [id, name, icon, color, createdAt, updatedAt, deletedAt];
}

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../data/database.dart';
import '../../../data/tables.dart';

part 'category_repository.g.dart';

@riverpod
class CategoryRepository extends _$CategoryRepository {
  @override
  void build() {}

  // Add Custom Category
  Future<int> addCategory(String name, String type) async {
    final db = ref.read(databaseProvider);
    return await db.into(db.categories).insert(CategoriesCompanion.insert(
      name: name,
      type: type,
      isSystem: const Value(false),
    ));
  }
}

// Provider for Income Categories
final incomeCategoriesProvider = StreamProvider<List<Category>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.categories)
    ..where((t) => t.type.equals('INCOME'))
    ..orderBy([(t) => OrderingTerm(expression: t.name)])
  ).watch();
});

// Provider for Expense Categories
final expenseCategoriesProvider = StreamProvider<List<Category>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.categories)
    ..where((t) => t.type.equals('EXPENSE'))
    ..orderBy([(t) => OrderingTerm(expression: t.name)])
  ).watch();
});

// Initialize Default Categories (Call this in main.dart or database creation)
Future<void> seedCategories(AppDatabase db) async {
  final count = await db.select(db.categories).get().then((l) => l.length);
  if (count == 0) {
    // Default Income
    for(var c in ['Sales', 'Salary', 'Refund', 'Gift', 'Others']) {
      await db.into(db.categories).insert(CategoriesCompanion.insert(name: c, type: 'INCOME', isSystem: const Value(true)));
    }
    // Default Expense
    for(var c in ['Purchase', 'Rent', 'Food', 'Transport', 'Bills', 'Health', 'Entertainment', 'Others']) {
      await db.into(db.categories).insert(CategoriesCompanion.insert(name: c, type: 'EXPENSE', isSystem: const Value(true)));
    }
  }
}
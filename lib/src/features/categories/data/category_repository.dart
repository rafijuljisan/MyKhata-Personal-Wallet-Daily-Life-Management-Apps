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

  // 1. Add Custom Category
  Future<int> addCategory(String name, String type) async {
    final db = ref.read(databaseProvider);
    return await db.into(db.categories).insert(CategoriesCompanion.insert(
      name: name,
      type: type,
      isSystem: const Value(false),
    ));
  }

  // 2. Update Category (NEW)
  Future<void> updateCategory({required int id, required String name, required String type}) async {
    final db = ref.read(databaseProvider);
    await (db.update(db.categories)..where((t) => t.id.equals(id))).write(
      CategoriesCompanion(
        name: Value(name),
        type: Value(type),
      ),
    );
  }

  // 3. Delete Category (NEW)
  Future<void> deleteCategory(int id) async {
    final db = ref.read(databaseProvider);
    // Note: You might want to check if transactions exist for this category first
    // But for now, we just delete the category. Transactions will show "null" or break depending on join logic.
    await (db.delete(db.categories)..where((t) => t.id.equals(id))).go();
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

// Initialize Default Categories
Future<void> seedCategories(AppDatabase db) async {
  final count = await db.select(db.categories).get().then((l) => l.length);
  if (count == 0) {
    for(var c in ['Sales', 'Salary', 'Refund', 'Gift', 'Others']) {
      await db.into(db.categories).insert(CategoriesCompanion.insert(name: c, type: 'INCOME', isSystem: const Value(true)));
    }
    for(var c in ['Purchase', 'Rent', 'Food', 'Transport', 'Bills', 'Health', 'Entertainment', 'Others']) {
      await db.into(db.categories).insert(CategoriesCompanion.insert(name: c, type: 'EXPENSE', isSystem: const Value(true)));
    }
  }
}
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:rxdart/rxdart.dart'; // ADDED THIS IMPORT
import 'package:my_khata/src/data/database.dart';
import 'package:my_khata/src/data/tables.dart';

part 'budget_repository.g.dart';

@riverpod
class BudgetRepository extends _$BudgetRepository {
  @override
  void build() {}

  // Set or Update Budget
  Future<void> setBudget({
    required int categoryId,
    required double limitAmount,
    required int month,
    required int year,
  }) async {
    final db = ref.read(databaseProvider);
    
    // Check if exists
    final existing = await (db.select(db.budgets)
      ..where((t) => 
        t.categoryId.equals(categoryId) & 
        t.month.equals(month) & 
        t.year.equals(year))
    ).getSingleOrNull();

    if (existing != null) {
      // Update
      await (db.update(db.budgets)..where((t) => t.id.equals(existing.id)))
          .write(BudgetsCompanion(limitAmount: Value(limitAmount)));
    } else {
      // Insert
      await db.into(db.budgets).insert(BudgetsCompanion.insert(
        categoryId: categoryId,
        limitAmount: limitAmount,
        month: month,
        year: year,
      ));
    }
  }
}

// Data Class for UI
class BudgetStatus {
  final Category category;
  final double limit;
  final double spent;
  
  double get progress => limit == 0 ? 0 : (spent / limit).clamp(0.0, 1.0);
  bool get isOverBudget => spent > limit;
  bool get isNearLimit => spent > (limit * 0.8) && !isOverBudget;

  BudgetStatus({required this.category, required this.limit, required this.spent});
}

// Provider: Get Budgets + Spending for a specific month
final budgetStatusProvider = StreamProvider.family<List<BudgetStatus>, DateTime>((ref, date) {
  final db = ref.watch(databaseProvider);
  final month = date.month;
  final year = date.year;

  // 1. Get Expense Categories
  final categoriesStream = (db.select(db.categories)..where((t) => t.type.equals('EXPENSE'))).watch();

  // 2. Get Budgets for this month
  final budgetsStream = (db.select(db.budgets)
    ..where((t) => t.month.equals(month) & t.year.equals(year))).watch();

  // 3. Get Transactions (Spending) for this month
  final startOfMonth = DateTime(year, month, 1);
  final endOfMonth = DateTime(year, month + 1, 0, 23, 59, 59);
  
  final transactionsStream = (db.select(db.transactions)
    ..where((t) => t.txnType.equals('CASH_OUT') & 
                   t.date.isBetweenValues(startOfMonth, endOfMonth))).watch();

  return Rx.combineLatest3(categoriesStream, budgetsStream, transactionsStream, 
    (List<Category> categories, List<Budget> budgets, List<Transaction> txns) {
      
      return categories.map((cat) {
        // Find set limit (default to 0 if not set)
        final budget = budgets.firstWhere((b) => b.categoryId == cat.id, orElse: () => 
          Budget(id: -1, categoryId: cat.id, limitAmount: 0.0, month: month, year: year));
        
        // Calculate spent for this category
        final spent = txns.where((t) => t.categoryId == cat.id).fold(0.0, (sum, t) => sum + t.amount);

        return BudgetStatus(category: cat, limit: budget.limitAmount, spent: spent);
      }).toList();
    }
  );
});
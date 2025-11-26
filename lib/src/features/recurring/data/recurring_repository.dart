import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:my_khata/src/data/database.dart';
import 'package:my_khata/src/data/tables.dart';

part 'recurring_repository.g.dart';

@riverpod
class RecurringRepository extends _$RecurringRepository {
  @override
  void build() {}

  // Add Recurring Bill
  Future<void> addRecurring({
    required String name,
    required double amount,
    required String type, 
    required int categoryId,
    required String frequency, // DAILY, WEEKLY, MONTHLY, YEARLY
    required DateTime firstDueDate, 
  }) async {
    final db = ref.read(databaseProvider);
    
    await db.into(db.recurringTransactions).insert(RecurringTransactionsCompanion.insert(
      name: name,
      amount: amount,
      type: type,
      categoryId: categoryId,
      frequency: Value(frequency),
      dayOfMonth: firstDueDate.day,
      nextDueDate: firstDueDate,
    ));
  }

  // NEW: Update Recurring Bill
  Future<void> updateRecurring({
    required int id,
    required String name,
    required double amount,
    required int categoryId,
    required String frequency,
    required DateTime nextDueDate,
  }) async {
    final db = ref.read(databaseProvider);
    await (db.update(db.recurringTransactions)..where((t) => t.id.equals(id))).write(
      RecurringTransactionsCompanion(
        name: Value(name),
        amount: Value(amount),
        categoryId: Value(categoryId),
        frequency: Value(frequency),
        nextDueDate: Value(nextDueDate),
        dayOfMonth: Value(nextDueDate.day), // Update day reference just in case
      ),
    );
  }

  // Mark as Paid
  Future<void> markAsPaid(int id) async {
    final db = ref.read(databaseProvider);
    final item = await (db.select(db.recurringTransactions)..where((t) => t.id.equals(id))).getSingle();
    
    final now = DateTime.now();
    
    // Calculate NEW next due date based on Frequency
    DateTime nextDue = item.nextDueDate;
    
    switch (item.frequency) {
      case 'DAILY':
        nextDue = nextDue.add(const Duration(days: 1));
        if (nextDue.isBefore(now)) nextDue = now.add(const Duration(days: 1));
        break;
      case 'WEEKLY':
        nextDue = nextDue.add(const Duration(days: 7));
        if (nextDue.isBefore(now)) nextDue = now.add(const Duration(days: 7));
        break;
      case 'YEARLY':
        nextDue = DateTime(nextDue.year + 1, nextDue.month, nextDue.day);
        if (nextDue.isBefore(now)) nextDue = DateTime(now.year + 1, nextDue.month, nextDue.day);
        break;
      case 'MONTHLY':
      default:
        nextDue = DateTime(nextDue.year, nextDue.month + 1, item.dayOfMonth);
        if (nextDue.isBefore(now)) nextDue = DateTime(now.year, now.month + 1, item.dayOfMonth);
        break;
    }

    await (db.update(db.recurringTransactions)..where((t) => t.id.equals(id))).write(
      RecurringTransactionsCompanion(
        lastPaidDate: Value(now),
        nextDueDate: Value(nextDue),
      ),
    );
  }
  
  Future<void> deleteRecurring(int id) async {
     final db = ref.read(databaseProvider);
     await (db.delete(db.recurringTransactions)..where((t) => t.id.equals(id))).go();
  }
}

final upcomingBillsProvider = StreamProvider<List<RecurringTransaction>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.recurringTransactions)
    ..orderBy([(t) => OrderingTerm(expression: t.nextDueDate)]))
    .watch();
});
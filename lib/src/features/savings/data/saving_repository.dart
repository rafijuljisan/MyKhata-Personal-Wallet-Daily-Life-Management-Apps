import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:my_khata/src/data/database.dart';
import 'package:my_khata/src/data/tables.dart';
import '../../wallets/data/wallet_provider.dart';

part 'saving_repository.g.dart';

@riverpod
class SavingRepository extends _$SavingRepository {
  @override
  void build() {}

  // 1. Create a Goal
  Future<void> addGoal({
    required String name,
    required double targetAmount,
    required DateTime? targetDate,
  }) async {
    final db = ref.read(databaseProvider);
    await db.into(db.savingGoals).insert(SavingGoalsCompanion.insert(
      name: name,
      targetAmount: targetAmount,
      targetDate: Value(targetDate),
      currentAmount: const Value(0.0),
    ));
  }

  // 2. Add Money to Goal (Deposit)
  // confirmTransaction: If true, we also deduct this money from the Wallet (Expense)
  Future<void> depositToGoal({
    required int goalId,
    required double amount,
    required bool createTransaction,
    required String goalName,
  }) async {
    final db = ref.read(databaseProvider);
    
    // 1. Update Goal Progress
    final goal = await (db.select(db.savingGoals)..where((t) => t.id.equals(goalId))).getSingle();
    final newAmount = goal.currentAmount + amount;
    
    await (db.update(db.savingGoals)..where((t) => t.id.equals(goalId))).write(
      SavingGoalsCompanion(currentAmount: Value(newAmount))
    );

    // 2. Optional: Record as 'Expense' (Money set aside)
    if (createTransaction) {
      final walletId = ref.read(activeWalletIdProvider);
      await db.into(db.transactions).insert(TransactionsCompanion.insert(
        amount: amount,
        txnType: 'CASH_OUT',
        category: const Value('Savings'), // Ensure this matches a valid category or string
        date: DateTime.now(),
        details: Value("Deposit to Goal: $goalName"),
        walletId: Value(walletId),
        partyId: const Value(null),
      ));
    }
  }

  Future<void> deleteGoal(int id) async {
    final db = ref.read(databaseProvider);
    await (db.delete(db.savingGoals)..where((t) => t.id.equals(id))).go();
  }
}

// Provider: List of Goals
final savingGoalsProvider = StreamProvider<List<SavingGoal>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.savingGoals)
    ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
    .watch();
});
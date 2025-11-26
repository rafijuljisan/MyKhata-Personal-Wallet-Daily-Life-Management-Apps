import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:my_khata/src/data/database.dart';
import 'package:my_khata/src/data/tables.dart';
import '../../wallets/data/wallet_provider.dart'; 

part 'transaction_repository.g.dart';

@riverpod
class TransactionRepository extends _$TransactionRepository {
  @override
  void build() {}

  // 1. Add Single Cash Transaction
  Future<void> addCashTransaction({
    required double amount,
    required String type,
    required int? categoryId, 
    required String note,
    required DateTime date,
  }) async {
    final db = ref.read(databaseProvider);
    final walletId = ref.read(activeWalletIdProvider);

    await db.into(db.transactions).insert(TransactionsCompanion.insert(
      amount: amount,
      txnType: type,
      categoryId: Value(categoryId),
      date: date,
      details: Value(note),
      partyId: const Value(null),
      walletId: Value(walletId),
    ));
  }
  
  // 2. Add Split Transaction 
  Future<void> addSplitTransaction({
    required List<Map<String, dynamic>> items, 
    required String type,
    required DateTime date,
    required String mainNote,
  }) async {
    final db = ref.read(databaseProvider);
    final walletId = ref.read(activeWalletIdProvider);

    await db.transaction(() async {
      for (var item in items) {
        await db.into(db.transactions).insert(TransactionsCompanion.insert(
          amount: item['amount'],
          txnType: type,
          categoryId: Value(item['categoryId']),
          date: date,
          details: Value("$mainNote [Split]: ${item['note'] ?? ''}"),
          partyId: const Value(null),
          walletId: Value(walletId),
        ));
      }
    });
  }

  // 3. Add Party Transaction
  Future<void> addPartyTransaction({
    required int partyId,
    required double amount,
    required String type, 
    required String note,
    required DateTime date,
  }) async {
    final db = ref.read(databaseProvider);
    final walletId = ref.read(activeWalletIdProvider); 

    await db.into(db.transactions).insert(TransactionsCompanion.insert(
      amount: amount,
      txnType: type,
      date: date,
      details: Value(note),
      partyId: Value(partyId),
      walletId: Value(walletId), 
    ));
  }

  // 4. Fund Transfer
  Future<void> transferFund({
    required int fromWalletId,
    required int toWalletId,
    required double amount,
    required String note,
    required DateTime date,
  }) async {
    final db = ref.read(databaseProvider);
    await db.transaction(() async {
      await db.into(db.transactions).insert(TransactionsCompanion.insert(
        amount: amount,
        txnType: 'TRANSFER_OUT',
        date: date,
        details: Value("Transfer to Wallet #$toWalletId. $note"),
        walletId: Value(fromWalletId),
      ));

      await db.into(db.transactions).insert(TransactionsCompanion.insert(
        amount: amount,
        txnType: 'TRANSFER_IN',
        date: date,
        details: Value("Received from Wallet #$fromWalletId. $note"),
        walletId: Value(toWalletId),
      ));
    });
  }

  Future<void> deleteTransaction(int id) async {
    final db = ref.read(databaseProvider);
    await (db.delete(db.transactions)..where((t) => t.id.equals(id))).go();
  }

  Future<void> updateTransaction(Transaction txn) async {
    final db = ref.read(databaseProvider);
    await db.update(db.transactions).replace(txn);
  }
}

// --- PROVIDERS ---

// 1. Transaction With Details (Category included)
class TransactionWithDetails {
  final Transaction transaction;
  final Party? party;
  final Category? category;
  TransactionWithDetails(this.transaction, this.party, this.category);
}

final allTransactionsProvider = StreamProvider<List<TransactionWithDetails>>((ref) {
  final db = ref.watch(databaseProvider);
  final walletId = ref.watch(activeWalletIdProvider); 
  
  final query = db.select(db.transactions).join([
    leftOuterJoin(db.parties, db.parties.id.equalsExp(db.transactions.partyId)),
    leftOuterJoin(db.categories, db.categories.id.equalsExp(db.transactions.categoryId)), 
  ]);

  query.where(db.transactions.walletId.equals(walletId)); 
  query.orderBy([OrderingTerm.desc(db.transactions.date)]);

  return query.watch().map((rows) {
    return rows.map((row) {
      return TransactionWithDetails(
        row.readTable(db.transactions),
        row.readTableOrNull(db.parties),
        row.readTableOrNull(db.categories),
      );
    }).toList();
  });
});

// 2. Party Transactions (MISSING IN YOUR CODE, ADDED BACK)
final partyTransactionsProvider = StreamProvider.family<List<Transaction>, int>((ref, partyId) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.transactions)
        ..where((tbl) => tbl.partyId.equals(partyId))
        ..orderBy([(t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc)]))
      .watch();
});

// 3. Category Expenses (MISSING IN YOUR CODE, ADDED BACK)
final categoryExpensesProvider = StreamProvider<Map<String, double>>((ref) {
  final db = ref.watch(databaseProvider);
  final walletId = ref.watch(activeWalletIdProvider); 
  
  // We join with Categories table to get names, or use the 'category' text column as fallback
  final query = db.select(db.transactions).join([
    leftOuterJoin(db.categories, db.categories.id.equalsExp(db.transactions.categoryId))
  ]);
  
  query.where(db.transactions.txnType.equals('CASH_OUT') & db.transactions.walletId.equals(walletId));

  return query.watch().map((rows) {
    final Map<String, double> totals = {};
    for (var row in rows) {
      final t = row.readTable(db.transactions);
      final cat = row.readTableOrNull(db.categories);
      
      // Use Category Name if linked, otherwise fallback to text column, otherwise 'Other'
      final catName = cat?.name ?? t.category ?? "Other";
      totals[catName] = (totals[catName] ?? 0) + t.amount;
    }
    return totals;
  });
});
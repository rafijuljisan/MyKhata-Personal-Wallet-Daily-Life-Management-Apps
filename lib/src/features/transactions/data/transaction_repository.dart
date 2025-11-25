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

  // 1. Add Cash
  Future<void> addCashTransaction({
    required double amount,
    required String type,
    required String category,
    required String note,
    required DateTime date,
  }) async {
    final db = ref.read(databaseProvider);
    final walletId = ref.read(activeWalletIdProvider);

    await db.into(db.transactions).insert(TransactionsCompanion.insert(
      amount: amount,
      txnType: type,
      category: Value(category),
      date: date,
      details: Value(note),
      partyId: const Value(null),
      walletId: Value(walletId),
    ));
  }

  // 2. Add Party Transaction
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
      category: const Value("Party"),
      date: date,
      details: Value(note),
      partyId: Value(partyId),
      walletId: Value(walletId), 
    ));
  }

  // 3. NEW: FUND TRANSFER
  Future<void> transferFund({
    required int fromWalletId,
    required int toWalletId,
    required double amount,
    required String note,
    required DateTime date,
  }) async {
    final db = ref.read(databaseProvider);
    
    // Run as a batch transaction (Atomic)
    await db.transaction(() async {
      // 1. Subtract from Source Wallet
      await db.into(db.transactions).insert(TransactionsCompanion.insert(
        amount: amount,
        txnType: 'TRANSFER_OUT',
        category: const Value('Transfer'),
        date: date,
        details: Value("Transfer to Wallet #$toWalletId. $note"),
        walletId: Value(fromWalletId),
        partyId: const Value(null),
      ));

      // 2. Add to Destination Wallet
      await db.into(db.transactions).insert(TransactionsCompanion.insert(
        amount: amount,
        txnType: 'TRANSFER_IN',
        category: const Value('Transfer'),
        date: date,
        details: Value("Received from Wallet #$fromWalletId. $note"),
        walletId: Value(toWalletId),
        partyId: const Value(null),
      ));
    });
  }

  // 4. Delete
  Future<void> deleteTransaction(int id) async {
    final db = ref.read(databaseProvider);
    await (db.delete(db.transactions)..where((t) => t.id.equals(id))).go();
  }

  // 5. Update
  Future<void> updateTransaction(Transaction txn) async {
    final db = ref.read(databaseProvider);
    await db.update(db.transactions).replace(txn);
  }
}

// --- PROVIDERS ---

final partyTransactionsProvider = StreamProvider.family<List<Transaction>, int>((ref, partyId) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.transactions)
        ..where((tbl) => tbl.partyId.equals(partyId))
        ..orderBy([(t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc)]))
      .watch();
});

class TransactionWithParty {
  final Transaction transaction;
  final Party? party;
  TransactionWithParty(this.transaction, this.party);
}

final allTransactionsProvider = StreamProvider<List<TransactionWithParty>>((ref) {
  final db = ref.watch(databaseProvider);
  final walletId = ref.watch(activeWalletIdProvider); 
  
  final query = db.select(db.transactions).join([
    leftOuterJoin(db.parties, db.parties.id.equalsExp(db.transactions.partyId)),
  ]);

  query.where(db.transactions.walletId.equals(walletId)); 
  query.orderBy([OrderingTerm.desc(db.transactions.date)]);

  return query.watch().map((rows) {
    return rows.map((row) {
      return TransactionWithParty(
        row.readTable(db.transactions),
        row.readTableOrNull(db.parties),
      );
    }).toList();
  });
});

final categoryExpensesProvider = StreamProvider<Map<String, double>>((ref) {
  final db = ref.watch(databaseProvider);
  final walletId = ref.watch(activeWalletIdProvider); 

  return (db.select(db.transactions)
        ..where((t) => t.txnType.equals('CASH_OUT') & t.walletId.equals(walletId)))
      .watch()
      .map((transactions) {
        final Map<String, double> totals = {};
        for (var t in transactions) {
          final cat = t.category ?? "Other";
          totals[cat] = (totals[cat] ?? 0) + t.amount;
        }
        return totals;
      });
});
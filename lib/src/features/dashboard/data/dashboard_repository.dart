import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:rxdart/rxdart.dart';
import '../../../data/database.dart';
import '../../../data/tables.dart';
import '../../wallets/data/wallet_provider.dart';

part 'dashboard_repository.g.dart';

// --- 1. Cash In Hand (Keep Wallet Specific) ---
// This MUST remain wallet specific because "Cash in Hand" is physically inside a specific wallet.
@riverpod
Stream<double> cashInHand(Ref ref) {
  final db = ref.watch(databaseProvider);
  final walletId = ref.watch(activeWalletIdProvider);
  
  final query = db.select(db.transactions).join([
    leftOuterJoin(db.parties, db.parties.id.equalsExp(db.transactions.partyId)),
  ]);
  
  query.where(db.transactions.walletId.equals(walletId));

  return query.watch().map((rows) {
    double total = 0;
    for (var row in rows) {
      final txn = row.readTable(db.transactions);
      
      if (txn.txnType == 'CASH_IN' || txn.txnType == 'TRANSFER_IN') {
        total += txn.amount;
      } 
      else if (txn.txnType == 'CASH_OUT' || txn.txnType == 'TRANSFER_OUT') {
        total -= txn.amount;
      }
      else if (txn.txnType == 'DUE_RECEIVED') {
         total += txn.amount;
      }
      else if (txn.txnType == 'DUE_GIVEN') {
          total -= txn.amount;
      }
    }
    return total;
  });
}

// --- 2. Receivables (Pabo) - GLOBAL (All Wallets) ---
// Updated: Removed walletId filter. Shows total owed to you across all wallets.
@riverpod
Stream<double> totalReceivables(Ref ref) {
  final db = ref.watch(databaseProvider);
  // Removed: final walletId = ref.watch(activeWalletIdProvider);

  final partiesStream = db.select(db.parties).watch();
  
  // Fetch ALL transactions (removed walletId filter)
  final transactionsStream = db.select(db.transactions).watch();

  return Rx.combineLatest2(partiesStream, transactionsStream, 
    (List<Party> parties, List<Transaction> transactions) {
      double totalPabo = 0;
      
      for (var party in parties) {
        double balance = party.initialBalance;
        
        for (var t in transactions) {
          if (t.partyId == party.id) {
            if (t.txnType == 'DUE_GIVEN') balance += t.amount;
            if (t.txnType == 'DUE_RECEIVED') balance -= t.amount;
          }
        }
        
        if (balance > 0) totalPabo += balance;
      }
      return totalPabo;
    }
  );
}

// --- 3. Payables (Dibo) - GLOBAL (All Wallets) ---
// Updated: Removed walletId filter. Shows total you owe across all wallets.
@riverpod
Stream<double> totalPayables(Ref ref) {
  final db = ref.watch(databaseProvider);
  // Removed: final walletId = ref.watch(activeWalletIdProvider);

  final partiesStream = db.select(db.parties).watch();
  
  // Fetch ALL transactions (removed walletId filter)
  final transactionsStream = db.select(db.transactions).watch();

  return Rx.combineLatest2(partiesStream, transactionsStream, 
    (List<Party> parties, List<Transaction> transactions) {
      double totalDibo = 0;
      
      for (var party in parties) {
        double balance = party.initialBalance;
        
        for (var t in transactions) {
          if (t.partyId == party.id) {
            if (t.txnType == 'DUE_GIVEN') balance += t.amount;
            if (t.txnType == 'DUE_RECEIVED') balance -= t.amount;
          }
        }
        
        if (balance < 0) {
          totalDibo += balance.abs();
        }
      }
      return totalDibo;
    }
  );
}
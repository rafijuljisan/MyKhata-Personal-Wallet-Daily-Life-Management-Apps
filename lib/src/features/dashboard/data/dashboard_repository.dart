import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:rxdart/rxdart.dart'; // Required for combineLatest
import '../../../data/database.dart';
import '../../../data/tables.dart';
import '../../wallets/data/wallet_provider.dart';

part 'dashboard_repository.g.dart';

// --- 1. Cash In Hand (Smart Calculation) ---
@riverpod
Stream<double> cashInHand(Ref ref) {
  final db = ref.watch(databaseProvider);
  final walletId = ref.watch(activeWalletIdProvider);
  
  // We need to join Transactions with Parties to know if it was a Supplier or Customer
  final query = db.select(db.transactions).join([
    leftOuterJoin(db.parties, db.parties.id.equalsExp(db.transactions.partyId)),
  ]);
  
  query.where(db.transactions.walletId.equals(walletId));

  return query.watch().map((rows) {
    double total = 0;
    for (var row in rows) {
      final txn = row.readTable(db.transactions);
      final party = row.readTableOrNull(db.parties);
      
      if (txn.txnType == 'CASH_IN' || txn.txnType == 'TRANSFER_IN') {
        total += txn.amount;
      } 
      else if (txn.txnType == 'CASH_OUT' || txn.txnType == 'TRANSFER_OUT') {
        total -= txn.amount;
      }
      // LOGIC:
      // If I got money from Customer (Due Received) -> Cash Increases (+).
      else if (txn.txnType == 'DUE_RECEIVED') {
         total += txn.amount;
      }
      // If I gave money (Payment to Supplier) -> Cash Decreases (-).
      else if (txn.txnType == 'DUE_GIVEN') {
        // Check if the party is a Supplier. If so, it's likely a payment.
        if (party != null && party.type == 'SUPPLIER') {
          total -= txn.amount;
        }
        // Note: 'DUE_GIVEN' to a Customer usually means "Sale on Credit" (goods given, no cash exchanged), 
        // so we DO NOT subtract cash in that case.
      }
    }
    return total;
  });
}

// --- 2. Receivables (Pabo - Customers Only) ---
@riverpod
Stream<double> totalReceivables(Ref ref) {
  final db = ref.watch(databaseProvider);
  final walletId = ref.watch(activeWalletIdProvider);

  // 1. Get All Customers
  final partiesStream = (db.select(db.parties)..where((p) => p.type.equals('CUSTOMER'))).watch();
  
  // 2. Get All Transactions for this Wallet
  final transactionsStream = (db.select(db.transactions)..where((t) => t.walletId.equals(walletId))).watch();

  return Rx.combineLatest2(partiesStream, transactionsStream, 
    (List<Party> parties, List<Transaction> transactions) {
      double totalPabo = 0;
      
      for (var customer in parties) {
        // Start with Initial Balance
        double balance = customer.initialBalance; 
        
        // Add/Sub transactions specific to this customer
        for (var t in transactions) {
          if (t.partyId == customer.id) {
            if (t.txnType == 'DUE_GIVEN') balance += t.amount;    // Sold on Credit -> They owe me more
            if (t.txnType == 'DUE_RECEIVED') balance -= t.amount; // They paid -> They owe me less
          }
        }
        
        // If balance is positive, they owe me (Pabo)
        if (balance > 0) totalPabo += balance;
      }
      return totalPabo;
    }
  );
}

// --- 3. Payables (Dibo - Suppliers Only) ---
@riverpod
Stream<double> totalPayables(Ref ref) {
  final db = ref.watch(databaseProvider);
  final walletId = ref.watch(activeWalletIdProvider);

  // 1. Get All Suppliers
  final partiesStream = (db.select(db.parties)..where((p) => p.type.equals('SUPPLIER'))).watch();
  
  // 2. Get Transactions for this Wallet
  final transactionsStream = (db.select(db.transactions)..where((t) => t.walletId.equals(walletId))).watch();

  return Rx.combineLatest2(partiesStream, transactionsStream, 
    (List<Party> suppliers, List<Transaction> transactions) {
      double totalDibo = 0;
      
      for (var supplier in suppliers) {
        double balance = supplier.initialBalance;
        
        for (var t in transactions) {
          if (t.partyId == supplier.id) {
             // LOGIC REVERSED FOR SUPPLIERS
             // Got Money/Goods -> Liability Increases
             if (t.txnType == 'DUE_RECEIVED') balance += t.amount; 
             // Gave Money (Payment) -> Liability Decreases
             if (t.txnType == 'DUE_GIVEN') balance -= t.amount;   
          }
        }
        
        // If balance is positive, I owe them (Dibo)
        // (Assuming initialBalance was entered as positive debt)
        if (balance > 0) totalDibo += balance;
      }
      return totalDibo;
    }
  );
}
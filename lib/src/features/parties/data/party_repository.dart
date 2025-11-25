import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:rxdart/rxdart.dart'; 
import 'package:my_khata/src/data/database.dart';
import 'package:my_khata/src/data/tables.dart';
import '../../wallets/data/wallet_provider.dart'; // Import Wallet Provider

part 'party_repository.g.dart';

// 1. Logic to Add/Update/Delete
@riverpod
class PartyRepository extends _$PartyRepository {
  @override
  void build() {}

  Future<void> addParty({required String name, required String mobile, required String type}) async {
    final db = ref.read(databaseProvider);
    await db.into(db.parties).insert(PartiesCompanion.insert(
      name: name, mobile: mobile, type: type, initialBalance: const Value(0.0)
    ));
  }

  Future<void> updateParty(Party party) async {
    final db = ref.read(databaseProvider);
    await db.update(db.parties).replace(party);
  }

  Future<void> deleteParty(int id) async {
    final db = ref.read(databaseProvider);
    await (db.delete(db.parties)..where((t) => t.id.equals(id))).go();
    await (db.delete(db.transactions)..where((t) => t.partyId.equals(id))).go();
  }
}

// Helper Class
class PartyWithBalance {
  final Party party;
  final double balance;
  PartyWithBalance(this.party, this.balance);
}

// 2. Logic to Get List (Updated for Multi-Wallet Balance)
final partyListProvider = StreamProvider<List<PartyWithBalance>>((ref) {
  final db = ref.watch(databaseProvider);
  final walletId = ref.watch(activeWalletIdProvider); // Watch Wallet
  
  final partiesStream = db.select(db.parties).watch();
  
  // Only fetch transactions for THIS wallet to calculate balance
  final transactionsStream = (db.select(db.transactions)
        ..where((t) => t.walletId.equals(walletId)))
        .watch();

  return Rx.combineLatest2(partiesStream, transactionsStream, 
    (List<Party> parties, List<Transaction> transactions) {
      return parties.map((party) {
        double bal = party.initialBalance; 
        for (var t in transactions) {
          if (t.partyId == party.id) {
            if (t.txnType == 'DUE_GIVEN') bal += t.amount;
            if (t.txnType == 'DUE_RECEIVED') bal -= t.amount;
          }
        }
        return PartyWithBalance(party, bal);
      }).toList();
    }
  );
});
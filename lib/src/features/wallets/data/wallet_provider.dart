import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/database.dart';
import '../../../data/tables.dart';

// 1. State for Active Wallet ID
class ActiveWalletNotifier extends Notifier<int> {
  @override
  int build() {
    _loadSavedWallet();
    return 1; // Default ID 1
  }

  Future<void> _loadSavedWallet() async {
    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getInt('active_wallet_id');
    if (savedId != null) {
      state = savedId;
    } else {
      // If no saved wallet, find the default one from DB
      final db = ref.read(databaseProvider);
      final defaultWallet = await (db.select(db.wallets)..where((w) => w.isDefault.equals(true))).getSingleOrNull();
      if (defaultWallet != null) {
        state = defaultWallet.id;
        prefs.setInt('active_wallet_id', defaultWallet.id);
      }
    }
  }

  Future<void> setWallet(int id) async {
    state = id;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('active_wallet_id', id);
  }
}

final activeWalletIdProvider = NotifierProvider<ActiveWalletNotifier, int>(() {
  return ActiveWalletNotifier();
});

// 2. Provider to get ALL Wallets (For the switcher list)
final walletListProvider = StreamProvider<List<Wallet>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.select(db.wallets).watch();
});

// 3. Helper to create a new wallet
final walletRepositoryProvider = Provider((ref) => WalletRepository(ref.watch(databaseProvider)));

class WalletRepository {
  final AppDatabase db;
  WalletRepository(this.db);

  Future<void> addWallet(String name) async {
    await db.into(db.wallets).insert(WalletsCompanion.insert(
      name: name,
      // FIXED: Wrapped in Value()
      type: const Value('Business'),
    ));
  }
}

// 4. Provider to get Cash In Hand for all Wallets (New)
final allWalletBalancesProvider = StreamProvider<Map<int, double>>((ref) {
  final db = ref.watch(databaseProvider);

  // 1. Get All Transactions with Party Info
  final query = db.select(db.transactions).join([
    leftOuterJoin(db.parties, db.parties.id.equalsExp(db.transactions.partyId)),
  ]);
  
  // 2. Watch for changes
  return query.watch().map((rows) {
    // Map to hold {walletId: balance}
    final Map<int, double> balances = {};
    
    for (var row in rows) {
      final txn = row.readTable(db.transactions);
      final party = row.readTableOrNull(db.parties);
      
      // FIX: Ensure walletId is non-null before using it as a map key.
      if (txn.walletId == null) continue;
      final int wId = txn.walletId!; 
      
      // Initialize balance for the wallet if it doesn't exist
      balances.putIfAbsent(wId, () => 0.0);
      
      double change = 0;

      if (txn.txnType == 'CASH_IN' || txn.txnType == 'TRANSFER_IN' || txn.txnType == 'DUE_RECEIVED') {
        // Cash increases for these types
        change = txn.amount;
      } 
      else if (txn.txnType == 'CASH_OUT' || txn.txnType == 'TRANSFER_OUT') {
        // Cash decreases for these types
        change = -txn.amount;
      }
      else if (txn.txnType == 'DUE_GIVEN') {
        // Due Given is:
        // - Goods given on credit (Customer) -> NO CASH CHANGE (change = 0)
        // - Payment to Supplier (Supplier) -> CASH DECREASES (change = -amount)
        if (party != null && party.type == 'SUPPLIER') {
          change = -txn.amount;
        }
      }
      
      balances[wId] = balances[wId]! + change;
    }
    return balances;
  });
});
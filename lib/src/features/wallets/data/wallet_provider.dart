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
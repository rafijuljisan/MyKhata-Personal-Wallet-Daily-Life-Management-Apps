import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../data/database.dart';
import '../../../data/tables.dart';
import '../../wallets/data/wallet_provider.dart';

part 'shopping_repository.g.dart';

@riverpod
class ShoppingRepository extends _$ShoppingRepository {
  @override
  void build() {}

  // 1. Add Item
  Future<void> addItem(String name) async {
    final db = ref.read(databaseProvider);
    await db.into(db.shoppingItems).insert(ShoppingItemsCompanion.insert(
      itemName: name,
      estimatedCost: const Value(0), // Default cost
      isChecked: const Value(false), // Default unchecked
    ));
  }

  // 2. Update Cost (e.g. when buying)
  Future<void> updateCost(int id, double cost) async {
    final db = ref.read(databaseProvider);
    await (db.update(db.shoppingItems)..where((t) => t.id.equals(id))).write(
      ShoppingItemsCompanion(estimatedCost: Value(cost)),
    );
  }

  // 3. Toggle Checkbox
  Future<void> toggleCheck(int id, bool isChecked) async {
    final db = ref.read(databaseProvider);
    await (db.update(db.shoppingItems)..where((t) => t.id.equals(id))).write(
      ShoppingItemsCompanion(isChecked: Value(isChecked)),
    );
  }

  // 4. Delete Item
  Future<void> deleteItem(int id) async {
    final db = ref.read(databaseProvider);
    await (db.delete(db.shoppingItems)..where((t) => t.id.equals(id))).go();
  }

  // 5. CHECKOUT (Convert to Expense) - FIXED
  Future<void> checkoutBoughtItems() async {
    final db = ref.read(databaseProvider);
    final walletId = ref.read(activeWalletIdProvider);
    
    // Get all checked items
    final boughtItems = await (db.select(db.shoppingItems)
      ..where((t) => t.isChecked.equals(true)))
      .get();
    
    if (boughtItems.isEmpty) return;

    double totalCost = 0;
    List<String> itemNames = [];

    for (var item in boughtItems) {
      totalCost += item.estimatedCost;
      itemNames.add("${item.itemName} ৳${item.estimatedCost.toStringAsFixed(0)}");
    }

    // Only create transaction if total > 0
    if (totalCost > 0) {
      // Create ONE transaction for the whole shopping trip
      await db.into(db.transactions).insert(TransactionsCompanion.insert(
        amount: totalCost,
        txnType: 'CASH_OUT',
        category: const Value('Shopping'),
        date: DateTime.now(),
        details: Value("Bazar: ${itemNames.join(', ')}"),
        walletId: Value(walletId),
        partyId: const Value(null),
      ));

      // Delete the bought items from the list
      await (db.delete(db.shoppingItems)
        ..where((t) => t.isChecked.equals(true)))
        .go();
    }
  }
}

// Provider to get the list
final shoppingListProvider = StreamProvider<List<ShoppingItem>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.select(db.shoppingItems).watch();
});
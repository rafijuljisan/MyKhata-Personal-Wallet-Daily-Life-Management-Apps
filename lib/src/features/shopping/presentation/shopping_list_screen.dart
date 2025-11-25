import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/shopping_repository.dart';
// Make sure to import your database class if ShoppingItem type is needed explicitly, 
// otherwise 'var' works fine in loops.

class ShoppingListScreen extends ConsumerStatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  ConsumerState<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends ConsumerState<ShoppingListScreen> {
  final _addItemController = TextEditingController();

  @override
  void dispose() {
    _addItemController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final listAsync = ref.watch(shoppingListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Bazar List (Shopping)"),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // --- 1. ADD ITEM INPUT ---
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.deepOrange.shade50,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _addItemController,
                    decoration: InputDecoration(
                      hintText: "Add item (e.g. Rice, Fish)",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onSubmitted: (_) => _addItem(),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _addItem,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  ),
                  child: const Text("ADD", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),

          // --- 2. SHOPPING LIST ---
          Expanded(
            child: listAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          "List is empty. Add items!",
                          style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  );
                }

                // Calculate Total of CHECKED items
                double currentTotal = 0;
                int checkedCount = 0;
                for (var i in items) {
                  if (i.isChecked) {
                    currentTotal += i.estimatedCost;
                    checkedCount++;
                  }
                }

                return Column(
                  children: [
                    Expanded(
                      child: ListView.separated(
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          // HERE IS THE FIX: Using a custom widget for the tile
                          return ShoppingItemTile(
                            key: ValueKey(item.id), // Important for performance
                            item: item,
                          );
                        },
                      ),
                    ),

                    // --- 3. BOTTOM CHECKOUT BAR ---
                    if (checkedCount > 0)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: currentTotal > 0 ? Colors.green.shade50 : Colors.orange.shade50,
                          border: Border(
                            top: BorderSide(
                              color: currentTotal > 0 ? Colors.green.shade200 : Colors.orange.shade200,
                              width: 2,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "$checkedCount item${checkedCount > 1 ? 's' : ''} selected",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "৳ ${currentTotal.toStringAsFixed(0)}",
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: currentTotal > 0 ? Colors.green : Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                            ElevatedButton.icon(
                              onPressed: currentTotal > 0
                                  ? () => _confirmCheckout(context, currentTotal)
                                  : null,
                              icon: const Icon(Icons.check_circle, size: 20),
                              label: const Text(
                                "CHECKOUT",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: currentTotal > 0 ? Colors.green : Colors.grey,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text("Error: $e")),
            ),
          ),
        ],
      ),
    );
  }

  void _addItem() {
    if (_addItemController.text.trim().isNotEmpty) {
      ref.read(shoppingRepositoryProvider.notifier)
          .addItem(_addItemController.text.trim());
      _addItemController.clear();
    }
  }

  void _confirmCheckout(BuildContext context, double total) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.shopping_bag, color: Colors.green.shade700),
            const SizedBox(width: 10),
            const Text("Finish Shopping?"),
          ],
        ),
        content: Text(
          "This will add an Expense of ৳ ${total.toStringAsFixed(0)} to your ledger and remove the bought items.",
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              ref.read(shoppingRepositoryProvider.notifier).checkoutBoughtItems();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Expense Added: ৳ ${total.toStringAsFixed(0)}"),
                  backgroundColor: Colors.green,
                ),
              );
            },
            icon: const Icon(Icons.check_circle),
            label: const Text("Confirm"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ==============================================================================
// SEPARATE WIDGET FOR THE LIST ITEM (Fixes the input/checkbox issue)
// ==============================================================================

class ShoppingItemTile extends ConsumerStatefulWidget {
  final dynamic item; // Replace 'dynamic' with your actual 'ShoppingItem' class if available

  const ShoppingItemTile({
    super.key,
    required this.item,
  });

  @override
  ConsumerState<ShoppingItemTile> createState() => _ShoppingItemTileState();
}

class _ShoppingItemTileState extends ConsumerState<ShoppingItemTile> {
  late TextEditingController _costController;

  @override
  void initState() {
    super.initState();
    // Initialize controller with current DB value
    _costController = TextEditingController(
      text: widget.item.estimatedCost > 0
          ? widget.item.estimatedCost.toStringAsFixed(0)
          : "",
    );
  }

  @override
  void didUpdateWidget(covariant ShoppingItemTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the item cost changed in the DB (externally) and doesn't match our controller, update it.
    // We check carefully to avoid overwriting what the user is currently typing.
    if (widget.item.estimatedCost != oldWidget.item.estimatedCost) {
      double currentInput = double.tryParse(_costController.text) ?? 0;
      if (currentInput != widget.item.estimatedCost) {
        _costController.text = widget.item.estimatedCost > 0
            ? widget.item.estimatedCost.toStringAsFixed(0)
            : "";
      }
    }
  }

  @override
  void dispose() {
    _costController.dispose();
    super.dispose();
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Item?"),
        content: Text("Remove '${widget.item.itemName}' from the list?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(shoppingRepositoryProvider.notifier).deleteItem(widget.item.id);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      
      // --- CHECKBOX LOGIC ---
      leading: Checkbox(
        value: widget.item.isChecked,
        activeColor: Colors.green,
        onChanged: (val) {
          final isChecking = val ?? false;
          
          // CRITICAL FIX: Check the DB value. 
          // Note: Since we are using onChanged on the TextField, the DB value 
          // should be up to date. But if it's 0, we block the check.
          if (isChecking && widget.item.estimatedCost <= 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("⚠️ Please add a price first"),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 1),
              ),
            );
            return;
          }

          ref.read(shoppingRepositoryProvider.notifier)
             .toggleCheck(widget.item.id, isChecking);
        },
      ),

      // --- ITEM NAME ---
      title: Text(
        widget.item.itemName,
        style: TextStyle(
          decoration: widget.item.isChecked
              ? TextDecoration.lineThrough
              : null,
          color: widget.item.isChecked ? Colors.grey : Colors.black,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),

      // --- PRICE INPUT ---
      trailing: Container(
        width: 110,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: widget.item.isChecked ? Colors.green.shade50 : Colors.grey.shade100,
          border: Border.all(
            color: widget.item.isChecked ? Colors.green.shade300 : Colors.grey.shade400,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: TextField(
          controller: _costController,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.right,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: widget.item.isChecked ? Colors.green.shade800 : Colors.black87,
          ),
          decoration: const InputDecoration(
            hintText: "0",
            prefixText: "৳ ",
            prefixStyle: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.symmetric(vertical: 8),
          ),
          // CRITICAL FIX: Use onChanged to save immediately
          onChanged: (val) {
            final cost = double.tryParse(val) ?? 0;
            ref.read(shoppingRepositoryProvider.notifier)
               .updateCost(widget.item.id, cost);
          },
        ),
      ),
      onLongPress: () => _confirmDelete(context),
    );
  }
}
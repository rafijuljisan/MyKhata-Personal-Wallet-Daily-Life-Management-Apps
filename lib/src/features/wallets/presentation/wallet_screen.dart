import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/wallet_provider.dart';

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletsAsync = ref.watch(walletListProvider);
    final activeWalletId = ref.watch(activeWalletIdProvider);
    final allBalancesAsync = ref.watch(allWalletBalancesProvider); 

    return Scaffold(
      appBar: AppBar(title: const Text("Manage Wallets")),
      body: walletsAsync.when(
        data: (wallets) {
          return ListView.builder(
            itemCount: wallets.length,
            // FIX 1: Add bottom padding to prevent overflow due to FloatingActionButton
            padding: const EdgeInsets.only(bottom: 90), 
            itemBuilder: (context, index) {
              final wallet = wallets[index];
              final isActive = wallet.id == activeWalletId;
              
              final balance = allBalancesAsync.when(
                data: (balances) => balances[wallet.id] ?? 0.0,
                loading: () => 0.0, 
                error: (_, __) => 0.0,
              );

              return Card(
                color: isActive ? Colors.blue.shade50 : Colors.white,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: Icon(
                    isActive ? Icons.check_circle : Icons.account_balance_wallet,
                    color: isActive ? Colors.blue : Colors.grey,
                  ),
                  title: Text(
                    wallet.name,
                    style: TextStyle(
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                      color: isActive ? Colors.blue.shade900 : Colors.black87,
                    ),
                  ),
                  subtitle: Text(wallet.type), // Personal / Business
                  // MODIFIED: Show balance and active chip
                  trailing: Column(
                    // FIX 2: Ensure content is vertically centered in the ListTile
                    mainAxisAlignment: MainAxisAlignment.center, 
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                       Text(
                         "৳ ${balance.toStringAsFixed(0)}",
                         style: TextStyle(
                           fontWeight: FontWeight.bold,
                           fontSize: 16,
                           color: balance >= 0 ? Colors.green.shade700 : Colors.red.shade700,
                         ),
                       ),
                       if(isActive)
                        const Padding(
                          padding: EdgeInsets.only(top: 4.0),
                          // FIX 3: Removed "Active" chip to fix potential misalignment and simplify.
                          // The blue checkmark and card color already indicate active status.
                          // Using a smaller, more compact indicator if needed.
                          // Using the word "Active" to avoid the overflow risk with the large font.
                          child: Text("Active", style: TextStyle(fontSize: 12, color: Colors.blue)), 
                        ),
                    ],
                  ),
                  onTap: () {
                    // Switch Wallet Logic
                    ref.read(activeWalletIdProvider.notifier).setWallet(wallet.id);
                    Navigator.pop(context); // Close screen after switching
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Switched to ${wallet.name}")),
                    );
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text("Error: $e")),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddWalletDialog(context, ref),
        label: const Text("New Wallet"),
        icon: const Icon(Icons.add),
      ),
    );
  }

  void _showAddWalletDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Create New Wallet"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: "Wallet Name (e.g. Shop Cash)",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                ref.read(walletRepositoryProvider).addWallet(controller.text);
                Navigator.pop(ctx);
              }
            },
            child: const Text("Create"),
          ),
        ],
      ),
    );
  }
}
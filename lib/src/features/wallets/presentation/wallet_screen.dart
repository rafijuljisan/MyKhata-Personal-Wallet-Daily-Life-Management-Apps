import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/wallet_provider.dart';

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletsAsync = ref.watch(walletListProvider);
    final activeWalletId = ref.watch(activeWalletIdProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Manage Wallets")),
      body: walletsAsync.when(
        data: (wallets) {
          return ListView.builder(
            itemCount: wallets.length,
            itemBuilder: (context, index) {
              final wallet = wallets[index];
              final isActive = wallet.id == activeWalletId;

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
                  trailing: isActive
                      ? const Chip(label: Text("Active", style: TextStyle(fontSize: 10, color: Colors.white)), backgroundColor: Colors.blue)
                      : null,
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
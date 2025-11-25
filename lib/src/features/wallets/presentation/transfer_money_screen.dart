import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../data/database.dart';
import '../data/wallet_provider.dart';
import '../../transactions/data/transaction_repository.dart';
import '../../settings/data/language_provider.dart';

class TransferMoneyScreen extends ConsumerStatefulWidget {
  const TransferMoneyScreen({super.key});

  @override
  ConsumerState<TransferMoneyScreen> createState() => _TransferMoneyScreenState();
}

class _TransferMoneyScreenState extends ConsumerState<TransferMoneyScreen> {
  int? _fromWalletId;
  int? _toWalletId;
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Auto-select current wallet as "From"
    final currentId = ref.read(activeWalletIdProvider);
    _fromWalletId = currentId;
  }

  @override
  Widget build(BuildContext context) {
    final walletsAsync = ref.watch(walletListProvider);
    final lang = ref.watch(languageProvider);

    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.get('transfer_fund', lang))),
      body: walletsAsync.when(
        data: (wallets) {
          if (wallets.length < 2) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text("You need at least 2 wallets to transfer money. Please create another wallet in Settings.", textAlign: TextAlign.center),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // 1. From Wallet
                DropdownButtonFormField<int>(
                  value: _fromWalletId,
                  decoration: InputDecoration(
                    labelText: AppStrings.get('from_wallet', lang),
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.account_balance_wallet, color: Colors.red),
                  ),
                  items: wallets.map((w) => DropdownMenuItem(value: w.id, child: Text(w.name))).toList(),
                  onChanged: (val) => setState(() => _fromWalletId = val),
                ),
                const SizedBox(height: 20),

                // Icon Arrow
                const Icon(Icons.arrow_downward, size: 30, color: Colors.grey),
                const SizedBox(height: 20),

                // 2. To Wallet
                DropdownButtonFormField<int>(
                  value: _toWalletId,
                  decoration: InputDecoration(
                    labelText: AppStrings.get('to_wallet', lang),
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.account_balance_wallet, color: Colors.green),
                  ),
                  items: wallets.map((w) => DropdownMenuItem(value: w.id, child: Text(w.name))).toList(),
                  onChanged: (val) => setState(() => _toWalletId = val),
                ),
                const SizedBox(height: 20),

                // 3. Amount
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: AppStrings.get('amount', lang),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),

                // 4. Note
                TextField(
                  controller: _noteController,
                  decoration: InputDecoration(
                    labelText: AppStrings.get('note', lang),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),

                // 5. Date
                ListTile(
                  title: Text("${AppStrings.get('date', lang)}: ${DateFormat('dd MMM yyyy').format(_selectedDate)}"),
                  trailing: const Icon(Icons.calendar_today),
                  shape: RoundedRectangleBorder(side: BorderSide(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (date != null) setState(() => _selectedDate = date);
                  },
                ),

                const SizedBox(height: 40),

                // 6. Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _submitTransfer,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                    child: Text(AppStrings.get('transfer', lang).toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text("Error: $e")),
      ),
    );
  }

  void _submitTransfer() {
    if (_fromWalletId == null || _toWalletId == null || _amountController.text.isEmpty) {
      return;
    }
    if (_fromWalletId == _toWalletId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Source and Destination cannot be the same.")),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) return;

    ref.read(transactionRepositoryProvider.notifier).transferFund(
      fromWalletId: _fromWalletId!,
      toWalletId: _toWalletId!,
      amount: amount,
      note: _noteController.text,
      date: _selectedDate,
    );

    Navigator.pop(context);
  }
}
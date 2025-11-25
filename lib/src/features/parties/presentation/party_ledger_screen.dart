import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart'; 
import '../../../data/database.dart';
import '../../transactions/data/transaction_repository.dart';
import '../data/party_repository.dart'; 
import 'add_party_screen.dart'; 

class PartyLedgerScreen extends ConsumerWidget {
  final Party party;

  const PartyLedgerScreen({super.key, required this.party});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionList = ref.watch(partyTransactionsProvider(party.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(party.name),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => AddPartyScreen(partyToEdit: party)));
              } else if (value == 'delete') {
                _confirmDeleteParty(context, ref);
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit Contact')),
              const PopupMenuItem(value: 'delete', child: Text('Delete Contact', style: TextStyle(color: Colors.red))),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // --- 1. Party Info & Communication Card ---
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: Column(
              children: [
                Text(party.mobile, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                
                // COMMUNICATION BUTTONS
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Spaced out nicely
                  children: [
                    // Call
                    _actionButton(
                      icon: Icons.call,
                      label: "Call",
                      color: Colors.green,
                      onTap: () => _launchCall(party.mobile),
                    ),
                    // SMS
                    _actionButton(
                      icon: Icons.message,
                      label: "SMS",
                      color: Colors.red.shade700,
                      onTap: () => _launchSms(party.mobile),
                    ),
                    // WhatsApp (NEW)
                    _actionButton(
                      icon: Icons.chat_bubble, 
                      label: "WhatsApp",
                      color: Colors.green.shade700,
                      onTap: () => _launchWhatsApp(context, party.mobile),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // --- 2. Transaction History List ---
          Expanded(
            child: transactionList.when(
              data: (transactions) => transactions.isEmpty
                  ? const Center(child: Text("No transactions yet."))
                  : ListView.builder(
                      itemCount: transactions.length,
                      itemBuilder: (context, index) {
                        final txn = transactions[index];
                        final isGiven = txn.txnType == 'DUE_GIVEN';
                        return ListTile(
                          leading: Icon(
                            isGiven ? Icons.arrow_upward : Icons.arrow_downward,
                            color: isGiven ? Colors.red : Colors.green,
                          ),
                          title: Text(isGiven ? "You Gave (Baki Dilam)" : "You Got (Pela)"),
                          subtitle: Text(DateFormat('dd MMM yyyy').format(txn.date)),
                          trailing: Text(
                            "৳ ${txn.amount.toStringAsFixed(0)}",
                            style: TextStyle(
                              color: isGiven ? Colors.red : Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          onLongPress: () {
                             ref.read(transactionRepositoryProvider.notifier).deleteTransaction(txn.id);
                          },
                        );
                      },
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text("Error: $e")),
            ),
          ),
        ],
      ),
      
      // --- 3. Action Buttons ---
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15)),
                onPressed: () => _showAddDialog(context, ref, 'DUE_GIVEN'),
                child: const Text("GAVE MONEY\n(DILAM)", textAlign: TextAlign.center),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15)),
                onPressed: () => _showAddDialog(context, ref, 'DUE_RECEIVED'),
                child: const Text("GOT MONEY\n(PELAM)", textAlign: TextAlign.center),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper for small round buttons
  Widget _actionButton({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: color.withOpacity(0.1),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // --- LAUNCHER LOGIC ---
  Future<void> _launchCall(String number) async {
    final Uri launchUri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  Future<void> _launchSms(String number) async {
    final Uri launchUri = Uri(
      scheme: 'sms',
      path: number,
      queryParameters: <String, String>{
        'body': 'Dear Customer, please pay your due balance.', 
      },
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  // --- WHATSAPP LOGIC (Fixed for "No Account" error) ---
  Future<void> _launchWhatsApp(BuildContext context, String number) async {
    // 1. Clean the number (remove spaces, dashes)
    var cleanNumber = number.replaceAll(RegExp(r'[^\d+]'), '');

    // 2. Fix Country Code for Bangladesh
    // If it starts with '01...', replace '0' with '880'
    if (cleanNumber.startsWith('01')) {
      cleanNumber = '880${cleanNumber.substring(1)}';
    }
    // If it doesn't start with '880' and no '+', assume it needs it (optional safety)
    else if (!cleanNumber.startsWith('880') && !cleanNumber.startsWith('+')) {
       cleanNumber = '880$cleanNumber'; 
    }
    
    // Remove '+' if present for the URL
    if (cleanNumber.startsWith('+')) {
      cleanNumber = cleanNumber.substring(1);
    }

    // 3. Launch URL
    final url = Uri.parse("https://wa.me/$cleanNumber?text=Dear Customer, please pay your due balance.");
    
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not open WhatsApp")),
        );
      }
    }
  }

  void _confirmDeleteParty(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Contact?"),
        content: const Text("This will delete the contact AND ALL their transaction history. This cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              ref.read(partyRepositoryProvider.notifier).deleteParty(party.id);
              Navigator.pop(ctx); 
              Navigator.pop(context); 
            },
            child: Text("DELETE ALL", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref, String type) {
    final amountController = TextEditingController();
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(type == 'DUE_GIVEN' ? "Add Due (Baki)" : "Receive Cash (Joma)"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: amountController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Amount")),
            TextField(controller: noteController, decoration: const InputDecoration(labelText: "Note")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              if (amountController.text.isEmpty) return;
              ref.read(transactionRepositoryProvider.notifier).addPartyTransaction(
                partyId: party.id,
                amount: double.parse(amountController.text),
                type: type,
                note: noteController.text,
                date: DateTime.now(),
              );
              Navigator.pop(ctx);
            },
            child: const Text("SAVE"),
          )
        ],
      ),
    );
  }
}
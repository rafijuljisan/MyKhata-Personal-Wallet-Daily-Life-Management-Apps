import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/party_repository.dart'; 
import 'add_party_screen.dart';
import 'party_ledger_screen.dart';

class PartyListScreen extends ConsumerStatefulWidget {
  const PartyListScreen({super.key});

  @override
  ConsumerState<PartyListScreen> createState() => _PartyListScreenState();
}

class _PartyListScreenState extends ConsumerState<PartyListScreen> {
  bool _isSearching = false;
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    // This provider now returns List<PartyWithBalance>
    final partyList = ref.watch(partyListProvider);

    return Scaffold(
      appBar: AppBar(
        title: !_isSearching
            ? const Text("Customers & Suppliers")
            : TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                cursorColor: Colors.white,
                decoration: const InputDecoration(
                  hintText: "Search name or mobile...",
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
              ),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchController.clear();
                  _searchQuery = "";
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
        ],
      ),
      body: partyList.when(
        data: (partiesWithBalance) {
          // Filter Logic (Using PartyWithBalance)
          final filteredItems = partiesWithBalance.where((item) {
            final name = item.party.name.toLowerCase();
            final mobile = item.party.mobile.toLowerCase();
            return name.contains(_searchQuery) || mobile.contains(_searchQuery);
          }).toList();

          if (filteredItems.isEmpty) {
            return const Center(child: Text("No contacts found."));
          }

          return ListView.builder(
            itemCount: filteredItems.length,
            itemBuilder: (context, index) {
              final item = filteredItems[index];
              final party = item.party;
              final balance = item.balance;

              // Color Logic: Green if they owe you (>0), Red if you owe them (<0)
              final isPositive = balance >= 0;
              final displayBalance = balance.abs(); 

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: party.type == 'CUSTOMER' ? Colors.green[100] : Colors.orange[100],
                  child: Text(party.name[0].toUpperCase(),
                      style: TextStyle(color: party.type == 'CUSTOMER' ? Colors.green : Colors.orange)),
                ),
                title: Text(party.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(party.mobile),
                
                // --- Balance Display ---
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "৳ ${displayBalance.toStringAsFixed(0)}",
                          style: TextStyle(
                            color: isPositive ? Colors.green : Colors.red[900],
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          isPositive ? "Pabo (Due)" : "Dibo (Pay)",
                          style: TextStyle(
                            fontSize: 10, 
                            color: isPositive ? Colors.green : Colors.red[900]
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 10),
                    const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                  ],
                ),
                
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PartyLedgerScreen(party: party),
                    ),
                  );
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text("Error: $err")),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AddPartyScreen()));
        },
        child: const Icon(Icons.person_add),
      ),
    );
  }
}
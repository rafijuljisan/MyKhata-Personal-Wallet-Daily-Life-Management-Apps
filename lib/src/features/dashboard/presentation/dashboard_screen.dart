import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/dashboard_repository.dart';
import '../../transactions/presentation/add_transaction_screen.dart';
import '../../parties/presentation/party_list_screen.dart';
import '../../parties/presentation/party_ledger_screen.dart'; 
import '../../parties/data/party_repository.dart'; 
import '../../transactions/presentation/transaction_history_screen.dart';
import '../../reports/presentation/report_screen.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../settings/data/language_provider.dart';
import '../../settings/data/backup_service.dart';
import '../../wallets/presentation/wallet_screen.dart';
import '../../wallets/data/wallet_provider.dart';
import '../../wallets/presentation/transfer_money_screen.dart'; // NEW Import
import '../../analytics/presentation/analytics_screen.dart';
import '../../bike/presentation/bike_screen.dart';
import '../../shopping/presentation/shopping_list_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runAutoBackup();
    });
  }

  Future<void> _runAutoBackup() async {
    final prefs = await SharedPreferences.getInstance();
    final isEnabled = prefs.getBool('auto_backup_enabled') ?? true;
    if (isEnabled) {
      final days = prefs.getInt('backup_retention_days') ?? 30;
      ref.read(backupServiceProvider).autoBackupToPhone(retentionDays: days);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalDue = ref.watch(totalReceivablesProvider);
    final totalPayable = ref.watch(totalPayablesProvider);
    final lang = ref.watch(languageProvider);
    final walletList = ref.watch(walletListProvider);
    final activeWalletId = ref.watch(activeWalletIdProvider);
    final partyListAsync = ref.watch(partyListProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.blue.shade50, 
        foregroundColor: Colors.black,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: const CircleAvatar(
            backgroundColor: Colors.blue, 
            child: Icon(Icons.person, color: Colors.white),
          ),
        ),
        title: InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen())),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                walletList.when(
                  data: (wallets) {
                    if (wallets.isEmpty) return "MyKhata";
                    final active = wallets.firstWhere(
                      (w) => w.id == activeWalletId, 
                      orElse: () => wallets.first
                    );
                    return active.name;
                  },
                  loading: () => "Loading...",
                  error: (e, s) => "MyKhata",
                ),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const Icon(Icons.arrow_drop_down),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.blue), 
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Notifications coming soon!")));
            }
          ),
        ],
      ),

      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              children: [
                // --- GRID MENU ---
                Container(
                  color: Colors.blue.shade50,
                  padding: const EdgeInsets.only(bottom: 20),
                  child: GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 5, // Changed from 4 to 5
                    mainAxisSpacing: 12, // Reduced spacing
                    crossAxisSpacing: 8, // Reduced spacing
                    childAspectRatio: 0.85, // Adjusted ratio for better fit
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), // Reduced horizontal padding
                    children: [
                      // 1. Contacts
                      _MenuIcon(Icons.people, AppStrings.get('contacts', lang), Colors.indigo, 
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PartyListScreen()))),
                      
                      // 2. History
                      _MenuIcon(Icons.history_edu, AppStrings.get('history', lang), Colors.blue, 
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TransactionHistoryScreen()))),
                      
                      // 3. Analytics
                      _MenuIcon(Icons.pie_chart, AppStrings.get('analytics', lang), Colors.purple, 
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AnalyticsScreen()))),
                      
                      // 4. Reports
                      _MenuIcon(Icons.picture_as_pdf, AppStrings.get('reports', lang), Colors.orange.shade800, 
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportScreen()))),
                      
                      // 5. Wallets
                      _MenuIcon(Icons.account_balance_wallet, "Wallets", Colors.teal, 
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen()))),
                      
                      // 6. TRANSFER
                      _MenuIcon(Icons.swap_horiz, AppStrings.get('transfer', lang), Colors.green.shade700, 
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TransferMoneyScreen()))),

                      // 7. Settings
                      _MenuIcon(Icons.settings, AppStrings.get('settings', lang), Colors.blueGrey, 
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()))),
                      
                      // 8. Bike Tracker
                      _MenuIcon(Icons.directions_bike, "Bike", Colors.brown, 
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BikeScreen()))),
                      
                      // 9. Bazar List
                      _MenuIcon(Icons.shopping_cart, "Bazar List", Colors.deepOrange, 
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ShoppingListScreen()))),
                    ],
                  ),
                ),

                // --- SUMMARY CARD ---
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, spreadRadius: 2)],
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: _BigNumber(AppStrings.get('receive', lang), totalDue, Colors.red)), 
                      Container(width: 1, height: 40, color: Colors.grey.shade300), 
                      Expanded(child: _BigNumber(AppStrings.get('pay', lang), totalPayable, Colors.green)), 
                    ],
                  ),
                ),

                // --- SEARCH BAR ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PartyListScreen())),
                          child: Container(
                            height: 45,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.search, color: Colors.grey),
                                const SizedBox(width: 10),
                                Text(AppStrings.get('search_contacts', lang), style: TextStyle(color: Colors.grey.shade600)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _SquareIconBtn(Icons.filter_list, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TransactionHistoryScreen()))),
                      const SizedBox(width: 10),
                      _SquareIconBtn(Icons.download, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportScreen()))),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // --- LIST HEADER ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Text(AppStrings.get('customers_suppliers', lang), style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),

          // --- CUSTOMER LIST ---
          partyListAsync.when(
            data: (parties) {
              if (parties.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Center(child: Text(AppStrings.get('no_contacts', lang), style: const TextStyle(color: Colors.grey))),
                  ),
                );
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = parties[index];
                    final balance = item.balance;
                    final isPositive = balance >= 0; 
                    
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue.shade50,
                        child: Text(item.party.name[0].toUpperCase(), style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                      ),
                      title: Text(item.party.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(item.party.mobile, style: const TextStyle(fontSize: 12)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "৳ ${balance.abs().toStringAsFixed(0)}",
                            style: TextStyle(
                              color: isPositive ? Colors.red : Colors.green, 
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => PartyLedgerScreen(party: item.party)));
                      },
                    );
                  },
                  childCount: parties.length,
                ),
              );
            },
            loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
            error: (e, s) => SliverToBoxAdapter(child: Center(child: Text("Error: $e"))),
          ),
          
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0, 
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: "Tally"),
          BottomNavigationBarItem(icon: Icon(Icons.inbox), label: "Cashbox"),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: "Wallet"),
          BottomNavigationBarItem(icon: Icon(Icons.menu), label: "Menu"),
        ],
        onTap: (index) {
          if(index == 1) Navigator.push(context, MaterialPageRoute(builder: (_) => const TransactionHistoryScreen()));
          if(index == 2) Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen()));
          if(index == 3) Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
        },
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AddTransactionScreen()));
        },
        backgroundColor: Colors.red, 
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
    );
  }
}

// --- WIDGETS ---

class _MenuIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MenuIcon(this.icon, this.label, this.color, this.onTap);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label, 
            textAlign: TextAlign.center, 
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _BigNumber extends StatelessWidget {
  final String label;
  final AsyncValue<double> amountProvider;
  final Color color;

  const _BigNumber(this.label, this.amountProvider, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        amountProvider.when(
          data: (val) => Text(
            "৳ ${val.abs().toStringAsFixed(0)}", 
            style: TextStyle(color: color, fontSize: 26, fontWeight: FontWeight.bold),
          ),
          loading: () => const Text("...", style: TextStyle(fontSize: 24)),
          error: (e, s) => const Text("-"),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}

class _SquareIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _SquareIconBtn(this.icon, this.onTap);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.black54, size: 24),
      ),
    );
  }
}
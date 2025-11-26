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
import '../../wallets/presentation/transfer_money_screen.dart';
import '../../analytics/presentation/analytics_screen.dart';
import '../../bike/presentation/bike_screen.dart';
import '../../shopping/presentation/shopping_list_screen.dart';

// --- NEW IMPORTS ---
import '../../budget/presentation/budget_screen.dart';
import '../../recurring/presentation/recurring_bill_screen.dart';
import '../../savings/presentation/saving_goal_screen.dart';

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
                    crossAxisCount: 4, // Cleaned up layout to 4 columns
                    mainAxisSpacing: 16, 
                    crossAxisSpacing: 8, 
                    childAspectRatio: 0.9, 
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), 
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
                      
                      // --- NEW FEATURES ---
                      
                      // 5. Budgeting
                      _MenuIcon(Icons.calculate, "Budget", Colors.teal, 
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BudgetScreen()))),
                      
                      // 6. Bills (Recurring)
                      _MenuIcon(Icons.calendar_month, "Bills", Colors.redAccent, 
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RecurringBillScreen()))),

                      // 7. Savings
                      _MenuIcon(Icons.savings, "Savings", Colors.green, 
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SavingGoalScreen()))),
                      
                      // 8. Bike Tracker
                      _MenuIcon(Icons.directions_bike, "Bike", Colors.brown, 
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BikeScreen()))),
                      
                      // 9. Bazar List
                      _MenuIcon(Icons.shopping_cart, "Bazar", Colors.deepOrange, 
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ShoppingListScreen()))),

                      // 10. Transfer
                      _MenuIcon(Icons.swap_horiz, AppStrings.get('transfer', lang), Colors.blueGrey, 
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TransferMoneyScreen()))),

                      // 11. Wallets
                      _MenuIcon(Icons.account_balance_wallet, "Wallets", Colors.cyan, 
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen()))),

                      // 12. Settings
                      _MenuIcon(Icons.settings, AppStrings.get('settings', lang), Colors.grey.shade700, 
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()))),
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
                      Expanded(child: _BigNumber(AppStrings.get('receive', lang), totalDue, Colors.green)), // Pabo is Green
                      Container(width: 1, height: 40, color: Colors.grey.shade300), 
                      Expanded(child: _BigNumber(AppStrings.get('pay', lang), totalPayable, Colors.red)), // Dibo is Red
                    ],
                  ),
                ),

                // --- LIST HEADER ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(AppStrings.get('customers_suppliers', lang), style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                      TextButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PartyListScreen())),
                         child: const Text("View All")
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 5),
              ],
            ),
          ),

          // --- CUSTOMER LIST ---
          partyListAsync.when(
            data: (parties) {
              // Show only top 5 recent or non-zero balance for dashboard
              final dashboardList = parties.take(10).toList();
              
              if (dashboardList.isEmpty) {
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
                    final item = dashboardList[index];
                    final balance = item.balance;
                    // Dashboard colors: Green if I get money (Pabo), Red if I pay (Dibo)
                    final isPabo = balance > 0;
                    
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
                              color: isPabo ? Colors.green : Colors.red, 
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
                  childCount: dashboardList.length,
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
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: "Dash"),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: "History"),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: "Contacts"),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Menu"),
        ],
        onTap: (index) {
          if(index == 1) Navigator.push(context, MaterialPageRoute(builder: (_) => const TransactionHistoryScreen()));
          if(index == 2) Navigator.push(context, MaterialPageRoute(builder: (_) => const PartyListScreen()));
          if(index == 3) Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
        },
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AddTransactionScreen()));
        },
        backgroundColor: Colors.blue[800], 
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
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.blue.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
              ],
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
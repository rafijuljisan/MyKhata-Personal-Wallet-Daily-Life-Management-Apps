import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../data/transaction_repository.dart';
import 'add_transaction_screen.dart';
import '../../settings/data/language_provider.dart'; // Import Language Logic

class TransactionHistoryScreen extends ConsumerStatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  ConsumerState<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends ConsumerState<TransactionHistoryScreen> {
  bool _isSearching = false;
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  // New Filters
  DateTimeRange? _selectedDateRange;
  String _filterType = 'ALL'; // ALL, CASH_IN, CASH_OUT, DUE_GIVEN, DUE_RECEIVED

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(allTransactionsProvider);
    final lang = ref.watch(languageProvider);

    // Helper for Dropdown Labels
    String getLabel(String type) {
      switch(type) {
        case 'ALL': return lang == 'bn' ? 'সকল লেনদেন' : 'All Transactions';
        case 'CASH_IN': return AppStrings.get('cash_in', lang);
        case 'CASH_OUT': return AppStrings.get('cash_out', lang);
        case 'DUE_GIVEN': return AppStrings.get('add_due', lang);
        case 'DUE_RECEIVED': return AppStrings.get('receive_due', lang);
        default: return type;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: !_isSearching
            ? Text(AppStrings.get('all_history', lang))
            : TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                cursorColor: Colors.white,
                decoration: InputDecoration(
                  hintText: AppStrings.get('search_history', lang),
                  hintStyle: const TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
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
      body: Column(
        children: [
          // --- 1. FILTER SECTION ---
          Container(
            color: Colors.teal.shade50,
            child: ExpansionTile(
              title: Text(
                _selectedDateRange == null && _filterType == 'ALL' 
                    ? (lang == 'bn' ? "ফিল্টার (তারিখ ও ধরণ)" : "Filter (Date & Type)")
                    : (lang == 'bn' ? "ফিল্টার চালু আছে" : "Filters Active"),
                style: TextStyle(
                  color: _selectedDateRange != null || _filterType != 'ALL' ? Colors.red : Colors.black87,
                  fontWeight: FontWeight.bold
                ),
              ),
              leading: Icon(Icons.filter_list, color: Colors.red[900]),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    children: [
                      // Date Picker
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 45),
                          side: BorderSide(color: Colors.red),
                        ),
                        onPressed: () async {
                          final picked = await showDateRangePicker(
                            context: context,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                            initialDateRange: _selectedDateRange,
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: ColorScheme.light(primary: Colors.red),
                                ),
                                child: child!,
                              );
                            }
                          );
                          if (picked != null) {
                            setState(() => _selectedDateRange = picked);
                          }
                        },
                        icon: Icon(Icons.date_range, color: Colors.red),
                        label: Text(
                          _selectedDateRange == null 
                            ? (lang == 'bn' ? "তারিখ নির্বাচন করুন" : "Select Date Range")
                            : "${DateFormat('dd MMM').format(_selectedDateRange!.start)} - ${DateFormat('dd MMM').format(_selectedDateRange!.end)}",
                          style: const TextStyle(color: Colors.black87),
                        ),
                      ),
                      const SizedBox(height: 10),
                      
                      // Type Dropdown
                      DropdownButtonFormField<String>(
                        value: _filterType,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          isDense: true,
                        ),
                        items: ['ALL', 'CASH_IN', 'CASH_OUT', 'DUE_GIVEN', 'DUE_RECEIVED']
                            .map((type) => DropdownMenuItem(
                              value: type,
                              child: Text(getLabel(type), style: const TextStyle(fontSize: 14)),
                            )).toList(),
                        onChanged: (val) => setState(() => _filterType = val!),
                      ),
                      
                      // Clear Button
                      if (_selectedDateRange != null || _filterType != 'ALL')
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              setState(() {
                                _selectedDateRange = null;
                                _filterType = 'ALL';
                              });
                            },
                            child: Text(lang == 'bn' ? "ফিল্টার মুছুন" : "Clear Filters", style: TextStyle(color: Colors.red)),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // --- 2. LIST SECTION ---
          Expanded(
            child: history.when(
              data: (data) {
                final filteredData = data.where((item) {
                  final txn = item.transaction;
                  
                  // 1. Search Filter
                  final note = (txn.details ?? "").toLowerCase();
                  final amount = txn.amount.toString();
                  final partyName = (item.party?.name ?? "").toLowerCase();
                  final matchesSearch = note.contains(_searchQuery) || amount.contains(_searchQuery) || partyName.contains(_searchQuery);
                  if (!matchesSearch) return false;

                  // 2. Date Filter
                  if (_selectedDateRange != null) {
                    final date = txn.date;
                    final start = DateUtils.dateOnly(_selectedDateRange!.start);
                    final end = DateUtils.dateOnly(_selectedDateRange!.end).add(const Duration(days: 1));
                    if (date.isBefore(start) || date.isAfter(end) || date.isAtSameMomentAs(end)) {
                       return false;
                    }
                  }

                  // 3. Type Filter
                  if (_filterType != 'ALL') {
                    if (txn.txnType != _filterType) return false;
                  }

                  return true;
                }).toList();

                if (filteredData.isEmpty) {
                  return Center(child: Text(AppStrings.get('no_transactions', lang)));
                }
                
                return ListView.builder(
                  itemCount: filteredData.length,
                  itemBuilder: (context, index) {
                    final item = filteredData[index];
                    final txn = item.transaction;
                    final party = item.party;

                    Color color;
                    IconData icon;
                    String title;
                    
                    switch (txn.txnType) {
                      case 'CASH_IN':
                        color = Colors.teal;
                        icon = Icons.arrow_downward;
                        title = AppStrings.get('cash_in', lang);
                        break;
                      case 'CASH_OUT':
                        color = Colors.redAccent;
                        icon = Icons.arrow_upward;
                        title = AppStrings.get('cash_out', lang);
                        break;
                      case 'DUE_GIVEN':
                        color = Colors.red;
                        icon = Icons.person_remove;
                        title = "${AppStrings.get('gave', lang)}: ${party?.name ?? ''}";
                        break;
                      case 'DUE_RECEIVED':
                        color = Colors.green;
                        icon = Icons.person_add;
                        title = "${AppStrings.get('got', lang)}: ${party?.name ?? ''}";
                        break;
                      default:
                        color = Colors.grey;
                        icon = Icons.help;
                        title = "Unknown";
                    }

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      elevation: 2,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: color.withOpacity(0.1),
                          child: Icon(icon, color: color, size: 20),
                        ),
                        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          "${DateFormat('dd MMM hh:mm a').format(txn.date)}\n${txn.details ?? ''}",
                          style: const TextStyle(fontSize: 12),
                        ),
                        isThreeLine: true,
                        trailing: Text(
                          "৳ ${txn.amount.toStringAsFixed(0)}",
                          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        onLongPress: () {
                          showModalBottomSheet(
                            context: context,
                            builder: (ctx) => Wrap(
                              children: [
                                ListTile(
                                  leading: Icon(Icons.edit, color: Colors.red),
                                  title: Text(AppStrings.get('edit', lang)),
                                  onTap: () {
                                    Navigator.pop(ctx);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => AddTransactionScreen(transactionToEdit: txn),
                                      ),
                                    );
                                  },
                                ),
                                ListTile(
                                  leading: Icon(Icons.delete, color: Colors.red),
                                  title: Text(AppStrings.get('delete', lang)),
                                  onTap: () {
                                    Navigator.pop(ctx);
                                    _confirmDelete(context, ref, txn.id, lang);
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text("${AppStrings.get('error', lang)}: $e")),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, int id, String lang) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.get('delete_confirm_title', lang)),
        content: Text(AppStrings.get('delete_txn_msg', lang)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), 
            child: Text(AppStrings.get('cancel', lang))
          ),
          TextButton(
            onPressed: () {
              ref.read(transactionRepositoryProvider.notifier).deleteTransaction(id);
              Navigator.pop(ctx);
            },
            child: Text(AppStrings.get('delete', lang), style: TextStyle(color: Colors.red[900])),
          ),
        ],
      ),
    );
  }
}
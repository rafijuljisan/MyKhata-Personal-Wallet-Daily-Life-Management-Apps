import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../data/transaction_repository.dart';
import 'add_transaction_screen.dart';
import '../../settings/data/language_provider.dart';
import '../../categories/data/category_repository.dart'; // Import for Category Filter
import '../../../data/database.dart'; // For Category type

class TransactionHistoryScreen extends ConsumerStatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  ConsumerState<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends ConsumerState<TransactionHistoryScreen> {
  bool _isSearching = false;
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  // Filters
  DateTimeRange? _selectedDateRange;
  String _filterType = 'ALL'; // ALL, CASH_IN, CASH_OUT, DUE_GIVEN, DUE_RECEIVED
  int? _selectedCategoryId; // Category Filter

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(allTransactionsProvider);
    final lang = ref.watch(languageProvider);
    
    // Load categories for filter dropdown
    final incomeCats = ref.watch(incomeCategoriesProvider);
    final expenseCats = ref.watch(expenseCategoriesProvider);
    
    // IMPROVEMENT: Dynamically filter categories based on selected Type
    List<Category> displayedCategories = [];
    final allIncome = incomeCats.value ?? [];
    final allExpense = expenseCats.value ?? [];

    if (_filterType == 'CASH_IN') {
      displayedCategories = allIncome;
    } else if (_filterType == 'CASH_OUT') {
      displayedCategories = allExpense;
    } else {
      // For ALL or other types, show everything
      displayedCategories = [...allIncome, ...allExpense];
    }

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
                _selectedDateRange == null && _filterType == 'ALL' && _selectedCategoryId == null
                    ? (lang == 'bn' ? "ফিল্টার (তারিখ ও ধরণ)" : "Filter Options")
                    : (lang == 'bn' ? "ফিল্টার চালু আছে" : "Filters Active"),
                style: TextStyle(
                  color: (_selectedDateRange != null || _filterType != 'ALL' || _selectedCategoryId != null) 
                      ? Colors.red 
                      : Colors.black87,
                  fontWeight: FontWeight.bold
                ),
              ),
              leading: Icon(Icons.filter_list, color: Colors.teal[800]),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    children: [
                      // Date Picker
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 45),
                          side: const BorderSide(color: Colors.teal),
                        ),
                        onPressed: () async {
                          final picked = await showDateRangePicker(
                            context: context,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                            initialDateRange: _selectedDateRange,
                          );
                          if (picked != null) setState(() => _selectedDateRange = picked);
                        },
                        icon: const Icon(Icons.date_range, color: Colors.teal),
                        label: Text(
                          _selectedDateRange == null 
                            ? (lang == 'bn' ? "তারিখ নির্বাচন করুন" : "Select Date Range")
                            : "${DateFormat('dd MMM').format(_selectedDateRange!.start)} - ${DateFormat('dd MMM').format(_selectedDateRange!.end)}",
                          style: const TextStyle(color: Colors.black87),
                        ),
                      ),
                      const SizedBox(height: 10),
                      
                      Row(
                        children: [
                          // Type Filter
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _filterType,
                              decoration: const InputDecoration(labelText: "Type", border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10)),
                              items: ['ALL', 'CASH_IN', 'CASH_OUT', 'DUE_GIVEN', 'DUE_RECEIVED']
                                  .map((type) => DropdownMenuItem(value: type, child: Text(getLabel(type), style: const TextStyle(fontSize: 13)))).toList(),
                              onChanged: (val) => setState(() {
                                _filterType = val!;
                                // Reset Category selection when Type changes to prevent invalid state
                                _selectedCategoryId = null; 
                              }),
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Category Filter (Dynamic based on Type)
                          Expanded(
                            child: DropdownButtonFormField<int?>(
                              value: _selectedCategoryId,
                              decoration: const InputDecoration(labelText: "Category", border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10)),
                              items: [
                                const DropdownMenuItem<int?>(value: null, child: Text("All Categories")),
                                ...displayedCategories.map((cat) => DropdownMenuItem(value: cat.id, child: Text(cat.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13))))
                              ],
                              onChanged: (val) => setState(() => _selectedCategoryId = val),
                            ),
                          ),
                        ],
                      ),
                      
                      // Clear Button
                      if (_selectedDateRange != null || _filterType != 'ALL' || _selectedCategoryId != null)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              setState(() {
                                _selectedDateRange = null;
                                _filterType = 'ALL';
                                _selectedCategoryId = null;
                              });
                            },
                            child: Text(lang == 'bn' ? "ফিল্টার মুছুন" : "Clear Filters", style: const TextStyle(color: Colors.red)),
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
                  final catName = (item.category?.name ?? "").toLowerCase();
                  
                  final matchesSearch = note.contains(_searchQuery) || 
                                        amount.contains(_searchQuery) || 
                                        partyName.contains(_searchQuery) ||
                                        catName.contains(_searchQuery);
                  
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

                  // 4. Category Filter
                  if (_selectedCategoryId != null) {
                    if (txn.categoryId != _selectedCategoryId) return false;
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
                    final category = item.category;

                    Color color;
                    IconData icon;
                    String title;
                    
                    // Determine Icon & Title based on Data
                    switch (txn.txnType) {
                      case 'CASH_IN':
                        color = Colors.green;
                        icon = Icons.arrow_downward;
                        // Show Category Name if available, else "Cash In"
                        title = category?.name ?? AppStrings.get('cash_in', lang);
                        break;
                      case 'CASH_OUT':
                        color = Colors.redAccent;
                        icon = Icons.arrow_upward;
                        // Show Category Name if available (e.g. "Food"), else "Cash Out"
                        title = category?.name ?? AppStrings.get('cash_out', lang);
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
                      case 'TRANSFER_OUT':
                      case 'TRANSFER_IN':
                        color = Colors.blueGrey;
                        icon = Icons.swap_horiz;
                        title = "Transfer";
                        break;
                      default:
                        color = Colors.grey;
                        icon = Icons.help;
                        title = "Unknown";
                    }

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      elevation: 1,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: color.withOpacity(0.1),
                          child: Icon(icon, color: color, size: 20),
                        ),
                        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          "${DateFormat('dd MMM hh:mm a').format(txn.date)}\n${txn.details ?? ''}",
                          style: const TextStyle(fontSize: 12, color: Colors.black54),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
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
                                  leading: const Icon(Icons.edit, color: Colors.blue),
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
                                  leading: const Icon(Icons.delete, color: Colors.red),
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
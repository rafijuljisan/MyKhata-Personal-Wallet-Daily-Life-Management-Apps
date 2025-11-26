import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../data/database.dart';
import '../data/transaction_repository.dart';
import '../../settings/data/language_provider.dart'; 
import '../../categories/data/category_repository.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  final Transaction? transactionToEdit; 

  const AddTransactionScreen({super.key, this.transactionToEdit});

  @override
  ConsumerState<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  // Mode: Single or Split
  bool _isSplitMode = false;

  // Single Transaction Controllers
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  int? _selectedCategoryId;

  // Split Transaction Data
  List<Map<String, dynamic>> _splitItems = [];

  String _selectedType = 'CASH_IN'; 
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _initSplitItems(); 

    if (widget.transactionToEdit != null) {
      final t = widget.transactionToEdit!;
      _amountController.text = t.amount.toStringAsFixed(0);
      _noteController.text = t.details ?? "";
      _selectedType = t.txnType;
      _selectedCategoryId = t.categoryId;
      _selectedDate = t.date;
    }
  }

  void _initSplitItems() {
    if (_splitItems.isEmpty) {
      _addSplitRow();
      _addSplitRow();
    }
  }

  void _addSplitRow() {
    setState(() {
      _splitItems.add({
        'controller': TextEditingController(),
        'categoryId': null,
        'note': ''
      });
    });
  }

  void _removeSplitRow(int index) {
    setState(() {
      _splitItems[index]['controller'].dispose();
      _splitItems.removeAt(index);
    });
  }

  double get _totalSplitAmount {
    double total = 0;
    for (var item in _splitItems) {
      double val = double.tryParse(item['controller'].text) ?? 0;
      total += val;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.transactionToEdit != null;
    final lang = ref.watch(languageProvider);
    
    // Fetch Categories based on Type (Income/Expense)
    final categoryAsync = _selectedType == 'CASH_IN' 
        ? ref.watch(incomeCategoriesProvider)
        : ref.watch(expenseCategoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? "Edit Transaction" : "Add Transaction"),
        actions: [
           // Split Toggle
           if (!isEditing)
             Row(
               children: [
                 const Text("Split", style: TextStyle(fontSize: 12)),
                 Switch(
                   value: _isSplitMode, 
                   onChanged: (val) => setState(() => _isSplitMode = val),
                   activeColor: Colors.white,
                   activeTrackColor: Colors.orange,
                 ),
               ],
             )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Transaction Type
            if (widget.transactionToEdit?.partyId == null)
              Row(
                children: [
                  Expanded(child: _typeButton(AppStrings.get('cash_in', lang), Colors.blue, 'CASH_IN')),
                  const SizedBox(width: 10),
                  Expanded(child: _typeButton(AppStrings.get('cash_out', lang), Colors.red, 'CASH_OUT')),
                ],
              ),
            const SizedBox(height: 20),

            // 2. Date Picker
            ListTile(
              contentPadding: EdgeInsets.zero,
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
            const SizedBox(height: 20),

            // 3. MAIN INPUT AREA
            if (_isSplitMode) ...[
              const Text("Split Breakdown", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              
              ..._splitItems.asMap().entries.map((entry) {
                int idx = entry.key;
                Map item = entry.value;
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextField(
                                controller: item['controller'],
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(labelText: "Amount", isDense: true, border: OutlineInputBorder()),
                                onChanged: (_) => setState((){}),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 3,
                              child: _buildCategoryDropdown(
                                categoryAsync, 
                                item['categoryId'], 
                                (val) => setState(() => item['categoryId'] = val)
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _removeSplitRow(idx),
                            )
                          ],
                        ),
                        TextField(
                           decoration: const InputDecoration(labelText: "Item details (optional)", border: InputBorder.none),
                           onChanged: (val) => item['note'] = val,
                        )
                      ],
                    ),
                  ),
                );
              }).toList(),

              Center(
                child: TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text("Add Another Item"),
                  onPressed: _addSplitRow,
                ),
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Total Amount:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text("৳ ${_totalSplitAmount.toStringAsFixed(0)}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)),
                ],
              ),

            ] else ...[
              // SINGLE MODE
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: AppStrings.get('amount', lang), 
                  border: const OutlineInputBorder()
                ),
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: _buildCategoryDropdown(
                      categoryAsync, 
                      _selectedCategoryId, 
                      (val) => setState(() => _selectedCategoryId = val)
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: Colors.blue, size: 30),
                    onPressed: () => _showAddCategoryDialog(context),
                  )
                ],
              ),
              const SizedBox(height: 20),
            ],

            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                labelText: _isSplitMode ? "Main Note" : AppStrings.get('note', lang), 
                border: const OutlineInputBorder()
              ),
            ),

            const SizedBox(height: 40),
            
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saveTransaction,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                child: Text(isEditing ? AppStrings.get('update', lang) : AppStrings.get('save', lang)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown(AsyncValue<List<Category>> asyncData, int? selectedId, Function(int?) onChanged) {
    return asyncData.when(
      data: (categories) {
        if (categories.isEmpty) {
          return const InputDecorator(
            decoration: InputDecoration(border: OutlineInputBorder(), labelText: "Category"),
            child: Text("No categories found", style: TextStyle(color: Colors.grey)),
          );
        }

        // Ensure selectedId exists in the list to avoid crashes
        final isValidSelection = selectedId != null && categories.any((c) => c.id == selectedId);
        final safeValue = isValidSelection ? selectedId : null;

        return DropdownButtonFormField<int>(
          value: safeValue,
          decoration: const InputDecoration(labelText: "Category", border: OutlineInputBorder(), isDense: true),
          items: categories.map((cat) {
            return DropdownMenuItem<int>(
              value: cat.id, 
              child: Text(cat.name, overflow: TextOverflow.ellipsis)
            );
          }).toList(),
          onChanged: onChanged,
          hint: const Text("Select"),
        );
      },
      loading: () => const LinearProgressIndicator(),
      error: (e, s) => const Text("Error loading categories"),
    );
  }

  Widget _typeButton(String text, Color color, String type) {
    final isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = type;
          _selectedCategoryId = null; // Reset category on type change
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(text, style: TextStyle(color: isSelected ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _saveTransaction() {
    if (_isSplitMode) {
      if (_totalSplitAmount <= 0) return;
      
      final List<Map<String, dynamic>> itemsToSave = [];
      for (var item in _splitItems) {
        double amt = double.tryParse(item['controller'].text) ?? 0;
        if (amt > 0) {
          itemsToSave.add({
            'amount': amt,
            'categoryId': item['categoryId'],
            'note': item['note']
          });
        }
      }

      ref.read(transactionRepositoryProvider.notifier).addSplitTransaction(
        items: itemsToSave,
        type: _selectedType,
        date: _selectedDate,
        mainNote: _noteController.text,
      );

    } else {
      if (_amountController.text.isEmpty) return;
      final amount = double.parse(_amountController.text);
      
      if (widget.transactionToEdit == null) {
        ref.read(transactionRepositoryProvider.notifier).addCashTransaction(
          amount: amount,
          type: _selectedType,
          categoryId: _selectedCategoryId, 
          note: _noteController.text,
          date: _selectedDate,
        );
      } else {
        final updatedTxn = widget.transactionToEdit!.copyWith(
          amount: amount,
          txnType: _selectedType,
          categoryId: drift.Value(_selectedCategoryId),
          details: drift.Value(_noteController.text),
          date: _selectedDate,
        );
        ref.read(transactionRepositoryProvider.notifier).updateTransaction(updatedTxn);
      }
    }
    
    Navigator.pop(context);
  }

  Future<void> _showAddCategoryDialog(BuildContext context) async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Add New Category"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: "Category Name"),
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                // FIX: Map CASH_IN to INCOME and CASH_OUT to EXPENSE
                // This matches what the database and providers expect
                final categoryType = _selectedType == 'CASH_IN' ? 'INCOME' : 'EXPENSE';
                
                ref.read(categoryRepositoryProvider.notifier)
                  .addCategory(controller.text, categoryType);
                Navigator.pop(ctx);
              }
            },
            child: const Text("Add"),
          )
        ],
      ),
    );
  }
}
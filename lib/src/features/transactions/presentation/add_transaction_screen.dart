import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../data/database.dart';
import '../data/transaction_repository.dart';
import '../../settings/data/language_provider.dart'; 

class AddTransactionScreen extends ConsumerStatefulWidget {
  final Transaction? transactionToEdit; 

  const AddTransactionScreen({super.key, this.transactionToEdit});

  @override
  ConsumerState<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String _selectedType = 'CASH_IN'; 
  String _selectedCategory = 'Others'; 
  DateTime _selectedDate = DateTime.now();

  final List<String> _incomeCategories = ['Sales', 'Salary', 'Refund', 'Gift', 'Others'];
  final List<String> _expenseCategories = ['Purchase', 'Rent', 'Food', 'Transport', 'Bills', 'Health', 'Entertainment', 'Others'];

  @override
  void initState() {
    super.initState();
    if (widget.transactionToEdit != null) {
      final t = widget.transactionToEdit!;
      _amountController.text = t.amount.toStringAsFixed(0);
      _noteController.text = t.details ?? "";
      _selectedType = t.txnType;
      _selectedCategory = t.category ?? "Others"; 
      _selectedDate = t.date;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.transactionToEdit != null;
    final lang = ref.watch(languageProvider);
    
    final currentCategories = _selectedType == 'CASH_IN' ? _incomeCategories : _expenseCategories;
    
    if (!currentCategories.contains(_selectedCategory)) {
      _selectedCategory = 'Others';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing 
          ? AppStrings.get('edit_transaction', lang) 
          : AppStrings.get('add_transaction', lang)
        )
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: AppStrings.get('amount', lang), 
                border: const OutlineInputBorder()
              ),
            ),
            const SizedBox(height: 20),
            
            if (widget.transactionToEdit?.partyId == null)
              Row(
                children: [
                  Expanded(child: _typeButton(AppStrings.get('cash_in', lang), Colors.blue, 'CASH_IN')),
                  const SizedBox(width: 10),
                  Expanded(child: _typeButton(AppStrings.get('cash_out', lang), Colors.red, 'CASH_OUT')),
                ],
              ),
            
            const SizedBox(height: 20),

            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: "Category",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              items: currentCategories.map((String category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedCategory = val!;
                });
              },
            ),

            const SizedBox(height: 20),

            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                labelText: AppStrings.get('note', lang), 
                border: const OutlineInputBorder()
              ),
            ),
             const SizedBox(height: 20),
             
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

            // --- FIXED: Replaced Spacer() with SizedBox ---
            const SizedBox(height: 40),
            
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saveTransaction,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                child: Text(isEditing 
                  ? AppStrings.get('update', lang) 
                  : AppStrings.get('save', lang)
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeButton(String text, Color color, String type) {
    final isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedType = type),
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
    if (_amountController.text.isEmpty) return;
    
    final amount = double.parse(_amountController.text);
    final note = _noteController.text;

    if (widget.transactionToEdit == null) {
      ref.read(transactionRepositoryProvider.notifier).addCashTransaction(
        amount: amount,
        type: _selectedType,
        category: _selectedCategory, 
        note: note,
        date: _selectedDate,
      );
    } else {
      final updatedTxn = widget.transactionToEdit!.copyWith(
        amount: amount,
        txnType: _selectedType,
        category: drift.Value(_selectedCategory),
        details: drift.Value(note),
        date: _selectedDate,
      );
      ref.read(transactionRepositoryProvider.notifier).updateTransaction(updatedTxn);
    }
    
    Navigator.pop(context);
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../data/recurring_repository.dart';
import '../../categories/data/category_repository.dart';
import '../../../data/database.dart';

class RecurringBillScreen extends ConsumerStatefulWidget {
  const RecurringBillScreen({super.key});

  @override
  ConsumerState<RecurringBillScreen> createState() => _RecurringBillScreenState();
}

class _RecurringBillScreenState extends ConsumerState<RecurringBillScreen> {
  @override
  Widget build(BuildContext context) {
    final billsAsync = ref.watch(upcomingBillsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Recurring Bills & Subscriptions"),
      ),
      body: billsAsync.when(
        data: (bills) {
          if (bills.isEmpty) {
            return const Center(
              child: Text("No recurring bills set up.\nAdd your Rent, Internet, or Tuition fees.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bills.length,
            itemBuilder: (context, index) {
              final bill = bills[index];
              return _BillCard(
                bill: bill,
                onEdit: () => _showAddBillDialog(context, billToEdit: bill), // Pass bill to edit
                onDelete: () => _confirmDelete(context, bill.id),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text("Error: $e")),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddBillDialog(context),
        label: const Text("Add Bill"),
        icon: const Icon(Icons.add_alarm),
      ),
    );
  }

  void _showAddBillDialog(BuildContext context, {RecurringTransaction? billToEdit}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _AddBillSheet(billToEdit: billToEdit),
    );
  }

  void _confirmDelete(BuildContext context, int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Bill?"),
        content: const Text("This will permanently remove this reminder."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              ref.read(recurringRepositoryProvider.notifier).deleteRecurring(id);
              Navigator.pop(ctx);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _BillCard extends ConsumerWidget {
  final RecurringTransaction bill;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _BillCard({
    required this.bill,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final daysUntilDue = bill.nextDueDate.difference(now).inDays;
    
    Color statusColor = Colors.green;
    String statusText = "Due in $daysUntilDue days";
    
    if (daysUntilDue < 0) {
      statusColor = Colors.red;
      statusText = "Overdue by ${daysUntilDue.abs()} days!";
    } else if (daysUntilDue == 0) {
      statusColor = Colors.red;
      statusText = "Due Today!";
    } else if (daysUntilDue <= 3) {
      statusColor = Colors.orange;
      statusText = "Due soon ($daysUntilDue days)";
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        side: daysUntilDue <= 3 ? BorderSide(color: statusColor, width: 2) : BorderSide.none,
        borderRadius: BorderRadius.circular(12)
      ),
      child: InkWell(
        // NEW: Long Press to Edit/Delete
        onLongPress: () {
          showModalBottomSheet(
            context: context,
            builder: (ctx) => Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.edit, color: Colors.blue),
                  title: const Text("Edit Bill"),
                  onTap: () {
                    Navigator.pop(ctx);
                    onEdit();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text("Delete Bill"),
                  onTap: () {
                    Navigator.pop(ctx);
                    onDelete();
                  },
                ),
              ],
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(bill.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      const SizedBox(height: 4),
                      Text(
                        "${DateFormat('dd MMM yyyy').format(bill.nextDueDate)} (${bill.frequency})",
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                  Text(
                    "৳ ${bill.amount.toStringAsFixed(0)}", 
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blueGrey),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                    child: Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () {
                      ref.read(recurringRepositoryProvider.notifier).markAsPaid(bill.id);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Marked as Paid! Next due date updated.")));
                    },
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text("PAY NOW"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue, 
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    ),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _AddBillSheet extends ConsumerStatefulWidget {
  final RecurringTransaction? billToEdit;
  const _AddBillSheet({this.billToEdit});

  @override
  ConsumerState<_AddBillSheet> createState() => _AddBillSheetState();
}

class _AddBillSheetState extends ConsumerState<_AddBillSheet> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  
  String _selectedFrequency = 'MONTHLY';
  DateTime _selectedDate = DateTime.now();
  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    // PRE-FILL if Editing
    if (widget.billToEdit != null) {
      final b = widget.billToEdit!;
      _nameController.text = b.name;
      _amountController.text = b.amount.toStringAsFixed(0);
      _selectedFrequency = b.frequency;
      _selectedDate = b.nextDueDate;
      _selectedCategoryId = b.categoryId;
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(expenseCategoriesProvider);
    final isEditing = widget.billToEdit != null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16, right: 16, top: 16
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(isEditing ? "Edit Bill" : "Add Recurring Bill", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: "Bill Name (e.g. Rent, Netflix)", border: OutlineInputBorder()),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Amount", border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedFrequency,
                  decoration: const InputDecoration(labelText: "Repeat", border: OutlineInputBorder()),
                  items: ['DAILY', 'WEEKLY', 'MONTHLY', 'YEARLY'].map((f) {
                    return DropdownMenuItem(value: f, child: Text(f));
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedFrequency = val!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text("Next Due Date: ${DateFormat('dd MMM yyyy').format(_selectedDate)}"),
            trailing: const Icon(Icons.calendar_today),
            shape: RoundedRectangleBorder(side: BorderSide(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2023),
                lastDate: DateTime(2030),
              );
              if (date != null) setState(() => _selectedDate = date);
            },
          ),
          const SizedBox(height: 10),
          
          categoriesAsync.when(
            data: (cats) => DropdownButtonFormField<int>(
              value: _selectedCategoryId,
              decoration: const InputDecoration(labelText: "Category", border: OutlineInputBorder()),
              items: cats.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
              onChanged: (v) => setState(() => _selectedCategoryId = v),
            ),
            loading: () => const LinearProgressIndicator(),
            error: (e, s) => const Text("Failed to load categories"),
          ),
          
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (_nameController.text.isEmpty || _amountController.text.isEmpty || _selectedCategoryId == null) {
                  return;
                }
                
                if (isEditing) {
                  // Update Existing
                  ref.read(recurringRepositoryProvider.notifier).updateRecurring(
                    id: widget.billToEdit!.id,
                    name: _nameController.text,
                    amount: double.parse(_amountController.text),
                    categoryId: _selectedCategoryId!,
                    frequency: _selectedFrequency,
                    nextDueDate: _selectedDate,
                  );
                } else {
                  // Add New
                  ref.read(recurringRepositoryProvider.notifier).addRecurring(
                    name: _nameController.text,
                    amount: double.parse(_amountController.text),
                    type: 'CASH_OUT',
                    categoryId: _selectedCategoryId!,
                    frequency: _selectedFrequency,
                    firstDueDate: _selectedDate,
                  );
                }
                Navigator.pop(context);
              },
              child: Text(isEditing ? "Update Bill" : "Save Reminder"),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/database.dart'; // Needed for Party type
import '../data/party_repository.dart';

class AddPartyScreen extends ConsumerStatefulWidget {
  final Party? partyToEdit; // If null = Add Mode, If set = Edit Mode

  const AddPartyScreen({super.key, this.partyToEdit});

  @override
  ConsumerState<AddPartyScreen> createState() => _AddPartyScreenState();
}

class _AddPartyScreenState extends ConsumerState<AddPartyScreen> {
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  String _selectedType = 'CUSTOMER'; 

  @override
  void initState() {
    super.initState();
    // Pre-fill if editing
    if (widget.partyToEdit != null) {
      _nameController.text = widget.partyToEdit!.name;
      _mobileController.text = widget.partyToEdit!.mobile;
      _selectedType = widget.partyToEdit!.type;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.partyToEdit != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? "Edit Contact" : "Add Contact")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Name", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _mobileController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: "Mobile Number", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            
            // Toggle Customer / Supplier
            Row(
              children: [
                Expanded(child: _typeButton("Customer (Pabo)", Colors.green, 'CUSTOMER')),
                const SizedBox(width: 10),
                Expanded(child: _typeButton("Supplier (Dibo)", Colors.orange, 'SUPPLIER')),
              ],
            ),
            
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saveParty,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[900], foregroundColor: Colors.white),
                child: Text(isEditing ? "UPDATE" : "SAVE CONTACT"),
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

  void _saveParty() {
    if (_nameController.text.isEmpty) return;
    
    if (widget.partyToEdit == null) {
      // ADD NEW
      ref.read(partyRepositoryProvider.notifier).addParty(
        name: _nameController.text,
        mobile: _mobileController.text,
        type: _selectedType,
      );
    } else {
      // UPDATE EXISTING
      final updatedParty = widget.partyToEdit!.copyWith(
        name: _nameController.text,
        mobile: _mobileController.text,
        type: _selectedType,
      );
      ref.read(partyRepositoryProvider.notifier).updateParty(updatedParty);
    }
    
    Navigator.pop(context);
  }
}
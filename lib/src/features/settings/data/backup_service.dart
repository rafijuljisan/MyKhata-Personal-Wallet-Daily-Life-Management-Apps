import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../../../data/database.dart';
import '../../../data/tables.dart';
import 'google_drive_service.dart'; 

class BackupService {
  final AppDatabase db;
  final GoogleDriveService driveService;

  BackupService(this.db, this.driveService);

  // --- Helper: Generate JSON String (UPDATED with ALL Features) ---
  Future<String> _generateJsonString() async {
    // Fetch ALL data
    final allParties = await db.select(db.parties).get();
    final allTxns = await db.select(db.transactions).get();
    
    // New Features
    final allCategories = await db.select(db.categories).get();
    final allBudgets = await db.select(db.budgets).get();
    final allRecurring = await db.select(db.recurringTransactions).get();
    final allSavings = await db.select(db.savingGoals).get();

    final data = {
      "version": 2, // Bumped version to indicate new schema
      "date": DateTime.now().toIso8601String(),
      
      // 1. Parties
      "parties": allParties.map((p) => {
        "id": p.id,
        "name": p.name,
        "mobile": p.mobile,
        "type": p.type,
        "initialBalance": p.initialBalance,
      }).toList(),
      
      // 2. Transactions
      "transactions": allTxns.map((t) => {
        "amount": t.amount,
        "txnType": t.txnType,
        "date": t.date.toIso8601String(),
        "details": t.details,
        "partyId": t.partyId,
        "categoryId": t.categoryId, // Added categoryId
        "walletId": t.walletId,     // Added walletId
      }).toList(),

      // 3. Categories
      "categories": allCategories.map((c) => {
        "id": c.id,
        "name": c.name,
        "type": c.type,
        "isSystem": c.isSystem,
      }).toList(),

      // 4. Budgets
      "budgets": allBudgets.map((b) => {
        "id": b.id,
        "categoryId": b.categoryId,
        "limitAmount": b.limitAmount,
        "month": b.month,
        "year": b.year,
      }).toList(),

      // 5. Recurring Bills
      "recurring": allRecurring.map((r) => {
        "id": r.id,
        "name": r.name,
        "amount": r.amount,
        "type": r.type,
        "categoryId": r.categoryId,
        "frequency": r.frequency,
        "dayOfMonth": r.dayOfMonth,
        "nextDueDate": r.nextDueDate.toIso8601String(),
        "lastPaidDate": r.lastPaidDate?.toIso8601String(),
      }).toList(),

      // 6. Saving Goals
      "savings": allSavings.map((s) => {
        "id": s.id,
        "name": s.name,
        "targetAmount": s.targetAmount,
        "currentAmount": s.currentAmount,
        "targetDate": s.targetDate?.toIso8601String(),
        "createdAt": s.createdAt.toIso8601String(),
      }).toList(),
    };

    return jsonEncode(data);
  }

  // --- 1. SHARE BACKUP (Manual) ---
  Future<void> createBackup() async {
    final jsonString = await _generateJsonString();
    final directory = await getTemporaryDirectory();
    final dateStr = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    final file = File('${directory.path}/MyKhata_Backup_$dateStr.json');
    await file.writeAsString(jsonString);
    await Share.shareXFiles([XFile(file.path)], text: 'MyKhata Backup File');
  }

  // --- 2. AUTO BACKUP TO PHONE (FIXED: ONCE A DAY ONLY) ---
  Future<void> autoBackupToPhone({int retentionDays = 30}) async {
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      Directory? backupDir;

      // STRATEGY 1: Visible Download Folder
      final downloadDir = Directory('/storage/emulated/0/Download/MyKhata_Backups');
      if (!await downloadDir.exists()) {
        try { await downloadDir.create(recursive: true); } catch (e) { /* ignore */ }
      }

      if (await downloadDir.exists()) {
        backupDir = downloadDir;
      } else {
        // STRATEGY 2: App Internal Storage
        final appDir = await getExternalStorageDirectory();
        backupDir = Directory('${appDir!.path}/Backups');
        if (!await backupDir.exists()) await backupDir.create(recursive: true);
      }

      final file = File('${backupDir.path}/AutoBackup_$dateStr.json');

      // --- FIX: Check if today's backup ALREADY EXISTS ---
      if (await file.exists()) {
        print("Backup for today ($dateStr) already exists. Skipping.");
        return; 
      }

      // If not exists, generate and save
      final jsonString = await _generateJsonString();
      await file.writeAsString(jsonString);
      print("Auto Backup Success: ${file.path}");

      // Cleanup old files
      await _deleteOldBackups(backupDir, retentionDays);

    } catch (e) {
      print("Auto Backup Failed: $e");
    }
  }

  // Helper to cleanup
  Future<void> _deleteOldBackups(Directory dir, int daysToKeep) async {
    try {
      final List<FileSystemEntity> files = dir.listSync();
      final now = DateTime.now();

      for (var entity in files) {
        if (entity is File) {
          final filename = entity.uri.pathSegments.last;
          if (filename.startsWith('AutoBackup_') && filename.endsWith('.json')) {
            try {
              String datePart = filename.replaceFirst('AutoBackup_', '').replaceFirst('.json', '');
              DateTime fileDate = DateFormat('yyyy-MM-dd').parse(datePart);
              int difference = now.difference(fileDate).inDays;

              if (difference > daysToKeep) {
                await entity.delete();
              }
            } catch (e) { /* ignore */ }
          }
        }
      }
    } catch (e) { /* ignore */ }
  }

  // --- 3. RESTORE (UPDATED with New Tables) ---
  Future<bool> restoreBackup() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.single.path == null) return false;

      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();
      final Map<String, dynamic> data = jsonDecode(jsonString);

      // Use batch for better performance and atomicity
      await db.batch((batch) {
        // 1. Clear old data (Using delete all rows logic)
        batch.deleteWhere(db.transactions, (t) => const Constant(true));
        batch.deleteWhere(db.recurringTransactions, (t) => const Constant(true));
        batch.deleteWhere(db.budgets, (t) => const Constant(true));
        batch.deleteWhere(db.savingGoals, (t) => const Constant(true));
        batch.deleteWhere(db.parties, (t) => const Constant(true));
        batch.deleteWhere(db.categories, (t) => const Constant(true));

        // 2. Restore Categories (Dependencies first)
        if (data.containsKey('categories')) {
          for (var c in data['categories']) {
            batch.insert(db.categories, CategoriesCompanion.insert(
              id: Value(c['id']),
              name: c['name'],
              type: c['type'],
              isSystem: Value(c['isSystem'] ?? false),
            ), mode: InsertMode.insertOrReplace);
          }
        }

        // 3. Restore Parties
        if (data.containsKey('parties')) {
          for (var p in data['parties']) {
            batch.insert(db.parties, PartiesCompanion.insert(
              id: Value(p['id']),
              name: p['name'],
              mobile: p['mobile'],
              type: p['type'],
              initialBalance: Value(p['initialBalance']),
            ), mode: InsertMode.insertOrReplace);
          }
        }

        // 4. Restore Transactions
        if (data.containsKey('transactions')) {
          for (var t in data['transactions']) {
            batch.insert(db.transactions, TransactionsCompanion.insert(
              amount: t['amount'],
              txnType: t['txnType'],
              date: DateTime.parse(t['date']),
              details: Value(t['details']),
              partyId: Value(t['partyId']),
              categoryId: Value(t['categoryId']), // Restore Category Link
              walletId: Value(t['walletId']),     // Restore Wallet Link
            ));
          }
        }

        // 5. Restore Budgets
        if (data.containsKey('budgets')) {
          for (var b in data['budgets']) {
            batch.insert(db.budgets, BudgetsCompanion.insert(
              id: Value(b['id']),
              categoryId: b['categoryId'],
              limitAmount: b['limitAmount'],
              month: b['month'],
              year: b['year'],
            ));
          }
        }

        // 6. Restore Recurring
        if (data.containsKey('recurring')) {
          for (var r in data['recurring']) {
            batch.insert(db.recurringTransactions, RecurringTransactionsCompanion.insert(
              id: Value(r['id']),
              name: r['name'],
              amount: r['amount'],
              type: r['type'],
              categoryId: r['categoryId'],
              frequency: Value(r['frequency'] ?? 'MONTHLY'),
              dayOfMonth: r['dayOfMonth'],
              nextDueDate: DateTime.parse(r['nextDueDate']),
              lastPaidDate: r['lastPaidDate'] != null ? Value(DateTime.parse(r['lastPaidDate'])) : const Value(null),
            ));
          }
        }

        // 7. Restore Savings
        if (data.containsKey('savings')) {
          for (var s in data['savings']) {
            batch.insert(db.savingGoals, SavingGoalsCompanion.insert(
              id: Value(s['id']),
              name: s['name'],
              targetAmount: s['targetAmount'],
              currentAmount: Value(s['currentAmount']),
              targetDate: s['targetDate'] != null ? Value(DateTime.parse(s['targetDate'])) : const Value(null),
              createdAt: Value(DateTime.parse(s['createdAt'])),
            ));
          }
        }
      });

      return true;
    } catch (e) {
      print("Restore Error: $e");
      return false;
    }
  }
  
  // Placeholder for uploadToDrive
  Future<bool> uploadToDrive() async {
    try {
      final jsonString = await _generateJsonString();
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/temp_drive.json');
      await file.writeAsString(jsonString);
      return await driveService.uploadBackup(file);
    } catch (e) { return false; }
  }
}

final backupServiceProvider = Provider((ref) {
  return BackupService(
    ref.watch(databaseProvider),
    ref.watch(googleDriveProvider),
  );
});
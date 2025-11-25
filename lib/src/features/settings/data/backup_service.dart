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

  // --- Helper: Generate JSON String ---
  Future<String> _generateJsonString() async {
    final allParties = await db.select(db.parties).get();
    final allTxns = await db.select(db.transactions).get();

    final data = {
      "version": 1,
      "date": DateTime.now().toIso8601String(),
      "parties": allParties.map((p) => {
        "id": p.id,
        "name": p.name,
        "mobile": p.mobile,
        "type": p.type,
        "initialBalance": p.initialBalance,
      }).toList(),
      "transactions": allTxns.map((t) => {
        "amount": t.amount,
        "txnType": t.txnType,
        "date": t.date.toIso8601String(),
        "details": t.details,
        "partyId": t.partyId,
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

  // --- 2. AUTO BACKUP TO PHONE (With Auto-Delete) ---
  // retentionDays: Files older than this will be deleted (Default: 30 Days)
  Future<void> autoBackupToPhone({int retentionDays = 30}) async {
    try {
      final jsonString = await _generateJsonString();
      final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      
      Directory? backupDir;

      // STRATEGY 1: Try visible "Downloads" folder (Preferred for visibility)
      final downloadDir = Directory('/storage/emulated/0/Download/MyKhata_Backups');
      
      if (!await downloadDir.exists()) {
        try {
          await downloadDir.create(recursive: true);
        } catch (e) {
          print("Could not create Download dir: $e");
        }
      }

      if (await downloadDir.exists()) {
        backupDir = downloadDir;
      } else {
        // STRATEGY 2: Fallback to App-Specific Storage (Hidden but reliable)
        final appDir = await getExternalStorageDirectory();
        backupDir = Directory('${appDir!.path}/Backups');
        if (!await backupDir.exists()) {
          await backupDir.create(recursive: true);
        }
      }

      // Save the New Backup
      final file = File('${backupDir.path}/AutoBackup_$dateStr.json');
      await file.writeAsString(jsonString);
      print("Auto Backup Success: ${file.path}");

      // --- CLEANUP: Delete Old Files ---
      await _deleteOldBackups(backupDir, retentionDays);

    } catch (e) {
      print("Auto Backup Failed: $e");
    }
  }

  // Helper to delete files older than X days
  Future<void> _deleteOldBackups(Directory dir, int daysToKeep) async {
    try {
      final List<FileSystemEntity> files = dir.listSync();
      final now = DateTime.now();

      for (var entity in files) {
        if (entity is File) {
          final filename = entity.uri.pathSegments.last;
          // Check format: AutoBackup_yyyy-MM-dd.json
          if (filename.startsWith('AutoBackup_') && filename.endsWith('.json')) {
            try {
              // Extract date part: "AutoBackup_2023-10-25.json" -> "2023-10-25"
              String datePart = filename.replaceFirst('AutoBackup_', '').replaceFirst('.json', '');
              DateTime fileDate = DateFormat('yyyy-MM-dd').parse(datePart);

              // Calculate difference
              int difference = now.difference(fileDate).inDays;

              if (difference > daysToKeep) {
                print("Deleting old backup: $filename ($difference days old)");
                await entity.delete();
              }
            } catch (e) {
              // Ignore files that don't match date format perfectly
            }
          }
        }
      }
    } catch (e) {
      print("Cleanup Error: $e");
    }
  }

  // --- 3. RESTORE ---
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

      await db.transaction(() async {
        await db.delete(db.transactions).go();
        await db.delete(db.parties).go();

        for (var p in data['parties']) {
          await db.into(db.parties).insert(PartiesCompanion.insert(
            id: Value(p['id']),
            name: p['name'],
            mobile: p['mobile'],
            type: p['type'],
            initialBalance: Value(p['initialBalance']),
          ));
        }

        for (var t in data['transactions']) {
          await db.into(db.transactions).insert(TransactionsCompanion.insert(
            amount: t['amount'],
            txnType: t['txnType'],
            date: DateTime.parse(t['date']),
            details: Value(t['details']),
            partyId: Value(t['partyId']),
          ));
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
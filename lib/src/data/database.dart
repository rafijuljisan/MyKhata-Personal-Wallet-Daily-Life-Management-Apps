import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(tables: [Wallets, Parties, Transactions, BikeLogs, ShoppingItems, Categories, Budgets, RecurringTransactions, SavingGoals]) 
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 8; // Bumped to 8

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        await into(wallets).insert(WalletsCompanion.insert(
          name: 'My Wallet',
          type: const Value('Personal'),
          isDefault: const Value(true),
        ));
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // ... Previous migrations ...
        if (from < 7) {
          await m.createTable(categories);
          await m.createTable(budgets);
          await m.createTable(recurringTransactions);
          await m.createTable(savingGoals);
          try {
            await m.addColumn(transactions, transactions.categoryId);
          } catch (e) {
             // ignore if exists
          }
        }
        if (from < 8) {
          // Version 8: Add Frequency to RecurringTransactions
          await m.addColumn(recurringTransactions, recurringTransactions.frequency);
        }
      },
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'my_khata.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}

@riverpod
AppDatabase database(Ref ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
}
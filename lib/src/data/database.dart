import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(tables: [Wallets, Parties, Transactions, BikeLogs, ShoppingItems]) // Added ShoppingItems
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 6; // Bumped to 6

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
        if (from < 3) {
          await m.createTable(wallets);
          await m.addColumn(transactions, transactions.walletId);
          await into(wallets).insert(WalletsCompanion.insert(
            name: 'My Wallet',
            type: const Value('Personal'),
            isDefault: const Value(true),
          ));
        }
        if (from < 4) {
           await m.createTable(bikeLogs); 
        }
        if (from < 5) {
           await m.addColumn(bikeLogs, bikeLogs.nextDueKm);
           await m.addColumn(bikeLogs, bikeLogs.nextDueDate);
        }
        if (from < 6) {
           // Version 6: Bazar List Migration
           await m.createTable(shoppingItems);
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
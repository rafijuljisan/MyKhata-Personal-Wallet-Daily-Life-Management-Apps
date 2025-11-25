import 'package:drift/drift.dart';

// Table 1: Wallets
class Wallets extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  TextColumn get type => text().withDefault(const Constant('Personal'))();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
}

// Table 2: Parties
class Parties extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  TextColumn get mobile => text().withLength(min: 11, max: 14).unique()();
  TextColumn get type => text()(); 
  RealColumn get initialBalance => real().withDefault(const Constant(0.0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// Table 3: Transactions
class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  RealColumn get amount => real()();
  TextColumn get txnType => text()(); 
  TextColumn get category => text().nullable()(); 
  IntColumn get walletId => integer().nullable().references(Wallets, #id)();
  IntColumn get partyId => integer().nullable().references(Parties, #id)(); 
  DateTimeColumn get date => dateTime()();
  TextColumn get details => text().nullable()();
}

// Table 4: Bike Logs
class BikeLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get logType => text()(); 
  RealColumn get odometer => real()(); 
  RealColumn get cost => real()(); 
  RealColumn get quantity => real().nullable()(); 
  TextColumn get note => text().nullable()(); 
  DateTimeColumn get date => dateTime()();
  RealColumn get nextDueKm => real().nullable()(); 
  DateTimeColumn get nextDueDate => dateTime().nullable()(); 
}

// NEW: Table 5: Shopping List (Bazar List)
class ShoppingItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get itemName => text()();
  BoolColumn get isChecked => boolean().withDefault(const Constant(false))(); // Bought or not
  RealColumn get estimatedCost => real().withDefault(const Constant(0.0))(); // Price entered by user
}
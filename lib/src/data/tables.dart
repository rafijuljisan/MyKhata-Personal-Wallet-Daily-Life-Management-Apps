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
  IntColumn get categoryId => integer().nullable().references(Categories, #id)(); 
  IntColumn get walletId => integer().nullable().references(Wallets, #id)();
  IntColumn get partyId => integer().nullable().references(Parties, #id)(); 
  IntColumn get splitParentId => integer().nullable().references(Transactions, #id)(); 
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

// Table 5: Shopping List
class ShoppingItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get itemName => text()();
  BoolColumn get isChecked => boolean().withDefault(const Constant(false))(); 
  RealColumn get estimatedCost => real().withDefault(const Constant(0.0))(); 
}

// Table 6: Custom Categories
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  TextColumn get type => text()(); 
  BoolColumn get isSystem => boolean().withDefault(const Constant(false))(); 
}

// Table 7: Monthly Budgeting
class Budgets extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get categoryId => integer().references(Categories, #id)();
  RealColumn get limitAmount => real()(); 
  IntColumn get month => integer()();     
  IntColumn get year => integer()();      
}

// Table 8: Recurring Transactions (UPDATED)
class RecurringTransactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  RealColumn get amount => real()();      
  TextColumn get type => text()(); 
  IntColumn get categoryId => integer().references(Categories, #id)();
  
  // NEW: Frequency Column (Daily, Weekly, Monthly, Yearly)
  TextColumn get frequency => text().withDefault(const Constant('MONTHLY'))();
  
  IntColumn get dayOfMonth => integer()(); 
  DateTimeColumn get lastPaidDate => dateTime().nullable()();
  DateTimeColumn get nextDueDate => dateTime()(); 
}

// Table 9: Saving Goals
class SavingGoals extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  RealColumn get targetAmount => real()(); 
  RealColumn get currentAmount => real().withDefault(const Constant(0.0))();
  DateTimeColumn get targetDate => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
// Table 10: Blood Donation History
class BloodDonations extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get donateDate => dateTime()();
  TextColumn get location => text().nullable()(); // Hospital or Place
  TextColumn get patientName => text().nullable()(); // Who you donated to
  TextColumn get note => text().nullable()();
}
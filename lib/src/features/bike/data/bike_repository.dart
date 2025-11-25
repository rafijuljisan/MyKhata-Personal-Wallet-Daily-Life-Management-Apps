import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../data/database.dart';
import '../../../data/tables.dart';

part 'bike_repository.g.dart';

@riverpod
class BikeRepository extends _$BikeRepository {
  @override
  void build() {}

  Future<void> addLog({
    required String type,
    required double odometer,
    required double cost,
    double? quantity,
    String? note,
    required DateTime date,
    // Optional Reminders
    double? nextDueKm,
    DateTime? nextDueDate,
  }) async {
    final db = ref.read(databaseProvider);
    await db.into(db.bikeLogs).insert(BikeLogsCompanion.insert(
      logType: type,
      odometer: odometer,
      cost: cost,
      quantity: Value(quantity),
      note: Value(note),
      date: date,
      nextDueKm: Value(nextDueKm), // Save Target KM
      nextDueDate: Value(nextDueDate), // Save Target Date
    ));
  }
  
  Future<void> deleteLog(int id) async {
    final db = ref.read(databaseProvider);
    await (db.delete(db.bikeLogs)..where((t) => t.id.equals(id))).go();
  }
}

// --- PROVIDERS ---

final bikeLogsProvider = StreamProvider<List<BikeLog>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.bikeLogs)
        ..orderBy([(t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc)]))
      .watch();
});

// Smart Stats Provider (Returns Mileage + Nearest Reminder)
final bikeStatsProvider = StreamProvider<Map<String, dynamic>>((ref) {
  final db = ref.watch(databaseProvider);
  
  return (db.select(db.bikeLogs)..orderBy([(t) => OrderingTerm(expression: t.odometer, mode: OrderingMode.asc)]))
      .watch()
      .map((logs) {
        if (logs.isEmpty) {
          return {
            'mileage': 0.0, 'current_km': 0.0, 
            'next_task': 'No Data', 'remaining_km': 0.0, 'is_due': false
          };
        }

        double totalKm = 0;
        double totalFuel = 0;
        double currentKm = logs.last.odometer;

        // 1. Calculate Mileage
        final fuelLogs = logs.where((l) => l.logType == 'FUEL').toList();
        if (fuelLogs.length >= 2) {
           totalKm = fuelLogs.last.odometer - fuelLogs.first.odometer;
           for(int i=0; i<fuelLogs.length-1; i++) {
             totalFuel += (fuelLogs[i].quantity ?? 0);
           }
        }
        double mileage = totalFuel > 0 ? totalKm / totalFuel : 0.0;

        // 2. Find the NEAREST Upcoming Maintenance (Oil OR Parts)
        // We look at all logs that have a 'nextDue' set.
        String nextTaskName = "All Good";
        double minRemainingKm = 999999;
        bool isDue = false;

        for (var log in logs) {
          double remainingForThisLog = 999999;
          bool thisLogIsDue = false;

          // Check KM Limit
          if (log.nextDueKm != null) {
            remainingForThisLog = log.nextDueKm! - currentKm;
            if (remainingForThisLog <= 0) thisLogIsDue = true;
          }

          // Check Date Limit (Convert Time to approx KM for comparison sorting)
          // This is tricky, so we prioritize "Overdue" items first.
          if (log.nextDueDate != null) {
             final daysLeft = log.nextDueDate!.difference(DateTime.now()).inDays;
             if (daysLeft <= 0) {
               thisLogIsDue = true;
               remainingForThisLog = 0; // Immediate priority
             }
          }

          // If this log is closer/more urgent than previous best, pick it
          // Logic: We want the smallest positive remaining, OR any negative (overdue)
          if (log.nextDueKm != null || log.nextDueDate != null) {
             // If we found a closer task (or this one is overdue and previous wasn't)
             if (remainingForThisLog < minRemainingKm) {
               minRemainingKm = remainingForThisLog;
               nextTaskName = log.note ?? (log.logType == 'SERVICE' ? 'Oil Change' : 'Part Change');
               isDue = thisLogIsDue;
             }
          }
        }

        return {
          'mileage': mileage,
          'current_km': currentKm,
          'next_task': nextTaskName,
          'remaining_km': minRemainingKm == 999999 ? 0.0 : minRemainingKm,
          'is_due': isDue,
        };
      });
});
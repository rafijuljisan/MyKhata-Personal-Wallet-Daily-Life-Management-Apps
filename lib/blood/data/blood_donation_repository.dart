import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:my_khata/src/data/database.dart';

part 'blood_donation_repository.g.dart';

// Simple data class
class BloodStats {
  final int totalDonations;
  final DateTime? lastDonation;
  final DateTime? nextEligibleDate;
  final int daysRemaining;
  final double progress;
  final bool isEligible;

  const BloodStats({
    required this.totalDonations,
    this.lastDonation,
    this.nextEligibleDate,
    required this.daysRemaining,
    required this.progress,
    required this.isEligible,
  });
}

@riverpod
class BloodRepository extends _$BloodRepository {
  @override
  void build() {}

  Future<void> addDonation(DateTime date, String location, String patient) async {
    final db = ref.read(databaseProvider);
    await db.into(db.bloodDonations).insert(BloodDonationsCompanion.insert(
      donateDate: date,
      location: Value(location),
      patientName: Value(patient),
    ));
  }

  Future<void> deleteDonation(int id) async {
    final db = ref.read(databaseProvider);
    await (db.delete(db.bloodDonations)..where((t) => t.id.equals(id))).go();
  }
}

// Stream Provider for Blood Donations List
final bloodDonationsListProvider = StreamProvider<List<BloodDonation>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.bloodDonations)
    ..orderBy([(t) => OrderingTerm(expression: t.donateDate, mode: OrderingMode.desc)]))
    .watch();
});

// Stream Provider for Blood Stats
final bloodStatsProvider = StreamProvider<BloodStats>((ref) {
  final db = ref.watch(databaseProvider);
  
  return (db.select(db.bloodDonations)
    ..orderBy([(t) => OrderingTerm(expression: t.donateDate, mode: OrderingMode.desc)]))
    .watch()
    .map((history) {
      if (history.isEmpty) {
        return const BloodStats(
          totalDonations: 0,
          daysRemaining: 0,
          progress: 0,
          isEligible: true,
        );
      }

      final lastDate = history.first.donateDate;
      final today = DateTime.now();
      
      final nextDate = lastDate.add(const Duration(days: 90));
      final difference = nextDate.difference(today).inDays;

      double progress = 1.0 - (difference / 90.0);
      if (progress < 0) progress = 0;
      if (progress > 1) progress = 1;

      return BloodStats(
        totalDonations: history.length,
        lastDonation: lastDate,
        nextEligibleDate: nextDate,
        daysRemaining: difference > 0 ? difference : 0,
        progress: progress,
        isEligible: difference <= 0,
      );
    });
});
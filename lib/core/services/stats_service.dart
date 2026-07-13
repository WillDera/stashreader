import 'database_service.dart';
import '../models/reading_stat.dart';

class StatsService {
  final DatabaseService _db;

  StatsService(this._db);

  Future<void> trackReading(int bookId, int seconds) async {
    await _db.upsertStatsForDate(
      DateTime.now(),
      readingTimeSeconds: seconds,
    );
  }

  Future<void> trackSnippet() async {
    await _db.upsertStatsForDate(
      DateTime.now(),
      snippetsCreated: 1,
    );
  }

  Future<void> trackCompletion(int bookId) async {
    await _db.upsertStatsForDate(
      DateTime.now(),
      booksCompleted: 1,
    );
  }

  Future<List<ReadingStat>> getStats(DateTime start, DateTime end) async {
    return await _db.getStatsRange(start, end);
  }

  Future<int> getTotalReadingTimeToday() async {
    final today = DateTime.now();
    final stat = await _db.getStatsForDate(today);
    return stat?.readingTimeSeconds ?? 0;
  }

  Future<int> getTotalReadingTimeThisWeek() async {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: now.weekday - 1));
    final List<ReadingStat> stats = await _db.getStatsRange(
      DateTime(start.year, start.month, start.day),
      DateTime(now.year, now.month, now.day, 23, 59, 59),
    );
    int total = 0;
    for (final s in stats) {
      total += s.readingTimeSeconds;
    }
    return total;
  }
}

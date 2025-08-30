import 'package:sqflite/sqflite.dart';
import '../models/speed_result.dart';
import 'app_database.dart';

class ResultRepository {
  ResultRepository._();
  static final ResultRepository instance = ResultRepository._();

  Database get _db => AppDatabase.instance.db;

  Future<SpeedResult> add(SpeedResult result) async {
    final id = await _db.insert(AppDatabase.tableResults, result.toMap());
    return result.copyWith(id: id);
    }

  Future<List<SpeedResult>> getAll({bool newestFirst = true}) async {
    final rows = await _db.query(
      AppDatabase.tableResults,
      // ISO8601 strings sort correctly lexicographically, so no need for datetime()
      orderBy: 'timestamp ${newestFirst ? 'DESC' : 'ASC'}',
    );
    return rows.map((e) => SpeedResult.fromMap(e)).toList();
  }

  Future<int> delete(int id) async {
    return _db.delete(AppDatabase.tableResults, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clear() async {
    await _db.delete(AppDatabase.tableResults);
  }
}

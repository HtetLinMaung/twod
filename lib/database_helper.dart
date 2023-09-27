import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:twod/bet.dart';

class DatabaseHelper {
  static const _databaseName = "BettingDatabase.db";
  static const _databaseVersion = 1;

  static const table = 'bets';

  static const columnId = 'id';
  static const columnLottery = 'lottery';
  static const columnAmount = 'amount';
  static const columnDateTime = 'dateTime';
  static const columnR = 'r';

  // Make this a singleton class.
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  // Only allow a single open connection to the database.
  static Database? _database;
  Future<Database> get database async => _database ??= await _initDatabase();

  // Open the database and create it if it doesn't exist.
  Future<Database> _initDatabase() async {
    var documentsDirectory = await getApplicationDocumentsDirectory();
    var path = join(documentsDirectory.path, _databaseName);
    return await openDatabase(path,
        version: _databaseVersion, onCreate: _onCreate);
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
          CREATE TABLE $table (
            $columnId INTEGER PRIMARY KEY,
            $columnLottery TEXT NOT NULL,
            $columnAmount REAL NOT NULL,
            $columnDateTime TEXT NOT NULL,
            $columnR INTEGER DEFAULT 0
          )
          ''');
  }

  // Insert a bet into the database.
  Future<int> insert(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert(table, row);
  }

  // Future<List<Bet>> queryAllRows() async {
  //   Database db = await instance.database;
  //   final List<Map<String, dynamic>> maps = await db.query(table);
  //   return List.generate(maps.length, (i) {
  //     return Bet(
  //       id: maps[i][columnId],
  //       lottery: maps[i][columnLottery],
  //       amount: maps[i][columnAmount],
  //       dateTime: maps[i][columnDateTime],
  //       r: maps[i][columnR] == 1,
  //     );
  //   });
  // }

  Future<List<Bet>> queryRows(DateTime fromDateTime, DateTime toDateTime,
      [String? search]) async {
    Database db = await instance.database;

    String whereString = "$columnDateTime BETWEEN ? AND ?";
    List<dynamic> whereArgs = [
      fromDateTime.toIso8601String(),
      toDateTime.toIso8601String()
    ];

    if (search != null && search.isNotEmpty) {
      whereString += " AND ($columnLottery LIKE ?)";
      whereArgs.addAll(['%$search%']);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      table,
      where: whereString,
      whereArgs: whereArgs,
      orderBy: "$columnDateTime DESC",
    );

    return List.generate(maps.length, (i) {
      return Bet(
        id: maps[i][columnId],
        lottery: maps[i][columnLottery],
        amount: maps[i][columnAmount],
        dateTime: maps[i][columnDateTime],
        r: maps[i][columnR] == 1,
      );
    });
  }

  // Update a bet in the database.
  Future<int> update(int id, Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.update(table, row, where: '$columnId = ?', whereArgs: [id]);
  }

  // Delete a bet from the database.
  Future<int> delete(int id) async {
    Database db = await instance.database;
    return await db.delete(table, where: '$columnId = ?', whereArgs: [id]);
  }

  Future<List<SummaryBet>> getSummary(
      DateTime fromDateTime, DateTime toDateTime,
      [String? search]) async {
    Database db = await instance.database;

    // Initialize the list of query parameters
    List<dynamic> queryParams = [
      fromDateTime.toIso8601String(),
      toDateTime.toIso8601String(),
    ];

    // Conditionally add search criteria to the query
    String searchCriteria = '';
    if (search != null && search.isNotEmpty) {
      searchCriteria = 'AND (lottery LIKE ?)';
      queryParams.addAll(['%$search%']);
    }

    final List<Map<String, dynamic>> result = await db.rawQuery(
      '''
      SELECT lottery, r, 
             COALESCE(SUM(CASE WHEN r = 0 THEN amount ELSE amount * 2 END), 0.0) AS total_amount,
             COUNT(*) AS lottery_count
      FROM bets
      WHERE dateTime BETWEEN ? AND ?
      $searchCriteria
      GROUP BY lottery, r
      ORDER BY total_amount DESC, lottery_count DESC
      ''',
      queryParams,
    );
    return List.generate(result.length, (i) {
      return SummaryBet(
        lottery: result[i]["lottery"],
        totalAmount: result[i]["total_amount"],
        lotteryCount: result[i]["lottery_count"],
        r: result[i]["r"] == 1,
      );
    });
  }

  Future<TotalBet> getTotalForList(DateTime fromDateTime, DateTime toDateTime,
      [String? search]) async {
    Database db = await instance.database;

    // Initialize the list of query parameters
    List<dynamic> queryParams = [
      fromDateTime.toIso8601String(),
      toDateTime.toIso8601String(),
    ];

    // Conditionally add search criteria to the query
    String searchCriteria = '';
    if (search != null && search.isNotEmpty) {
      searchCriteria = 'AND (lottery LIKE ?)';
      queryParams.addAll(['%$search%']);
    }

    final List<Map<String, dynamic>> result = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(CASE WHEN r = 0 THEN amount ELSE amount * 2 END), 0.0) AS total_amount, COUNT(*) AS lottery_count
      FROM bets
      WHERE dateTime BETWEEN ? AND ?
      $searchCriteria
      ''',
      queryParams,
    );
    if (result.isEmpty) {
      return TotalBet(
        totalAmount: 0,
        lotteryCount: 0,
      );
    }

    return TotalBet(
      totalAmount: result[0]["total_amount"],
      lotteryCount: result[0]["lottery_count"],
    );
  }

  Future<TotalBet> getTotalForSummary(
      DateTime fromDateTime, DateTime toDateTime,
      [String? search]) async {
    Database db = await instance.database;

    // Initialize the list of query parameters
    List<dynamic> queryParams = [
      fromDateTime.toIso8601String(),
      toDateTime.toIso8601String(),
    ];

    // Conditionally add search criteria to the query
    String searchCriteria = '';
    if (search != null && search.isNotEmpty) {
      searchCriteria = 'AND (lottery LIKE ?)';
      queryParams.addAll(['%$search%']);
    }

    final List<Map<String, dynamic>> result = await db.rawQuery(
      '''
     SELECT COALESCE(SUM(t.lottery_count), 0) AS lottery_count, COALESCE(SUM(t.total_amount), 0.0) AS total_amount FROM (SELECT lottery, r, 
             COALESCE(SUM(CASE WHEN r = 0 THEN amount ELSE amount * 2 END), 0.0) AS total_amount,
             COALESCE(COUNT(*), 0) AS lottery_count
      FROM bets
      WHERE dateTime BETWEEN ? AND ?
      $searchCriteria
      GROUP BY lottery, r) AS t
      ''',
      queryParams,
    );
    return TotalBet(
      totalAmount: result[0]["total_amount"],
      lotteryCount: result[0]["lottery_count"],
    );
  }
}

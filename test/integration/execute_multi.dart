part of integrationtests;

void runExecuteMultiTests(
    String user, String password, String db, int port, String host) {
  ConnectionPool pool;
  group('executeMulti', () {
    setUp(() async {
      pool = new ConnectionPool(
          user: user,
          password: password,
          db: db,
          port: port,
          host: host,
          max: 2);
      expect(pool, isNotNull);
      var result = await setup(
          pool,
          "stream",
          "create table stream (id integer, name text)",
          "insert into stream (id, name) values (1, 'A'), (2, 'B'), (3, 'C')");
      expect(result.affectedRows, equals(3),
          reason: 'incorrect number of rows affected');
    });

    test('select', () async {
      var query = await pool.prepare('select * from stream where id = ?');
      var values = await query.executeMulti([
        [1],
        [2],
        [3]
      ]);
      expect(values, hasLength(3));

      var resultList = await values[0].toList();
      expect(resultList[0][0], equals(1));
      expect(resultList[0][1].toString(), equals('A'));

      resultList = await values[1].toList();
      expect(resultList[0][0], equals(2));
      expect(resultList[0][1].toString(), equals('B'));

      resultList = await values[2].toList();
      expect(resultList[0][0], equals(3));
      expect(resultList[0][1].toString(), equals('C'));
    });

    test('issue 43', () async {
      var tran = await pool.startTransaction();
      var query = await tran.prepare("SELECT * FROM stream");
      var result = await query.execute();

      await result.first;

      // TODO: library code or test needs fixing
      //
      // The following sometimes tries to call 'processResponse' on null
      // in lib/src/results/connection.dart line 190.
      //
      // Or sometimes produces this error: "MySQL Client Error:
      // Connection #1 cannot process a request for Instance of
      // '_QueryStreamHandler' while a request is already in progress for
      // Instance of '_ExecuteQueryHandler'"

      await query.close();
      await tran.rollback();
    });

    tearDown(() {
      expect(pool, isNotNull);
      pool.closeConnectionsWhenNotInUse();
    });
  });
}

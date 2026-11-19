import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'models/laporan.dart';

class DatabaseHelper {
  DatabaseHelper._();
  static final instance = DatabaseHelper._();
  Database? _db;

  Future<Database> get db async => _db ??= await openDatabase(
    kIsWeb ? 'smart_city.db' : join(await getDatabasesPath(), 'smart_city.db'),
    version: 2,
    onCreate: (db, version) => db.execute('''
          CREATE TABLE laporan (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            judul TEXT NOT NULL,
            kategori TEXT NOT NULL,
            lokasi TEXT NOT NULL,
            urgensi INTEGER NOT NULL,
            tanggal TEXT NOT NULL,
            status TEXT NOT NULL DEFAULT 'Baru'
          )'''),
    onUpgrade: (db, oldVersion, newVersion) async {
      if (oldVersion < 2) {
        await db.execute(
          'ALTER TABLE laporan ADD COLUMN urgensi INTEGER NOT NULL DEFAULT 1',
        );
        await db.execute(
          "ALTER TABLE laporan ADD COLUMN status TEXT NOT NULL DEFAULT 'Baru'",
        );
      }
    },
  );

  Future<int> tambah(Laporan l) async =>
      (await db).insert('laporan', l.toMap());

  Future<List<Laporan>> ambil(String cari, String status) async {
    final where = ['(judul LIKE ? OR lokasi LIKE ?)'];
    final args = <Object>['%$cari%', '%$cari%'];
    if (status != 'Semua') {
      where.add('status = ?');
      args.add(status);
    }
    final rows = await (await db).query(
      'laporan',
      where: where.join(' AND '),
      whereArgs: args,
      orderBy: "status = 'Selesai', urgensi DESC, tanggal ASC",
    );
    return rows.map(Laporan.fromMap).toList();
  }

  Future<List<int>> statistik() async {
    final d = await db;
    final total = await d.rawQuery('SELECT COUNT(*) FROM laporan');
    final aktif = await d.rawQuery(
      'SELECT COUNT(*) FROM laporan WHERE status != ?',
      ['Selesai'],
    );
    final selesai = await d.rawQuery(
      'SELECT COUNT(*) FROM laporan WHERE status = ?',
      ['Selesai'],
    );
    return [
      total,
      aktif,
      selesai,
    ].map((r) => Sqflite.firstIntValue(r) ?? 0).toList();
  }

  Future<int> ubah(Laporan l) async => (await db).update(
    'laporan',
    l.toMap(),
    where: 'id = ?',
    whereArgs: [l.id],
  );

  Future<int> ubahStatus(int id, String status) async => (await db).update(
    'laporan',
    {'status': status},
    where: 'id = ?',
    whereArgs: [id],
  );

  Future<int> hapus(int id) async =>
      (await db).delete('laporan', where: 'id = ?', whereArgs: [id]);
}

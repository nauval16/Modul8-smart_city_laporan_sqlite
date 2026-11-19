import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import 'database_helper.dart';
import 'halaman_laporan.dart';
import 'models/laporan.dart';

void main() {
  if (kIsWeb) databaseFactory = databaseFactoryFfiWeb;
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.teal),
      home: const FormLaporan(),
    ),
  );
}

class FormLaporan extends StatefulWidget {
  const FormLaporan({super.key});

  @override
  State<FormLaporan> createState() => _FormLaporanState();
}

class _FormLaporanState extends State<FormLaporan> {
  final _form = GlobalKey<FormState>();
  final _judul = TextEditingController();
  final _lokasi = TextEditingController();
  final _tanggal = TextEditingController();
  String? _kategori;
  int? _urgensi;
  bool _loading = false;

  String? _wajib(Object? v) =>
      (v == null || v.toString().trim().isEmpty) ? 'Wajib diisi' : null;

  Future<void> _pilihTanggal() async {
    final t = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (t != null) _tanggal.text = t.toString().substring(0, 10);
  }

  Future<void> _kirim() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    final pesan = ScaffoldMessenger.of(context);
    try {
      await DatabaseHelper.instance.tambah(
        Laporan(
          judul: _judul.text.trim(),
          kategori: _kategori!,
          lokasi: _lokasi.text.trim(),
          urgensi: _urgensi!,
          tanggal: _tanggal.text,
        ),
      );
      _form.currentState?.reset();
      _judul.clear();
      _lokasi.clear();
      _tanggal.clear();
      _kategori = null;
      _urgensi = null;
      pesan.showSnackBar(const SnackBar(content: Text('Laporan terkirim')));
    } catch (e) {
      pesan.showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lapor Fasilitas Kota')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _judul,
              decoration: const InputDecoration(labelText: 'Judul Masalah'),
              validator: (v) => v!.trim().length < 5
                  ? 'Wajib diisi, minimal 5 karakter'
                  : null,
            ),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Kategori Fasilitas',
              ),
              items: kategoriList
                  .map((k) => DropdownMenuItem(value: k, child: Text(k)))
                  .toList(),
              onChanged: (v) => _kategori = v,
              validator: _wajib,
            ),
            TextFormField(
              controller: _lokasi,
              decoration: const InputDecoration(
                labelText: 'Lokasi / Kecamatan',
              ),
              validator: _wajib,
            ),
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(labelText: 'Tingkat Urgensi'),
              items: urgensiList.entries
                  .map(
                    (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
                  )
                  .toList(),
              onChanged: (v) => _urgensi = v,
              validator: _wajib,
            ),
            TextFormField(
              controller: _tanggal,
              readOnly: true,
              onTap: _pilihTanggal,
              decoration: const InputDecoration(
                labelText: 'Tanggal Kejadian',
                suffixIcon: Icon(Icons.calendar_month),
              ),
              validator: _wajib,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _loading ? null : _kirim,
              child: Text(_loading ? 'Menyimpan...' : 'Kirim Laporan'),
            ),
            OutlinedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HalamanLaporan()),
              ),
              child: const Text('Pantau Laporan Kota'),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import 'database_helper.dart';
import 'models/laporan.dart';

class HalamanLaporan extends StatefulWidget {
  const HalamanLaporan({super.key});

  @override
  State<HalamanLaporan> createState() => _HalamanLaporanState();
}

class _HalamanLaporanState extends State<HalamanLaporan> {
  final _db = DatabaseHelper.instance;
  List<Laporan> _data = [];
  List<int> _stat = [0, 0, 0];
  String _cari = '';
  String _filter = 'Semua';

  @override
  void initState() {
    super.initState();
    _muat();
  }

  Future<void> _muat() async {
    final data = await _db.ambil(_cari, _filter);
    final stat = await _db.statistik();
    if (mounted) {
      setState(() {
        _data = data;
        _stat = stat;
      });
    }
  }

  Future<void> _ubahStatus(Laporan l) async {
    await _db.ubahStatus(l.id!, l.status == 'Baru' ? 'Diproses' : 'Selesai');
    _muat();
  }

  Future<void> _hapus(Laporan l) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Hapus laporan?'),
        content: Text(l.judul),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _db.hapus(l.id!);
      _muat();
    }
  }

  Future<void> _edit(Laporan l) async {
    final form = GlobalKey<FormState>();
    final judul = TextEditingController(text: l.judul);
    final lokasi = TextEditingController(text: l.lokasi);
    final tanggal = TextEditingController(text: l.tanggal);
    var kategori = l.kategori;
    var urgensi = l.urgensi;

    final simpan = await showDialog<bool>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, setDialog) => AlertDialog(
          title: const Text('Edit Laporan'),
          content: Form(
            key: form,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: judul,
                    decoration: const InputDecoration(labelText: 'Judul'),
                    validator: (v) =>
                        v!.trim().length < 5 ? 'Minimal 5 karakter' : null,
                  ),
                  DropdownButton<String>(
                    value: kategori,
                    isExpanded: true,
                    items: kategoriList
                        .map((k) => DropdownMenuItem(value: k, child: Text(k)))
                        .toList(),
                    onChanged: (v) => setDialog(() => kategori = v!),
                  ),
                  TextFormField(
                    controller: lokasi,
                    decoration: const InputDecoration(labelText: 'Lokasi'),
                    validator: (v) => v!.trim().isEmpty ? 'Wajib diisi' : null,
                  ),
                  DropdownButton<int>(
                    value: urgensi,
                    isExpanded: true,
                    items: urgensiList.entries
                        .map(
                          (e) => DropdownMenuItem(
                            value: e.key,
                            child: Text(e.value),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setDialog(() => urgensi = v!),
                  ),
                  TextFormField(
                    controller: tanggal,
                    readOnly: true,
                    decoration: const InputDecoration(labelText: 'Tanggal'),
                    onTap: () async {
                      final t = await showDatePicker(
                        context: c,
                        initialDate: DateTime.parse(tanggal.text),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (t != null) {
                        tanggal.text = t.toString().substring(0, 10);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                if (form.currentState!.validate()) Navigator.pop(c, true);
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );

    if (simpan == true) {
      await _db.ubah(
        Laporan(
          id: l.id,
          judul: judul.text.trim(),
          kategori: kategori,
          lokasi: lokasi.text.trim(),
          urgensi: urgensi,
          tanggal: tanggal.text,
          status: l.status,
        ),
      );
      _muat();
    }
  }

  Widget _kartu(String label, int nilai, Color warna) => Expanded(
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              '$nilai',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: warna,
              ),
            ),
            Text(label),
          ],
        ),
      ),
    ),
  );

  Widget _item(Laporan l) {
    final selesai = l.status == 'Selesai';
    final darurat = l.urgensi == 3;
    return Card(
      color: selesai ? Colors.green.shade50 : null,
      shape: darurat
          ? RoundedRectangleBorder(
              side: const BorderSide(color: Colors.red, width: 2),
              borderRadius: BorderRadius.circular(12),
            )
          : null,
      child: ListTile(
        leading: Icon(
          selesai ? Icons.check_circle : Icons.report,
          color: selesai ? Colors.green : (darurat ? Colors.red : Colors.grey),
        ),
        title: Text(
          l.judul,
          style: TextStyle(
            decoration: selesai ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text(
          '${l.kategori} • ${l.lokasi} • ${l.tanggal}\n'
          '${urgensiList[l.urgensi]} • ${l.status}',
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!selesai)
              IconButton(
                icon: const Icon(Icons.arrow_forward),
                tooltip: 'Ubah status',
                onPressed: () => _ubahStatus(l),
              ),
            IconButton(icon: const Icon(Icons.edit), onPressed: () => _edit(l)),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _hapus(l),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pantau Laporan Kota')),
      body: Column(
        children: [
          Row(
            children: [
              _kartu('Total', _stat[0], Colors.indigo),
              _kartu('Aktif', _stat[1], Colors.orange),
              _kartu('Selesai', _stat[2], Colors.green),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Cari judul / lokasi',
              ),
              onChanged: (v) {
                _cari = v;
                _muat();
              },
            ),
          ),
          Wrap(
            spacing: 6,
            children: ['Semua', 'Baru', 'Diproses', 'Selesai']
                .map(
                  (s) => ChoiceChip(
                    label: Text(s),
                    selected: _filter == s,
                    onSelected: (_) {
                      _filter = s;
                      _muat();
                    },
                  ),
                )
                .toList(),
          ),
          Expanded(child: ListView(children: _data.map(_item).toList())),
        ],
      ),
    );
  }
}

const kategoriList = [
  'Penerangan',
  'Jalan',
  'Drainase',
  'Sampah',
  'Lalu Lintas',
];
const urgensiList = {1: 'Normal', 2: 'Mendesak', 3: 'Darurat'};

class Laporan {
  final int? id;
  final String judul, kategori, lokasi, tanggal, status;
  final int urgensi;

  Laporan({
    this.id,
    required this.judul,
    required this.kategori,
    required this.lokasi,
    required this.urgensi,
    required this.tanggal,
    this.status = 'Baru',
  });

  factory Laporan.fromMap(Map<String, Object?> m) => Laporan(
    id: m['id'] as int,
    judul: m['judul'] as String,
    kategori: m['kategori'] as String,
    lokasi: m['lokasi'] as String,
    urgensi: m['urgensi'] as int,
    tanggal: m['tanggal'] as String,
    status: m['status'] as String,
  );

  Map<String, Object?> toMap() => {
    'judul': judul,
    'kategori': kategori,
    'lokasi': lokasi,
    'urgensi': urgensi,
    'tanggal': tanggal,
    'status': status,
  };
}

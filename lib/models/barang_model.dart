class Barang {
  final int id;
  final String nama;
  final String kode; // NEW
  final int stok;
  final int idKategori;
  final String? foto;
  final Kategori kategori;

  Barang({
    required this.id,
    required this.nama,
    required this.kode, // NEW
    required this.stok,
    required this.idKategori,
    this.foto,
    required this.kategori,
  });

  factory Barang.fromJson(Map<String, dynamic> json) {
    return Barang(
      id: json['id'],
      nama: json['nama'] ?? '',
      kode: json['kode'] ?? '', // NEW
      stok: json['stok'] ?? 0,
      idKategori: json['id_kategori'] ?? 0,
      foto: json['foto'],
      kategori: Kategori.fromJson(json['kategori'] ?? {}),
    );
  }
}

class Kategori {
  final int id;
  final String namaKategori;

  Kategori({
    required this.id,
    required this.namaKategori,
  });

  factory Kategori.fromJson(Map<String, dynamic> json) {
    return Kategori(
      id: json['id'] ?? 0,
      namaKategori: json['nama_kategori'] ?? '',
    );
  }
}

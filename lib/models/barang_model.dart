class Barang {
  final int id;
  final String nama;
  final int stok;
  final int idKategori;
  final String? foto;
  final Kategori kategori;

  Barang({
    required this.id,
    required this.nama,
    required this.stok,
    required this.idKategori,
    required this.foto,
    required this.kategori,
  });

  factory Barang.fromJson(Map<String, dynamic> json) {
    return Barang(
      id: json['id'],
      nama: json['nama'] ?? '',
      stok: json['stok'] ?? 0,
      idKategori: json['id_kategori'] ?? 0, // ✅ disesuaikan
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

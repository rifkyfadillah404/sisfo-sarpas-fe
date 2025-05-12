class Pengembalian {
  final String namaPengembali;
  final int peminjamanId;
  final String tanggalKembali;
  final int jumlahDikembalikan;
  final String kondisi;
  final int denda;
  final String status;

  Pengembalian({
    required this.namaPengembali,
    required this.peminjamanId,
    required this.tanggalKembali,
    required this.jumlahDikembalikan,
    required this.kondisi,
    required this.denda,
    required this.status,
  });

  Map<String, dynamic> toJson() {
    return {
      'nama_pengembali': namaPengembali,
      'peminjaman_id': peminjamanId,
      'tanggal_kembali': tanggalKembali,
      'jumlah_dikembalikan': jumlahDikembalikan,
      'kondisi': kondisi,
      'denda': denda,
      'status': status,
    };
  }
}

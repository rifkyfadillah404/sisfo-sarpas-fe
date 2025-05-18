import 'barang_model.dart';

class Peminjaman {
  final int id;
  final int userId;
  final String namaPeminjam;
  final int barangId;
  final String alasanMeminjam;
  final int jumlah;
  final String tanggalPinjam;
  final String tanggalKembali;
  final String status;
  final Barang? barang; // <-- buat nullable

  Peminjaman({
    required this.id,
    required this.userId,
    required this.namaPeminjam,
    required this.barangId,
    required this.alasanMeminjam,
    required this.jumlah,
    required this.tanggalPinjam,
    required this.tanggalKembali,
    required this.status,
    this.barang, // <-- tidak required
  });

  factory Peminjaman.fromJson(Map<String, dynamic> json) {
    return Peminjaman(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      namaPeminjam: json['nama_peminjam'] ?? '',
      barangId: json['barang_id'] ?? 0,
      alasanMeminjam: json['alasan_meminjam'] ?? '',
      jumlah: json['jumlah'] ?? 0,
      tanggalPinjam: json['tanggal_pinjam'] ?? '',
      tanggalKembali: json['tanggal_kembali'] ?? '',
      status: json['status'] ?? '',
      barang: json['barang'] != null ? Barang.fromJson(json['barang']) : null,
    );
  }
}

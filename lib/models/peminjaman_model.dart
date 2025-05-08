import 'barang_model.dart';

class Peminjaman {
  final int id;
  final int userId;
  final String namaPeminjam;
  final int barangId;
  final String alasanMeminjam;
  final int jumlah;
  final String tanggalPinjam;
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
    required this.status,
    this.barang, // <-- tidak required
  });

  factory Peminjaman.fromJson(Map<String, dynamic> json) {
    return Peminjaman(
      id: json['id'],
      userId: json['user_id'],
      namaPeminjam: json['nama_peminjam'],
      barangId: json['barang_id'],
      alasanMeminjam: json['alasan_meminjam'],
      jumlah: json['jumlah'],
      tanggalPinjam: json['tanggal_pinjam'],
      status: json['status'],
      barang: json['barang'] != null ? Barang.fromJson(json['barang']) : null,
    );
  }
}

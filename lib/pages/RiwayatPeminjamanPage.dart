import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sisfo_fe/models/peminjaman_model.dart';
import 'package:sisfo_fe/service/peminjaman_service.dart';

class RiwayatPeminjamanPage extends StatefulWidget {
  final String token;

  const RiwayatPeminjamanPage({Key? key, required this.token}) : super(key: key);

  @override
  State<RiwayatPeminjamanPage> createState() => _RiwayatPeminjamanPageState();
}

class _RiwayatPeminjamanPageState extends State<RiwayatPeminjamanPage> {
  List<Peminjaman> _peminjamanList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPeminjaman();
  }

  void _fetchPeminjaman() async {
    try {
      final list = await PeminjamanService.fetchPeminjamanUser(widget.token);
      setState(() {
        _peminjamanList = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat data: $e')),
      );
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'returned':
        return Colors.blue;  // Blue for returned status
      default:
        return Colors.orange;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'returned':
        return Icons.loop;  // Loop icon for returned
      default:
        return Icons.hourglass_empty;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F9FC),
      appBar: AppBar(
        title: Text(
          "Riwayat Peminjaman",
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _peminjamanList.isEmpty
              ? Center(
                  child: Text(
                    "Belum ada peminjaman.",
                    style: GoogleFonts.poppins(fontSize: 16),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _peminjamanList.length,
                  itemBuilder: (context, index) {
                    final item = _peminjamanList[index];
                    return Card(
                      elevation: 6,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Text(
                          item.barang?.nama ?? 'Barang tidak tersedia',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Tanggal Pinjam: ${item.tanggalPinjam}",
                                style: GoogleFonts.poppins(fontSize: 13),
                              ),
                              Text(
                                "Jumlah: ${item.jumlah}",
                                style: GoogleFonts.poppins(fontSize: 13),
                              ),
                              Text(
                                "Status: ${item.status.toUpperCase()}",
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: _statusColor(item.status),
                                ),
                              ),
                            ],
                          ),
                        ),
                        trailing: Icon(
                          _statusIcon(item.status),
                          color: _statusColor(item.status),
                          size: 30,
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

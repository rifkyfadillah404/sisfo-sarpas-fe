import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sisfo_fe/models/barang_model.dart';
import 'package:sisfo_fe/service/barang_service.dart';

class BarangPage extends StatefulWidget {
  final String token;
  const BarangPage({Key? key, required this.token}) : super(key: key);

  @override
  State<BarangPage> createState() => _BarangPageState();
}

class _BarangPageState extends State<BarangPage> {
  late Future<List<Barang>> _barangList;

  @override
  void initState() {
    super.initState();
    _barangList = BarangService().fetchBarang(widget.token);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F9FC),
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        title: Text(
          "Daftar Barang",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: FutureBuilder<List<Barang>>(
        future: _barangList,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Gagal memuat barang: ${snapshot.error}",
                style: GoogleFonts.poppins(color: Colors.red),
              ),
            );
          }

          final barangList = snapshot.data!;
          if (barangList.isEmpty) {
            return Center(
              child: Text(
                "Belum ada barang.",
                style: GoogleFonts.poppins(fontSize: 16),
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.70,
            ),
            itemCount: barangList.length,
            itemBuilder: (context, index) {
              final barang = barangList[index];
              return Container(
                decoration: BoxDecoration(  
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        child: barang.foto != null && barang.foto!.isNotEmpty
                            ? Image.network(
                                'http://127.0.0.1:8000${barang.foto}',// Menggunakan foto langsung dari API
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Center(
                                  child: Icon(Icons.broken_image, size: 40),
                                ),
                              )
                            : const Center(
                                child: Icon(Icons.inventory_2_rounded, size: 60),
                              ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                      child: Text(
                        barang.nama,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        "Kategori: ${barang.kategori.namaKategori}",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[700]),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                      child: Text(
                        "Stok: ${barang.stok}",
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.blueAccent,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

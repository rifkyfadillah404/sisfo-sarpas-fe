import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sisfo_fe/models/barang_model.dart';
import 'package:sisfo_fe/pages/peminjaman_page.dart';

class BarangDetailPage extends StatelessWidget {
  final Barang barang;
  final String token;

  const BarangDetailPage({
    Key? key,
    required this.barang,
    required this.token,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF4776E6), Colors.white],
            stops: [0.0, 0.3],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom App Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        "Detail Barang",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        onPressed: () {
                          // TODO: Implement share function
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Berbagi info barang'),
                              backgroundColor: Colors.black87,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              margin: const EdgeInsets.all(12),
                            ),
                          );
                        },
                        icon: const Icon(Icons.share_outlined, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Content
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      // Image and Basic Info - Top Card
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Image with category badge
                            Stack(
                              children: [
                                // Image
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(24),
                                  ),
                                  child: barang.foto != null && barang.foto!.isNotEmpty
                                      ? Image.network(
                                          barang.foto!,
                                          width: double.infinity,
                                          height: 250,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Container(
                                            height: 250,
                                            width: double.infinity,
                                            color: Colors.grey[200],
                                            child: Center(
                                              child: Icon(
                                                Icons.broken_image_rounded,
                                                size: 60,
                                                color: Colors.grey[400],
                                              ),
                                            ),
                                          ),
                                        )
                                      : Container(
                                          height: 250,
                                          width: double.infinity,
                                          color: Colors.grey[100],
                                          child: Center(
                                            child: Icon(
                                              Icons.inventory_2_rounded,
                                              size: 80,
                                              color: Colors.grey[400],
                                            ),
                                          ),
                                        ),
                                ),
                                
                                // Category Badge
                                Positioned(
                                  top: 16,
                                  left: 16,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF4776E6), Color(0xFF8E54E9)],
                                      ),
                                      borderRadius: BorderRadius.circular(30),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      barang.kategori.namaKategori,
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                                
                                // Stock Badge
                                Positioned(
                                  top: 16,
                                  right: 16,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: barang.stok > 0 ? Colors.green : Colors.redAccent,
                                      borderRadius: BorderRadius.circular(30),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          barang.stok > 0 ? Icons.check_circle : Icons.cancel,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          barang.stok > 0 ? "Tersedia" : "Habis",
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            
                            // Name and Basics
                            Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    barang.nama,
                                    style: GoogleFonts.poppins(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF4776E6),
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 16),
                                  
                                  _buildInfoRow(
                                    icon: Icons.qr_code_rounded,
                                    label: "Kode Barang",
                                    value: barang.kode,
                                    iconColor: const Color(0xFF8E54E9),
                                  ),
                                  
                                  const SizedBox(height: 8),
                                  
                                  _buildInfoRow(
                                    icon: Icons.category_rounded,
                                    label: "Kategori",
                                    value: barang.kategori.namaKategori,
                                    iconColor: const Color(0xFF8E54E9),
                                  ),
                                  
                                  const SizedBox(height: 8),
                                  
                                  _buildInfoRow(
                                    icon: Icons.inventory_2_rounded,
                                    label: "Stok Tersedia",
                                    value: barang.stok.toString(),
                                    valueColor: barang.stok > 0 ? Colors.green : Colors.redAccent,
                                    iconColor: const Color(0xFF8E54E9),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Description Card
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            
                            Text(
                              "Panduan Peminjaman",
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF4776E6),
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildGuidelineItem(
                              index: 1,
                              text: "Pastikan Anda memiliki ID pengguna yang valid",
                            ),
                            _buildGuidelineItem(
                              index: 2,
                              text: "Isi formulir peminjaman dengan lengkap",
                            ),
                            _buildGuidelineItem(
                              index: 3,
                              text: "Tunggu persetujuan dari admin",
                            ),
                            _buildGuidelineItem(
                              index: 4,
                              text: "Ambil barang pada tanggal yang ditentukan",
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 100), // Space for the bottom fixed button
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      
      // Fixed Borrow Button at Bottom
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xFF4776E6), Color(0xFF8E54E9)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8E54E9).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: barang.stok <= 0 
              ? null 
              : () {
                  try {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PeminjamanPage(
                          token: token,
                          barangDipilih: barang,
                        ),
                      ),
                    );
                  } catch (e) {
                    // Tangani error yang mungkin terjadi saat navigasi
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Terjadi kesalahan: $e'),
                        backgroundColor: Colors.redAccent,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        margin: const EdgeInsets.all(12),
                      ),
                    );
                  }
                },
          icon: const Icon(Icons.shopping_cart_outlined),
          label: Text(
            barang.stok <= 0 ? 'STOK HABIS' : 'PINJAM SEKARANG',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.transparent,
            disabledForegroundColor: Colors.white.withOpacity(0.6),
            disabledBackgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    required Color iconColor,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: iconColor),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: valueColor ?? Colors.black87,
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildGuidelineItem({required int index, required String text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            margin: const EdgeInsets.only(right: 12, top: 2),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4776E6), Color(0xFF8E54E9)],
              ),
              shape: BoxShape.circle,
            ),
            child: Text(
              index.toString(),
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

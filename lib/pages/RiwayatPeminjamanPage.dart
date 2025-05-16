import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sisfo_fe/models/peminjaman_model.dart';
import 'package:sisfo_fe/service/peminjaman_service.dart';
import 'package:sisfo_fe/pages/pengembalian_page.dart';
import 'package:intl/intl.dart';

class RiwayatPeminjamanPage extends StatefulWidget {
  final String token;

  const RiwayatPeminjamanPage({Key? key, required this.token}) : super(key: key);

  @override
  State<RiwayatPeminjamanPage> createState() => _RiwayatPeminjamanPageState();
}

class _RiwayatPeminjamanPageState extends State<RiwayatPeminjamanPage> {
  List<Peminjaman> _peminjamanList = [];
  bool _isLoading = true;
  String _filterStatus = 'all';

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
        SnackBar(
          content: Text('Gagal memuat data: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(12),
        ),
      );
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMMM yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'approved':
        return 'Disetujui';
      case 'rejected':
        return 'Ditolak';
      case 'returned':
        return 'Dikembalikan';
      case 'pending':
        return 'Menunggu';
      default:
        return status.toUpperCase();
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'returned':
        return const Color(0xFF4776E6);
      default:
        return Colors.orange;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'approved':
        return Icons.check_circle_outline_rounded;
      case 'rejected':
        return Icons.cancel_outlined;
      case 'returned':
        return Icons.assignment_return_outlined;
      default:
        return Icons.hourglass_empty_rounded;
    }
  }

  List<Peminjaman> get _filteredList {
    if (_filterStatus == 'all') {
      return _peminjamanList;
    }
    return _peminjamanList.where((item) => item.status == _filterStatus).toList();
  }
  
  // Method untuk menampilkan hanya barang yang dikembalikan
  void _showReturnedItems() {
    setState(() {
      _filterStatus = 'returned';
    });
    
    // Tampilkan konfirmasi
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Menampilkan barang yang sudah dikembalikan'),
        backgroundColor: const Color(0xFF4776E6),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            // Filter chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('all', 'Semua'),
                    const SizedBox(width: 8),
                    _buildFilterChip('pending', 'Menunggu'),
                    const SizedBox(width: 8),
                    _buildFilterChip('approved', 'Disetujui'),
                    const SizedBox(width: 8),
                    _buildFilterChip('rejected', 'Ditolak'),
                    const SizedBox(width: 8),
                    _buildFilterChip('returned', 'Dikembalikan'),
                  ],
                ),
              ),
            ),

            // Tombol Lihat Dikembalikan
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [Color(0xFF4776E6), Color(0xFF8E54E9)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8E54E9).withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
            ),

            // Status counter
            if (!_isLoading) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _filterStatus == 'all' 
                            ? 'Ringkasan Peminjaman' 
                            : 'Peminjaman ${_getStatusText(_filterStatus)}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF4776E6),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildStatusCounter(
                            'Menunggu',
                            _peminjamanList.where((p) => p.status == 'pending').length.toString(),
                            Colors.orange,
                          ),
                          _buildStatusCounter(
                            'Disetujui',
                            _peminjamanList.where((p) => p.status == 'approved').length.toString(),
                            Colors.green,
                          ),
                          _buildStatusCounter(
                            'Ditolak',
                            _peminjamanList.where((p) => p.status == 'rejected').length.toString(),
                            Colors.red,
                          ),
                          _buildStatusCounter(
                            'Kembali',
                            _peminjamanList.where((p) => p.status == 'returned').length.toString(),
                            const Color(0xFF4776E6),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8E54E9)),
                      ),
                    )
                  : _filteredList.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredList.length,
                          itemBuilder: (context, index) {
                            final item = _filteredList[index];
                            return _buildPeminjamanCard(item);
                          },
                        ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _filterStatus == value;
    
    return FilterChip(
      selected: isSelected,
      label: Text(label),
      labelStyle: GoogleFonts.poppins(
        color: isSelected ? Colors.white : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        fontSize: 12,
      ),
      backgroundColor: Colors.white,
      selectedColor: const Color(0xFF8E54E9),
      checkmarkColor: Colors.white,
      shadowColor: Colors.black26,
      elevation: 2,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
        side: BorderSide(
          color: isSelected ? Colors.transparent : Colors.grey.shade300,
        ),
      ),
      onSelected: (selected) {
        setState(() {
          _filterStatus = value;
        });
      },
    );
  }

  Widget _buildStatusCounter(String label, String count, Color color) {
    return Column(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              count,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.history_rounded,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            _filterStatus == 'all'
                ? "Belum ada riwayat peminjaman"
                : "Tidak ada peminjaman ${_getStatusText(_filterStatus).toLowerCase()}",
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Silakan lakukan peminjaman terlebih dahulu",
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPeminjamanCard(Peminjaman item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _statusColor(item.status).withOpacity(0.7),
                  _statusColor(item.status).withOpacity(0.9),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _statusIcon(item.status),
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  _getStatusText(item.status),
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDate(item.tanggalPinjam),
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Barang image or placeholder
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.inventory_2_outlined,
                          color: Color(0xFF8E54E9),
                          size: 30,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.barang?.nama ?? 'Barang tidak tersedia',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              "Jumlah: ${item.jumlah}",
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Additional info with icons
                Column(
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.person_outline_rounded,
                          size: 18,
                          color: Color(0xFF8E54E9),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Peminjam: ${item.namaPeminjam}",
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.event_note_outlined,
                          size: 18,
                          color: Color(0xFF8E54E9),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Alasan: ${item.alasanMeminjam}",
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    
                    // Tombol Pengembalian untuk peminjaman yang disetujui
                    if (item.status == 'approved') ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [Color(0xFF4776E6), Color(0xFF8E54E9)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF8E54E9).withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () => _navigateToPengembalian(item),
                          icon: const Icon(Icons.assignment_return_outlined),
                          label: Text(
                            'KEMBALIKAN BARANG',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // Method untuk navigasi ke halaman pengembalian dengan peminjaman yang dipilih
  void _navigateToPengembalian(Peminjaman selectedPeminjaman) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PengembalianPage(
          token: widget.token,
          selectedPeminjaman: selectedPeminjaman,
        ),
      ),
    );
  }
}

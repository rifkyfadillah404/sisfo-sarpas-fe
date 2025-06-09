import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sisfo_fe/models/pengembalian_model.dart';
import 'package:sisfo_fe/models/peminjaman_model.dart';
import 'package:sisfo_fe/service/pengembalian_service.dart';
import 'package:intl/intl.dart';

class PengembalianPage extends StatefulWidget {
  final String token;
  final Peminjaman? selectedPeminjaman;

  const PengembalianPage({
    super.key,
    required this.token,
    this.selectedPeminjaman,
  });

  @override
  State<PengembalianPage> createState() => _PengembalianPageState();
}

class _PengembalianPageState extends State<PengembalianPage> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _jumlahController = TextEditingController();
  final _kondisiController = TextEditingController();
  final _tanggalController = TextEditingController();

  final _pengembalianService = PengembalianService();

  DateTime? _tanggalKembali;
  Peminjaman? _selectedPeminjaman;
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadPeminjamanUser();
  }

  // Function to initialize the selected peminjaman
  Future<void> _loadPeminjamanUser() async {
    setState(() => _isLoading = true);
    try {
      // If a specific peminjaman is passed, use it directly
      if (widget.selectedPeminjaman != null) {
        setState(() {
          _selectedPeminjaman = widget.selectedPeminjaman;
          _isLoading = false;

          // Fill form with selected peminjaman data
          _namaController.text = _selectedPeminjaman!.namaPeminjam;
          _jumlahController.text = _selectedPeminjaman!.jumlah.toString();
          // Set today's date as default return date
          final now = DateTime.now();
          _tanggalKembali = now;
          final formatter = DateFormat('yyyy-MM-dd');
          _tanggalController.text = formatter.format(now);
        });
      } else {
        // If no specific peminjaman is passed, show error
        setState(() {
          _isLoading = false;
          _selectedPeminjaman = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Tidak ada peminjaman yang dipilih'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(12),
          ),
        );
      }
    } catch (e) {
      print('Error saat memuat data peminjaman: $e');
      setState(() {
        _isLoading = false;
        _selectedPeminjaman = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memuat data peminjaman: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(12),
        ),
      );
    }
  }

  // Date picker for picking tanggal kembali
  Future<void> _pickTanggalKembali() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now, // hanya bisa memilih hari ini atau ke depan
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4776E6),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _tanggalKembali = picked;
        final formatter = DateFormat('yyyy-MM-dd');
        _tanggalController.text = formatter.format(picked);
      });
    }
  }

  // Submit pengembalian
  Future<void> _submitPengembalian() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedPeminjaman == null || _tanggalKembali == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Lengkapi data terlebih dahulu'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(12),
          ),
        );
        return;
      }

      setState(() => _isSubmitting = true);

      try {
        final pengembalian = Pengembalian(
          namaPengembali: _namaController.text,
          peminjamanId: _selectedPeminjaman!.id,
          tanggalKembali: _tanggalKembali!.toIso8601String().substring(0, 10),
          jumlahDikembalikan: int.parse(_jumlahController.text),
          kondisi: _kondisiController.text,
          denda: 0,
          status: 'pending',
        );

        final success = await _pengembalianService.kirimPengembalian(
          pengembalian,
          widget.token,
        );

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Pengembalian berhasil dikirim!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              margin: const EdgeInsets.all(12),
            ),
          );

          _formKey.currentState!.reset();
          _namaController.clear();
          _jumlahController.clear();
          _kondisiController.clear();
          _tanggalController.clear();

          // Navigate back after successful return
          Navigator.pop(context);

          setState(() {
            _tanggalKembali = null;
          });
        } else {
          throw Exception('Gagal mengirim pengembalian');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengirim pengembalian: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(12),
          ),
        );
      } finally {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  void dispose() {
    _namaController.dispose();
    _jumlahController.dispose();
    _kondisiController.dispose();
    _tanggalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8E54E9)),
                ),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Container(
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
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Tombol Back
                          Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF4776E6,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: IconButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  icon: const Icon(
                                    Icons.arrow_back_ios_new,
                                    color: Color(0xFF4776E6),
                                  ),
                                  tooltip: 'Kembali ke riwayat',
                                ),
                              ),
                              const Spacer(),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Header with icon
                          Center(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF8E54E9,
                                    ).withOpacity(0.2),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.assignment_return_outlined,
                                size: 40,
                                color: Color(0xFF4776E6),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Title and subtitle
                          Text(
                            'Form Pengembalian Barang',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF4776E6),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Silakan isi form pengembalian dengan lengkap dan benar',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Form fields
                          _buildTextField(
                            _namaController,
                            'Nama Pengembali',
                            icon: Icons.person_outline_rounded,
                          ),
                          const SizedBox(height: 20),

                          // Selected Item Display
                          _buildSelectedItemDisplay(),
                          const SizedBox(height: 20),

                          // Date picker
                          GestureDetector(
                            onTap: _pickTanggalKembali,
                            child: AbsorbPointer(
                              child: _buildTextField(
                                _tanggalController,
                                'Tanggal Kembali',
                                icon: Icons.calendar_today_outlined,
                                suffix: const Icon(
                                  Icons.arrow_drop_down,
                                  color: Color(0xFF8E54E9),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Read-only quantity field
                          _buildReadOnlyQuantityField(),
                          const SizedBox(height: 20),

                          _buildTextField(
                            _kondisiController,
                            'Kondisi Barang',
                            icon: Icons.info_outline_rounded,
                            maxLines: 3,
                          ),
                          const SizedBox(height: 36),

                          // Submit Button
                          _isSubmitting
                              ? const Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFF8E54E9),
                                  ),
                                ),
                              )
                              : Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: [
                                      Color(0xFF4776E6),
                                      Color(0xFF8E54E9),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF8E54E9,
                                      ).withOpacity(0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton.icon(
                                  onPressed: _submitPengembalian,
                                  icon: const Icon(
                                    Icons.assignment_return_outlined,
                                  ),
                                  label: Text(
                                    'KIRIM PENGEMBALIAN',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 18,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                ),
                              ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
    );
  }

  Widget _buildSelectedItemDisplay() {
    if (_selectedPeminjaman == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade600),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Tidak ada peminjaman yang dipilih',
                style: GoogleFonts.poppins(
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final barangNama =
        _selectedPeminjaman!.barang?.nama ?? 'Barang tidak ditemukan';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.inventory_2_outlined, color: Colors.blue.shade600),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Barang yang Akan Dikembalikan',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.label_outline,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Nama Barang:',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  barangNama,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Peminjam:',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _selectedPeminjaman!.namaPeminjam,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyQuantityField() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.numbers_outlined, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Jumlah Dikembalikan',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _jumlahController.text.isEmpty
                      ? '0'
                      : '${_jumlahController.text} unit (semua yang dipinjam)',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color:
                        _jumlahController.text.isEmpty
                            ? Colors.grey.shade500
                            : Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.lock_outline, color: Colors.grey.shade500, size: 20),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(
    String label,
    IconData icon, {
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.poppins(color: Colors.grey),
      prefixIcon: Icon(icon, color: const Color(0xFF8E54E9)),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.grey.shade50,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xFF8E54E9), width: 2),
        borderRadius: BorderRadius.circular(16),
      ),
      errorBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.red.shade400),
        borderRadius: BorderRadius.circular(16),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.red.shade400, width: 2),
        borderRadius: BorderRadius.circular(16),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    TextInputType inputType = TextInputType.text,
    IconData? icon,
    Widget? suffix,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: inputType,
      maxLines: maxLines,
      style: GoogleFonts.poppins(),
      decoration: _inputDecoration(label, icon ?? Icons.edit, suffix: suffix),
      validator:
          (value) => value == null || value.isEmpty ? 'Wajib diisi' : null,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sisfo_fe/models/pengembalian_model.dart';
import 'package:sisfo_fe/models/peminjaman_model.dart';
import 'package:sisfo_fe/service/pengembalian_service.dart';
import 'package:sisfo_fe/service/peminjaman_service.dart';
import 'package:intl/intl.dart';

class PengembalianPage extends StatefulWidget {
  final String token;
  final Peminjaman? selectedPeminjaman;
  
  const PengembalianPage({
    super.key, 
    required this.token, 
    this.selectedPeminjaman
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
  List<Peminjaman> _peminjamanList = [];
  Peminjaman? _selectedPeminjaman;
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadPeminjamanUser();
  }

  // Function to load peminjaman list and filter items that are not returned yet
  Future<void> _loadPeminjamanUser() async {
    setState(() => _isLoading = true);
    try {
      final list = await PeminjamanService.fetchPeminjamanUser(widget.token);

      // Filter only peminjaman that are not returned or rejected
      final belumDikembalikan = list.where((p) =>
          p.status != 'returned' && p.status != 'rejected').toList();

      // Cari selectedPeminjaman dalam list
      Peminjaman? selectedFromList;
      if (widget.selectedPeminjaman != null) {
        // Cari peminjaman dengan ID yang sama
        final matches = belumDikembalikan.where((p) => p.id == widget.selectedPeminjaman!.id);
        if (matches.isNotEmpty) {
          selectedFromList = matches.first;
        } else {
          // Jika tidak ditemukan, tambahkan ke list (jika statusnya cocok)
          if (widget.selectedPeminjaman!.status != 'returned' && 
              widget.selectedPeminjaman!.status != 'rejected') {
            belumDikembalikan.add(widget.selectedPeminjaman!);
            selectedFromList = widget.selectedPeminjaman;
          }
        }
      }

      setState(() {
        _peminjamanList = belumDikembalikan;
        _selectedPeminjaman = selectedFromList ?? 
            (belumDikembalikan.isNotEmpty ? belumDikembalikan.first : null);
        _isLoading = false;
        
        // Isi form dengan data peminjaman yang dipilih
        if (_selectedPeminjaman != null) {
          _namaController.text = _selectedPeminjaman!.namaPeminjam;
          _jumlahController.text = _selectedPeminjaman!.jumlah.toString();
          // Set tanggal hari ini sebagai default
          final now = DateTime.now();
          _tanggalKembali = now;
          final formatter = DateFormat('yyyy-MM-dd');
          _tanggalController.text = formatter.format(now);
        }
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memuat data peminjaman: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(12),
        ),
      );
    }
  }

  // Date picker for picking tanggal kembali
  Future<void> _pickTanggalKembali() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2023),
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              margin: const EdgeInsets.all(12),
            ),
          );
          
          _formKey.currentState!.reset();
          _namaController.clear();
          _jumlahController.clear();
          _kondisiController.clear();
          _tanggalController.clear();

          // Update peminjaman list after successful return
          _loadPeminjamanUser(); // Reload the peminjaman list

          setState(() {
            _selectedPeminjaman =
                _peminjamanList.isNotEmpty ? _peminjamanList[0] : null;
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
      body: _isLoading
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
                              color: const Color(0xFF4776E6).withOpacity(0.1),
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
                                color: const Color(0xFF8E54E9).withOpacity(0.2),
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
                      
                      // Dropdown for Peminjaman
                      DropdownButtonFormField<Peminjaman>(
                        value: _selectedPeminjaman,
                        items: _peminjamanList.map((p) {
                          final barangNama = p.barang?.nama ?? 'Barang tidak ditemukan';
                          return DropdownMenuItem(
                            value: p,
                            child: Text(
                              '${p.namaPeminjam} - $barangNama',
                              style: GoogleFonts.poppins(),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => _selectedPeminjaman = val),
                        style: GoogleFonts.poppins(color: Colors.black87),
                        decoration: _inputDecoration(
                          'Pilih Peminjaman',
                          Icons.list_alt_rounded,
                        ),
                        validator: (val) => val == null ? 'Peminjaman wajib dipilih' : null,
                        icon: const Icon(
                          Icons.keyboard_arrow_down_rounded, 
                          color: Color(0xFF8E54E9)
                        ),
                        dropdownColor: Colors.white,
                        isExpanded: true,
                      ),
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
                      
                      _buildTextField(
                        _jumlahController,
                        'Jumlah Dikembalikan',
                        icon: Icons.numbers_outlined,
                        inputType: TextInputType.number,
                      ),
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
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8E54E9)),
                            ),
                          )
                        : Container(
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
                              onPressed: _submitPengembalian,
                              icon: const Icon(Icons.assignment_return_outlined),
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
                                padding: const EdgeInsets.symmetric(vertical: 18),
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

  InputDecoration _inputDecoration(String label, IconData icon, {Widget? suffix}) {
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
      validator: (value) => value == null || value.isEmpty ? 'Wajib diisi' : null,
    );
  }
}

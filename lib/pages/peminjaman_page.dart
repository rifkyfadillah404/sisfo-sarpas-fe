import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sisfo_fe/service/peminjaman_service.dart';
import 'package:sisfo_fe/service/barang_service.dart';
import 'package:sisfo_fe/models/barang_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class PeminjamanPage extends StatefulWidget {
  final String token;
  final Barang? barangDipilih;

  const PeminjamanPage({Key? key, required this.token, this.barangDipilih})
    : super(key: key);

  @override
  _PeminjamanPageState createState() => _PeminjamanPageState();
}

class _PeminjamanPageState extends State<PeminjamanPage> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _alasanController = TextEditingController();
  final _jumlahController = TextEditingController();
  final _tanggalController = TextEditingController();

  DateTime? _selectedDate;
  List<Barang> _barangList = [];
  Barang? _selectedBarang;
  bool _isLoading = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadBarang();
  }

  @override
  void dispose() {
    _namaController.dispose();
    _alasanController.dispose();
    _jumlahController.dispose();
    _tanggalController.dispose();
    super.dispose();
  }

  void _loadBarang() async {
    setState(() => _isLoading = true);
    try {
      final list = await BarangService().fetchBarang(widget.token);
      if (list.isEmpty) {
        throw Exception("Tidak ada barang yang tersedia");
      }

      // Mencari barang yang dipilih dari halaman detail
      Barang? selected;
      if (widget.barangDipilih != null) {
        try {
          // Cari barang berdasarkan ID
          final match = list.where((b) => b.id == widget.barangDipilih!.id);
          if (match.isNotEmpty) {
            selected = match.first;
          } else {
            // Jika tidak ditemukan berdasarkan ID, coba cari berdasarkan nama
            final matchByName = list.where((b) => b.nama == widget.barangDipilih!.nama);
            if (matchByName.isNotEmpty) {
              selected = matchByName.first;
            } else {
              // Jika tetap tidak ditemukan, gunakan barang yang dipilih langsung
              // dan tambahkan ke daftar agar bisa dipilih di dropdown
              selected = widget.barangDipilih;
              list.add(widget.barangDipilih!);
            }
          }
        } catch (e) {
          // Penanganan error saat mencari barang
          print("Error saat mencari barang dipilih: $e");
          // Gunakan barang pertama dari list sebagai fallback
          selected = list.first;
        }
      }

      setState(() {
        _barangList = list;
        _selectedBarang = selected ?? list.first;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text('Gagal memuat barang: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(12),
        )
      );
    }
  }

  void _submitPeminjaman() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedBarang == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          SnackBar(
            content: const Text('Barang belum dipilih'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(12),
          )
        );
        return;
      }

      setState(() => _isSubmitting = true);
      
      try {
        final prefs = await SharedPreferences.getInstance();
        final userId = prefs.getInt('user_id');

        if (userId == null) throw Exception("User ID tidak ditemukan");

        final jumlah = int.tryParse(_jumlahController.text);
        if (jumlah == null) throw Exception("Jumlah harus berupa angka");

        await PeminjamanService.createPeminjaman(
          token: widget.token,
          userId: userId,
          namaPeminjam: _namaController.text,
          alasanMeminjam: _alasanController.text,
          barangId: _selectedBarang!.id,
          jumlah: jumlah,
          tanggalPinjam: _tanggalController.text,
          status: 'pending',
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Peminjaman berhasil dibuat'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(12),
          ),
        );

        _formKey.currentState!.reset();
        _tanggalController.clear();
        _namaController.clear();
        _alasanController.clear();
        _jumlahController.clear();

        setState(() {
          _selectedBarang = _barangList.isNotEmpty ? _barangList[0] : null;
          _selectedDate = null;
          _isSubmitting = false;
        });
      } catch (e) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          SnackBar(
            content: Text('Gagal membuat peminjaman: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(12),
          )
        );
      }
    }
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
                      // Back Button
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
                              tooltip: 'Kembali ke detail barang',
                            ),
                          ),
                          const Spacer(),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      // Header
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
                            Icons.assignment_outlined,
                            size: 40,
                            color: Color(0xFF4776E6),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Lengkapi Data Peminjaman',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF4776E6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Silakan isi form berikut dengan lengkap dan benar',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      // Form Fields
                      _buildTextField(
                        _namaController, 
                        'Nama Peminjam',
                        icon: Icons.person_outline_rounded,
                      ),
                      const SizedBox(height: 20),
                      
                      // Dropdown for Barang
                      DropdownButtonFormField<Barang>(
                        value: _selectedBarang,
                        items: _barangList.map((barang) {
                          return DropdownMenuItem(
                            value: barang,
                            child: Text(
                              barang.nama,
                              style: GoogleFonts.poppins(),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (barang) => setState(() => _selectedBarang = barang),
                        style: GoogleFonts.poppins(color: Colors.black87),
                        decoration: _inputDecoration(
                          'Nama Barang',
                          Icons.inventory_2_outlined,
                        ),
                        validator: (value) => value == null ? 'Barang wajib dipilih' : null,
                        icon: const Icon(
                          Icons.keyboard_arrow_down_rounded, 
                          color: Color(0xFF8E54E9)
                        ),
                        dropdownColor: Colors.white,
                        isExpanded: true,
                      ),
                      const SizedBox(height: 20),
                      
                      _buildTextField(
                        _alasanController, 
                        'Alasan Meminjam', 
                        icon: Icons.note_alt_outlined,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 20),
                      
                      _buildTextField(
                        _jumlahController,
                        'Jumlah',
                        icon: Icons.numbers_outlined,
                        inputType: TextInputType.number,
                      ),
                      const SizedBox(height: 20),
                      
                      // Date Picker
                      GestureDetector(
                        onTap: () async {
                          FocusScope.of(context).requestFocus(FocusNode());
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
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
                              _selectedDate = picked;
                              final formatter = DateFormat('yyyy-MM-dd');
                              _tanggalController.text = formatter.format(picked);
                            });
                          }
                        },
                        child: AbsorbPointer(
                          child: _buildTextField(
                            _tanggalController,
                            'Tanggal Pinjam',
                            icon: Icons.calendar_today_outlined,
                            suffix: const Icon(
                              Icons.arrow_drop_down,
                              color: Color(0xFF8E54E9),
                            ),
                          ),
                        ),
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
                                onPressed: _submitPeminjaman,
                                icon: const Icon(Icons.send_rounded),
                                label: Text(
                                  'KIRIM PERMINTAAN',
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

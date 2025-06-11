import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sisfo_fe/service/peminjaman_service.dart';
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
  final _tanggalKembaliController = TextEditingController();

  DateTime? _selectedPinjamDate;
  DateTime? _selectedKembaliDate;
  Barang? _selectedBarang;
  bool _isLoading = false;
  bool _isSubmitting = false;

  // New variables for user name functionality
  bool _useLoggedInUser = true;
  String _loggedInUserName = '';
  bool _isLoadingUserData = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadBarang();
  }

  void _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userName = prefs.getString('user_name') ?? '';

      setState(() {
        _loggedInUserName = userName;
        _isLoadingUserData = false;
      });
    } catch (e) {
      setState(() {
        _loggedInUserName = '';
        _isLoadingUserData = false;
      });
    }
  }

  @override
  void dispose() {
    _namaController.dispose();
    _alasanController.dispose();
    _jumlahController.dispose();
    _tanggalController.dispose();
    _tanggalKembaliController.dispose();
    super.dispose();
  }

  void _loadBarang() async {
    setState(() => _isLoading = true);
    try {
      // If a specific barang is passed, use it directly
      if (widget.barangDipilih != null) {
        setState(() {
          _selectedBarang = widget.barangDipilih;
          _isLoading = false;
        });
      } else {
        // If no specific barang is passed, show error
        setState(() {
          _isLoading = false;
          _selectedBarang = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Tidak ada barang yang dipilih'),
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
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memuat barang: $e'),
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

  void _submitPeminjaman() async {
    if (_formKey.currentState!.validate()) {
      // Validate name selection
      if (_useLoggedInUser && _loggedInUserName.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Nama pengguna tidak tersedia. Silakan pilih "Masukkan nama lain"',
            ),
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

      if (!_useLoggedInUser && _namaController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Nama peminjam wajib diisi'),
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

      if (_selectedBarang == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Barang belum dipilih'),
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
        final prefs = await SharedPreferences.getInstance();
        final userId = prefs.getInt('user_id');

        if (userId == null) throw Exception("User ID tidak ditemukan");

        final jumlah = int.tryParse(_jumlahController.text);
        if (jumlah == null) throw Exception("Jumlah harus berupa angka");

        // Determine which name to use
        final namaPeminjam =
            _useLoggedInUser ? _loggedInUserName : _namaController.text;

        await PeminjamanService.createPeminjaman(
          token: widget.token,
          userId: userId,
          namaPeminjam: namaPeminjam,
          alasanMeminjam: _alasanController.text,
          barangId: _selectedBarang!.id,
          jumlah: jumlah,
          tanggalPinjam: _tanggalController.text,
          tanggalKembali: _tanggalKembaliController.text,
          status: 'pending',
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Peminjaman berhasil dibuat'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(12),
          ),
        );

        _formKey.currentState!.reset();
        _tanggalController.clear();
        _tanggalKembaliController.clear();
        _namaController.clear();
        _alasanController.clear();
        _jumlahController.clear();

        // Navigate back after successful submission
        Navigator.pop(context);

        setState(() {
          _selectedPinjamDate = null;
          _selectedKembaliDate = null;
          _isSubmitting = false;
        });
      } catch (e) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuat peminjaman: $e'),
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
                          // Back Button
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
                                    color: const Color(
                                      0xFF8E54E9,
                                    ).withOpacity(0.2),
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
                          _buildNameSection(),
                          const SizedBox(height: 20),

                          // Selected Item Display
                          _buildSelectedItemDisplay(),
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
                                  _selectedPinjamDate = picked;
                                  _selectedKembaliDate =
                                      picked; // Set return date same as borrow date
                                  final formatter = DateFormat('yyyy-MM-dd');
                                  _tanggalController.text = formatter.format(
                                    picked,
                                  );
                                  // Automatically set return date to be the same
                                  _tanggalKembaliController.text = formatter
                                      .format(picked);
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
                          const SizedBox(height: 20),

                          // Read-only return date field (automatically same as borrow date)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today_outlined,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Tanggal Kembali',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _tanggalKembaliController.text.isEmpty
                                            ? 'Sama dengan tanggal pinjam'
                                            : _tanggalKembaliController.text,
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          color:
                                              _tanggalKembaliController
                                                      .text
                                                      .isEmpty
                                                  ? Colors.grey.shade500
                                                  : Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.lock_outline,
                                  color: Colors.grey.shade500,
                                  size: 20,
                                ),
                              ],
                            ),
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
    if (_selectedBarang == null) {
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
                'Tidak ada barang yang dipilih',
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
                  'Barang yang Akan Dipinjam',
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
                  _selectedBarang!.nama,
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
                      Icons.inventory_outlined,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Stok Tersedia:',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${_selectedBarang!.stok} unit',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color:
                        _selectedBarang!.stok > 0
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.category_outlined,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Kategori:',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _selectedBarang!.kategori.namaKategori,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
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

  Widget _buildNameSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Toggle Section
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nama Peminjam',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF4776E6),
                ),
              ),
              const SizedBox(height: 12),

              // Option 1: Use logged-in user
              GestureDetector(
                onTap: () {
                  setState(() {
                    _useLoggedInUser = true;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        _useLoggedInUser
                            ? const Color(0xFF4776E6).withOpacity(0.1)
                            : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          _useLoggedInUser
                              ? const Color(0xFF4776E6)
                              : Colors.grey.shade300,
                      width: _useLoggedInUser ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _useLoggedInUser
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color:
                            _useLoggedInUser
                                ? const Color(0xFF4776E6)
                                : Colors.grey,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Gunakan nama saya',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w500,
                                color:
                                    _useLoggedInUser
                                        ? const Color(0xFF4776E6)
                                        : Colors.black87,
                              ),
                            ),
                            if (_isLoadingUserData)
                              Text(
                                'Memuat...',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              )
                            else
                              Text(
                                _loggedInUserName.isNotEmpty
                                    ? _loggedInUserName
                                    : 'Nama tidak tersedia',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Option 2: Manual input
              GestureDetector(
                onTap: () {
                  setState(() {
                    _useLoggedInUser = false;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        !_useLoggedInUser
                            ? const Color(0xFF4776E6).withOpacity(0.1)
                            : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          !_useLoggedInUser
                              ? const Color(0xFF4776E6)
                              : Colors.grey.shade300,
                      width: !_useLoggedInUser ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        !_useLoggedInUser
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color:
                            !_useLoggedInUser
                                ? const Color(0xFF4776E6)
                                : Colors.grey,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Masukkan nama lain',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500,
                            color:
                                !_useLoggedInUser
                                    ? const Color(0xFF4776E6)
                                    : Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Manual input field (shown only when not using logged-in user)
        if (!_useLoggedInUser) ...[
          const SizedBox(height: 16),
          _buildTextField(
            _namaController,
            'Masukkan Nama Peminjam',
            icon: Icons.person_outline_rounded,
            isRequired: true, // Required when manual input is selected
          ),
        ],
      ],
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
    bool isRequired = true,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: inputType,
      maxLines: maxLines,
      style: GoogleFonts.poppins(),
      decoration: _inputDecoration(label, icon ?? Icons.edit, suffix: suffix),
      validator:
          isRequired
              ? (value) => value == null || value.isEmpty ? 'Wajib diisi' : null
              : null,
    );
  }
}

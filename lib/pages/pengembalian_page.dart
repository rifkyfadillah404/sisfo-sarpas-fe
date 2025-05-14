import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sisfo_fe/models/pengembalian_model.dart';
import 'package:sisfo_fe/models/peminjaman_model.dart';
import 'package:sisfo_fe/service/pengembalian_service.dart';
import 'package:sisfo_fe/service/peminjaman_service.dart';

class PengembalianPage extends StatefulWidget {
  final String token;
  const PengembalianPage({super.key, required this.token});

  @override
  State<PengembalianPage> createState() => _PengembalianPageState();
}

class _PengembalianPageState extends State<PengembalianPage> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _jumlahController = TextEditingController();
  final _kondisiController = TextEditingController();

  final _pengembalianService = PengembalianService();

  DateTime? _tanggalKembali;
  List<Peminjaman> _peminjamanList = [];
  Peminjaman? _selectedPeminjaman;

  @override
  void initState() {
    super.initState();
    _loadPeminjamanUser();
  }

  // Function to load peminjaman list and filter items that are not returned yet
  Future<void> _loadPeminjamanUser() async {
  try {
    final list = await PeminjamanService.fetchPeminjamanUser(widget.token);

    // Filter only peminjaman that are not returned or rejected
    final belumDikembalikan = list.where((p) =>
        p.status != 'returned' && p.status != 'rejected').toList();

    setState(() {
      _peminjamanList = belumDikembalikan;
      _selectedPeminjaman =
          belumDikembalikan.isNotEmpty ? belumDikembalikan.first : null;
    });
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Gagal memuat data peminjaman: $e')),
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
    );
    if (picked != null) {
      setState(() => _tanggalKembali = picked);
    }
  }

  // Submit pengembalian
  Future<void> _submitPengembalian() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedPeminjaman == null || _tanggalKembali == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lengkapi data terlebih dahulu')),
        );
        return;
      }

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
          const SnackBar(content: Text('Pengembalian berhasil dikirim!')),
        );
        _formKey.currentState!.reset();
        _namaController.clear();
        _jumlahController.clear();
        _kondisiController.clear();

        // Update peminjaman list after successful return
        _loadPeminjamanUser(); // Reload the peminjaman list

        setState(() {
          _selectedPeminjaman =
              _peminjamanList.isNotEmpty ? _peminjamanList[0] : null;
          _tanggalKembali = null;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal mengirim pengembalian')),
        );
      }
    }
  }

  @override
  void dispose() {
    _namaController.dispose();
    _jumlahController.dispose();
    _kondisiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F9FC),
      appBar: AppBar(
        title: Text(
          'Form Pengembalian',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 5,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lengkapi Data Pengembalian',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(_namaController, 'Nama Pengembali'),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<Peminjaman>(
                          value: _selectedPeminjaman,
                          items: _peminjamanList.map((p) {
                            final barangNama = p.barang?.nama ?? 'Barang tidak ditemukan';
                            return DropdownMenuItem(
                              value: p,
                              child: Text(
                                '${p.namaPeminjam} - $barangNama (${p.tanggalPinjam})',
                              ),
                            );
                          }).toList(),
                          onChanged: (val) => setState(() => _selectedPeminjaman = val),
                          decoration: _inputDecoration('Pilih Peminjaman'),
                          validator: (val) => val == null ? 'Harus dipilih' : null,
                        ),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: _pickTanggalKembali,
                          child: AbsorbPointer(
                            child: _buildTextField(
                              TextEditingController(
                                text: _tanggalKembali == null
                                    ? ''
                                    : _tanggalKembali!.toIso8601String().split('T')[0],
                              ),
                              'Tanggal Kembali (YYYY-MM-DD)',
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          _jumlahController,
                          'Jumlah Dikembalikan',
                          inputType: TextInputType.number,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(_kondisiController, 'Kondisi Barang'),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _submitPengembalian,
                            icon: const Icon(Icons.send),
                            label: Text(
                              'Kirim',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: Colors.blueAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
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

  // Input decoration for text fields
  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.poppins(),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  // TextFormField widget
  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    TextInputType inputType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: inputType,
      decoration: _inputDecoration(label),
      validator: (value) => value == null || value.isEmpty ? 'Wajib diisi' : null,
    );
  }
}

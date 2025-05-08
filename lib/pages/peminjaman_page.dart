import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sisfo_fe/service/peminjaman_service.dart';
import 'package:sisfo_fe/service/barang_service.dart';
import 'package:sisfo_fe/models/barang_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PeminjamanPage extends StatefulWidget {
  final String token;

  const PeminjamanPage({Key? key, required this.token}) : super(key: key);

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
    try {
      final list = await BarangService().fetchBarang(widget.token);
      setState(() {
        _barangList = list;
        if (_selectedBarang == null && list.isNotEmpty) {
          _selectedBarang = list[0];
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat barang: $e')),
      );
    }
  }

  void _submitPeminjaman() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedBarang == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Barang belum dipilih')),
        );
        return;
      }

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
          const SnackBar(content: Text('Peminjaman berhasil dibuat')),
        );

        _formKey.currentState!.reset();
        _tanggalController.clear();
        _namaController.clear();
        _alasanController.clear();
        _jumlahController.clear();

        setState(() {
          _selectedBarang = _barangList.isNotEmpty ? _barangList[0] : null;
          _selectedDate = null;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membuat peminjaman: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F9FC),
      appBar: AppBar(
        title: Text(
          'Form Peminjaman',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: _barangList.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 5,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lengkapi Data Peminjaman',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(_namaController, 'Nama Peminjam'),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<Barang>(
                          value: _selectedBarang,
                          items: _barangList.map((barang) {
                            return DropdownMenuItem(
                              value: barang,
                              child: Text(barang.nama),
                            );
                          }).toList(),
                          onChanged: (barang) => setState(() => _selectedBarang = barang),
                          decoration: _inputDecoration('Nama Barang'),
                          validator: (value) =>
                              value == null ? 'Barang wajib dipilih' : null,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(_alasanController, 'Alasan Meminjam'),
                        const SizedBox(height: 16),
                        _buildTextField(
                          _jumlahController,
                          'Jumlah',
                          inputType: TextInputType.number,
                        ),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setState(() {
                                _selectedDate = picked;
                                _tanggalController.text =
                                    "${picked.toLocal()}".split(' ')[0];
                              });
                            }
                          },
                          child: AbsorbPointer(
                            child: _buildTextField(
                              _tanggalController,
                              'Tanggal Pinjam (YYYY-MM-DD)',
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _submitPeminjaman,
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

  Widget _buildTextField(TextEditingController controller, String label,
      {TextInputType inputType = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      keyboardType: inputType,
      decoration: _inputDecoration(label),
      validator: (value) => value == null || value.isEmpty ? 'Wajib diisi' : null,
    );
  }
}

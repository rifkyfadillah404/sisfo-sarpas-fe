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
  List<Barang> _allBarangList = [];
  List<Barang> _filteredBarangList = [];
  List<String> _kategoriList = [];
  String? _selectedKategori;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchBarang();
  }

  void _fetchBarang() async {
    try {
      final list = await BarangService().fetchBarang(widget.token);
      setState(() {
        _allBarangList = list;
        _filteredBarangList = list;  // Initially show all items
        _kategoriList = _getKategoriList(list);
        _kategoriList.insert(0, 'Semua'); // Menambahkan pilihan 'Semua' di kategori
      });
    } catch (e) {
      setState(() {
        _filteredBarangList = [];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat barang: $e')),
      );
    }
  }

  List<String> _getKategoriList(List<Barang> barangList) {
    Set<String> kategoriSet = {};
    for (var barang in barangList) {
      kategoriSet.add(barang.kategori.namaKategori);
    }
    return kategoriSet.toList();
  }

  void _filterBarang() {
    setState(() {
      _filteredBarangList = _allBarangList
          .where((barang) =>
              (_selectedKategori == null ||
                  _selectedKategori == 'Semua' ||
                  barang.kategori.namaKategori == _selectedKategori) &&
              barang.nama.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    });
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (query) {
                      setState(() {
                        _searchQuery = query;
                      });
                      _filterBarang();
                    },
                    decoration: InputDecoration(
                      labelText: 'Cari Barang',
                      prefixIcon: Icon(Icons.search),
                      contentPadding: EdgeInsets.symmetric(vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.blueAccent),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _selectedKategori,
                  hint: Text('Kategori'),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedKategori = newValue;
                    });
                    _filterBarang();
                  },
                  items: _kategoriList
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Barang>>(
              future: BarangService().fetchBarang(widget.token),  // Directly use the service here
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

                final barangList = _filteredBarangList;
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
                                      barang.foto!,// Menggunakan foto langsung dari API
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
          ),  
        ],
      ),
    );
  }
}

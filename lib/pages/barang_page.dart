import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sisfo_fe/models/barang_model.dart';
import 'package:sisfo_fe/service/barang_service.dart';
import 'package:sisfo_fe/pages/barang_detail_page.dart';

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
  bool _isLoading = true;

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
        _filteredBarangList = list;
        _kategoriList = _getKategoriList(list);
        _kategoriList.insert(0, 'Semua');
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _filteredBarangList = [];
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memuat barang: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(12),
        ),
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
      _filteredBarangList = _allBarangList.where((barang) {
        final matchKategori = _selectedKategori == null ||
            _selectedKategori == 'Semua' ||
            barang.kategori.namaKategori == _selectedKategori;
        final matchSearch = barang.nama
            .toLowerCase()
            .contains(_searchQuery.toLowerCase());
        return matchKategori && matchSearch;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search & Filter Area
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                TextField(
                  onChanged: (query) {
                    setState(() {
                      _searchQuery = query;
                    });
                    _filterBarang();
                  },
                  style: GoogleFonts.poppins(),
                  decoration: InputDecoration(
                    labelText: 'Cari Barang',
                    hintText: 'Masukkan nama barang',
                    hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400),
                    labelStyle: GoogleFonts.poppins(color: const Color(0xFF8E54E9)),
                    prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF8E54E9)),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF8E54E9)),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Kategori dropdown with improved UI
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedKategori,
                      hint: Text(
                        'Pilih Kategori',
                        style: GoogleFonts.poppins(color: Colors.grey.shade600),
                      ),
                      style: GoogleFonts.poppins(
                        color: Colors.black87,
                        fontSize: 14,
                      ),
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF8E54E9)),
                      isExpanded: true,
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedKategori = newValue;
                        });
                        _filterBarang();
                      },
                      items: _kategoriList.map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Statistics summary
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(
                "Menampilkan ${_filteredBarangList.length} barang",
                style: GoogleFonts.poppins(
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                _selectedKategori != null && _selectedKategori != 'Semua'
                    ? "Kategori: $_selectedKategori"
                    : "Semua Kategori",
                style: GoogleFonts.poppins(
                  color: const Color(0xFF8E54E9),
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        
        // Grid View
        Expanded(
          child: _isLoading 
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8E54E9)),
                  ),
                )
              : _filteredBarangList.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 80,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Tidak ada barang ditemukan",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (_searchQuery.isNotEmpty || _selectedKategori != 'Semua')
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: TextButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _searchQuery = '';
                                    _selectedKategori = 'Semua';
                                  });
                                  _filterBarang();
                                },
                                icon: const Icon(Icons.refresh),
                                label: const Text("Reset Filter"),
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFF4776E6),
                                ),
                              ),
                            ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.75,
                      ),
                      itemCount: _filteredBarangList.length,
                      itemBuilder: (context, index) {
                        final barang = _filteredBarangList[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BarangDetailPage(
                                  barang: barang,
                                  token: widget.token,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Image with gradient overlay
                                Expanded(
                                  child: Stack(
                                    children: [
                                      // Image
                                      ClipRRect(
                                        borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(20),
                                        ),
                                        child: Container(
                                          width: double.infinity,
                                          color: Colors.grey.shade100,
                                          child: barang.foto != null && barang.foto!.isNotEmpty
                                              ? Image.network(
                                                  barang.foto!,
                                                  fit: BoxFit.cover,
                                                  height: double.infinity,
                                                  errorBuilder: (_, __, ___) => Center(
                                                    child: Icon(
                                                      Icons.broken_image_rounded,
                                                      size: 40,
                                                      color: Colors.grey.shade400,
                                                    ),
                                                  ),
                                                )
                                              : Center(
                                                  child: Icon(
                                                    Icons.inventory_2_rounded,
                                                    size: 50,
                                                    color: Colors.grey.shade400,
                                                  ),
                                                ),
                                        ),
                                      ),
                                      
                                      // Kategori badge
                                      Positioned(
                                        top: 12,
                                        left: 12,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 5,
                                          ),
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [Color(0xFF4776E6), Color(0xFF8E54E9)],
                                            ),
                                            borderRadius: BorderRadius.circular(30),
                                          ),
                                          child: Text(
                                            barang.kategori.namaKategori,
                                            style: GoogleFonts.poppins(
                                              fontSize: 10,
                                              color: Colors.white,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                // Content
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        barang.nama,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: barang.stok > 0
                                                  ? Colors.green.shade50
                                                  : Colors.red.shade50,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              "Stok: ${barang.stok}",
                                              style: GoogleFonts.poppins(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                                color: barang.stok > 0
                                                    ? Colors.green.shade700
                                                    : Colors.red.shade700,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

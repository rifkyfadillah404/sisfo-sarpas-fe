// services/peminjaman_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/peminjaman_model.dart';

class PeminjamanService {
  static const String baseUrl = 'http://127.0.0.1:8000/api';

  /// Membuat peminjaman baru
  static Future<void> createPeminjaman({
    required String token,
    required int userId,
    required String namaPeminjam,
    required String alasanMeminjam,
    required int barangId,
    required int jumlah,
    required String tanggalPinjam,
    required String tanggalKembali,
    required String status,
  }) async {
    final response = await http.post(
      Uri.parse('http://127.0.0.1:8000/api/peminjaman'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json', // <-- tambahkan ini
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'user_id': userId,
        'nama_peminjam': namaPeminjam,
        'alasan_meminjam': alasanMeminjam,
        'barang_id': barangId,
        'jumlah': jumlah,
        'tanggal_pinjam': tanggalPinjam,  
        'tanggal_kembali' : tanggalKembali,
        'status': status,
      }),
    );

    if (response.statusCode != 201) {
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? 'Gagal membuat peminjaman');
    }
  }

  /// Mengambil riwayat peminjaman user yang login
  static Future<List<Peminjaman>> fetchPeminjamanUser(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/peminjaman/user'),
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['data'] == null) {
          return [];
        }
        
        final List<dynamic> jsonData = responseData['data'];
        return jsonData.map((e) => Peminjaman.fromJson(e)).toList();
      } else {
        print('Error response: ${response.body}');
        throw Exception('Gagal memuat data peminjaman: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception during fetchPeminjamanUser: $e');
      throw Exception('Gagal memuat data peminjaman: $e');
    }
  }
}

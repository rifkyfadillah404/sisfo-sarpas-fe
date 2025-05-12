import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/pengembalian_model.dart';

class PengembalianService {
  final String baseUrl = 'http://127.0.0.1:8000/api'; // Ganti dengan IP sesuai kebutuhan

  Future<bool> kirimPengembalian(Pengembalian pengembalian, String token) async {
    final url = Uri.parse('$baseUrl/pengembalian'); 
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(pengembalian.toJson()),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      // Respon berhasil, jika perlu bisa memparsing data tambahan dari server
      return true;
    } else {
      print('Gagal kirim: ${response.body}');
      return false;
    }
  }
}

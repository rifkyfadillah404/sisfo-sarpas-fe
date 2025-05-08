import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sisfo_fe/models/barang_model.dart';

class BarangService {

  static const String baseUrl = 'http://127.0.0.1:8000/api';

  Future<List<Barang>> fetchBarang(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/barang'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body)['data'];
      return data.map((item) => Barang.fromJson(item)).toList();
    } else {
      throw Exception('Gagal mengambil data barang');
    }
  }
}

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';

import 'package:sisfo_fe/pages/home_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Login App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      home: const LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  Future<void> _login() async {
    // Clear previous error messages
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Validate input fields
      if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
        setState(() {
          _errorMessage = 'Email dan password tidak boleh kosong';
          _isLoading = false;
        });
        return;
      }

      final url = Uri.parse('http://127.0.0.1:8000/api/login');

      http.Response response;
      try {
        response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': _emailController.text.trim(),
            'password': _passwordController.text,
          }),
        );
      } catch (e) {
        // Network error during request
        if (mounted) {
          setState(() {
            _errorMessage =
                'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.';
            _isLoading = false;
          });
        }
        return;
      }

      // Check if widget is still mounted before updating state
      if (!mounted) return;

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      // Handle response based on status code
      if (response.statusCode == 200) {
        // Success - parse response and navigate
        try {
          final data = jsonDecode(response.body);
          final token = data['access_token'];
          final userId = data['user']['id'];
          final userName = data['user']['name'] ?? '';
          final userEmail = data['user']['email'] ?? '';

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('access_token', token);
          await prefs.setInt('user_id', userId);
          await prefs.setString('user_name', userName);
          await prefs.setString('email', userEmail);

          // Check if widget is still mounted before navigating
          if (!mounted) return;

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => HomePage(token: token)),
          );
        } catch (e) {
          // Error parsing success response
          if (mounted) {
            setState(() {
              _errorMessage =
                  'Terjadi kesalahan saat memproses respons server.';
              _isLoading = false;
            });
          }
        }
      } else {
        // Error response - handle different status codes
        String errorMessage;

        print('Login failed with status: ${response.statusCode}');
        print('Response body: ${response.body}');

        // Handle Laravel validation errors (status 422)
        if (response.statusCode == 422) {
          try {
            final data = jsonDecode(response.body);

            // Laravel validation error format: {"message": "...", "errors": {"field": ["error1", "error2"]}}
            if (data['errors'] != null) {
              final errors = data['errors'] as Map<String, dynamic>;

              // Check if it's an email/credential error (from ValidationException)
              if (errors.containsKey('email')) {
                errorMessage =
                    'Email atau password salah. Silakan periksa kembali.';
              } else {
                // Other validation errors
                final errorMessages = <String>[];
                errors.forEach((field, messages) {
                  if (messages is List) {
                    errorMessages.addAll(messages.cast<String>());
                  }
                });
                errorMessage =
                    errorMessages.isNotEmpty
                        ? errorMessages.join(', ')
                        : 'Data yang dimasukkan tidak valid.';
              }
            } else if (data['message'] != null) {
              // Fallback to message field
              errorMessage =
                  'Email atau password salah. Silakan periksa kembali.';
            } else {
              errorMessage =
                  'Email atau password salah. Silakan periksa kembali.';
            }
          } catch (e) {
            print('Error parsing validation response: $e');
            errorMessage =
                'Email atau password salah. Silakan periksa kembali.';
          }
        } else if (response.statusCode == 401) {
          errorMessage = 'Email atau password salah. Silakan periksa kembali.';
        } else if (response.statusCode == 404) {
          errorMessage = 'Email tidak terdaftar. Silakan periksa email Anda.';
        } else if (response.statusCode >= 500) {
          errorMessage = 'Terjadi kesalahan server. Silakan coba lagi nanti.';
        } else {
          // Try to get message from response for other status codes
          try {
            final data = jsonDecode(response.body);
            errorMessage = data['message'] ?? 'Login gagal. Silakan coba lagi.';
          } catch (e) {
            print('Error parsing error response: $e');
            errorMessage = 'Login gagal. Silakan coba lagi.';
          }
        }

        // Update UI with error
        if (mounted) {
          setState(() {
            _errorMessage = errorMessage;
            _isLoading = false;
          });

          // Show snackbar for immediate feedback
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
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
    } catch (e) {
      // Handle any unexpected errors
      print('Unexpected error: $e');
      if (mounted) {
        setState(() {
          _errorMessage =
              'Terjadi kesalahan yang tidak terduga. Silakan coba lagi.';
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Terjadi kesalahan yang tidak terduga. Silakan coba lagi.',
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(12),
          ),
        );
      }
    } finally {
      // Make sure to update loading state if widget is still mounted
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        color: Colors.white,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Container(
                padding: const EdgeInsets.all(30.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 30,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.purple.withValues(alpha: 0.2),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/logo.png',
                        width: 80,
                        height: 80,
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Title and Subtitle
                    Text(
                      'Selamat Datang',
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF4776E6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Silakan masuk untuk melanjutkan',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),

                    const SizedBox(height: 36),

                    // Email Field
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: GoogleFonts.poppins(),
                      decoration: InputDecoration(
                        labelText: 'Email',
                        hintText: 'Masukkan email anda',
                        labelStyle: GoogleFonts.poppins(color: Colors.grey),
                        hintStyle: GoogleFonts.poppins(
                          color: Colors.grey.shade400,
                        ),
                        prefixIcon: const Icon(
                          Icons.email_rounded,
                          color: Color(0xFF8E54E9),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                            color: Color(0xFF8E54E9),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 16,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Password Field
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: GoogleFonts.poppins(),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        hintText: 'Masukkan password anda',
                        labelStyle: GoogleFonts.poppins(color: Colors.grey),
                        hintStyle: GoogleFonts.poppins(
                          color: Colors.grey.shade400,
                        ),
                        prefixIcon: const Icon(
                          Icons.lock_rounded,
                          color: Color(0xFF8E54E9),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: Colors.grey.shade600,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                            color: Color(0xFF8E54E9),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 16,
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Error Message
                    if (_errorMessage != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.red.shade700,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: GoogleFonts.poppins(
                                  color: Colors.red.shade700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: Icon(
                                Icons.close,
                                color: Colors.red.shade700,
                                size: 18,
                              ),
                              onPressed: () {
                                setState(() {
                                  _errorMessage = null;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 24),

                    // Login Button
                    _isLoading
                        ? const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF8E54E9),
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
                                color: const Color(
                                  0xFF8E54E9,
                                ).withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _login,
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              'MASUK',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),
                    // Sign Up Link
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

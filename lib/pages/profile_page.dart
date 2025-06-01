import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sisfo_fe/service/user_service.dart';
import 'dart:math';

class ProfileScreen extends StatefulWidget {
  final String token;
  final VoidCallback onLogout;

  const ProfileScreen({Key? key, required this.token, required this.onLogout})
    : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();
  bool _isLoading = true;
  String _userName = 'User SISFO';
  String _userEmail = 'user@example.com';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    print('Loading user data in profile page...');
    print(
      'Token: ${widget.token.substring(0, min(10, widget.token.length))}...',
    );

    try {
      final userData = await _userService.fetchUserData(widget.token);
      print('User data received in profile page: $userData');

      if (mounted) {
        setState(() {
          _userName = userData['name'] ?? 'User SISFO';
          _userEmail = userData['email'] ?? 'user@example.com';
          _isLoading = false;
        });
        print('Profile page updated with name: $_userName, email: $_userEmail');
      }
    } catch (e) {
      print('Error in profile page: $e');
      // Fallback to SharedPreferences if API fails
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          _userName = prefs.getString('user_name') ?? 'User SISFO';
          _userEmail = prefs.getString('email') ?? 'user@example.com';
          _isLoading = false;
        });
        print(
          'Profile page updated from SharedPreferences with name: $_userName, email: $_userEmail',
        );
      }
    }
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Konfirmasi Logout',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF4776E6),
            ),
          ),
          content: Text(
            'Apakah Anda yakin ingin keluar dari aplikasi?',
            style: GoogleFonts.poppins(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Batal',
                style: GoogleFonts.poppins(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                widget.onLogout();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4776E6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Logout',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // no gradient
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            // Content
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Loading Indicator
                      if (_isLoading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 50),
                          child: Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF4776E6),
                              ),
                            ),
                          ),
                        ),

                      if (!_isLoading) ...[
                        // Profile Image
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF4776E6),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF8E54E9).withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.person,
                              size: 50,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        Text(
                          _userName,
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF4776E6),
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          'Selamat datang di SISFO SARPAS',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 40),

                        // Info Card
                        _buildProfileInfoCard(
                          icon: Icons.email_outlined,
                          title: 'Email',
                          subtitle: _userEmail,
                        ),

                        const SizedBox(height: 16),

                        _buildProfileInfoCard(
                          icon: Icons.person_outline,
                          title: 'Nama Lengkap',
                          subtitle: _userName,
                        ),

                        const SizedBox(height: 40),

                        // Logout Button
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 30),
                          child: ElevatedButton.icon(
                            onPressed: () => _showLogoutConfirmation(context),
                            icon: const Icon(Icons.logout_rounded),
                            label: Text(
                              'Logout',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: Colors.redAccent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileInfoCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF4776E6).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF4776E6), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';
import '../widgets/no_internet_widget.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  bool _hasNetworkError = false;
  String? _errorMessage;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  bool get _isPhoneValid => _phoneController.text.trim().length == 10;

  Future<void> _handleLogin() async {
    if (!_isPhoneValid || _isLoading) return;

    HapticFeedback.mediumImpact();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _hasNetworkError = false;
    });

    final phone = _phoneController.text.trim();

    try {
      final res = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}/auth/login/rider'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone_number': phone}),
      );

      final body = jsonDecode(res.body);

      if (res.statusCode == 200) {
        final data = body['data'];
        final token = data['token'];
        final rider = data['rider'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        await prefs.setString('rider_id', rider['id'] ?? '');
        await prefs.setString('rider_phone', rider['phone_number'] ?? phone);
        if (rider['full_name'] != null) {
          await prefs.setString('rider_name', rider['full_name']);
        }

        if (!mounted) return;

        // Fetch onboarding status to resume exact state
        await _navigateBasedOnStatus(token);
      } else {
        setState(() {
          _errorMessage = body['message'] ?? 'Rider not found. Please check your phone number or register as a new partner.';
        });
      }
    } catch (e) {
      setState(() {
        _hasNetworkError = true;
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _navigateBasedOnStatus(String token) async {
    String targetRoute = '/select-client';
    try {
      final res = await http.get(
        Uri.parse('${AppConstants.apiBaseUrl}/documents/status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body)['data'];
        if (data != null && data['checklist'] is List) {
          final List checklist = data['checklist'];
          bool selfieUploaded = false;
          int docsUploaded = 0;

          for (var item in checklist) {
            if (item['is_uploaded'] == true) {
              if (item['document_type'] == 'selfie') {
                selfieUploaded = true;
              } else {
                docsUploaded++;
              }
            }
          }

          if (selfieUploaded) {
            targetRoute = '/selfie-bgv';
          } else if (docsUploaded > 0) {
            targetRoute = '/documents';
          } else {
            targetRoute = '/select-client';
          }
        }
      }
    } catch (_) {}

    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, targetRoute, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    if (_hasNetworkError) {
      return NoInternetWidget(
        title: 'Rider Login',
        showBackButton: false,
        onRetry: () {
          setState(() {
            _hasNetworkError = false;
          });
          _handleLogin();
        },
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      body: Column(
        children: [
          // ── TOP HEADER (Standardized dark indigo header) ────────
          Container(
            color: AppColors.accent,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Rider Login',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Enter your registered mobile number to log in',
                            style: GoogleFonts.inter(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── BODY FORM ──────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const SizedBox(height: 12),

                // Lock Graphic Banner
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_person_rounded,
                      color: AppColors.accent,
                      size: 36,
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // Error Message Card
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFCA5A5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: GoogleFonts.inter(
                              color: const Color(0xFF991B1B),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Mobile Number Input Field
                Text(
                  'Mobile Number',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (_) => setState(() {}),
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF111827),
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      hintText: 'Enter 10-digit number',
                      hintStyle: GoogleFonts.inter(color: const Color(0xFF9CA3AF), fontSize: 15),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(left: 16, right: 12),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🇮🇳', style: TextStyle(fontSize: 20)),
                            const SizedBox(width: 6),
                            Text(
                              '+91',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF111827),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(width: 1, height: 20, color: const Color(0xFFE5E7EB)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Submit Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isPhoneValid ? AppColors.accent : const Color(0xFFE5E7EB),
                    foregroundColor: _isPhoneValid ? Colors.white : const Color(0xFF9CA3AF),
                    elevation: _isPhoneValid ? 3 : 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _isPhoneValid && !_isLoading ? _handleLogin : null,
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : Text(
                          'Log In & Continue',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),

                const SizedBox(height: 24),

                // Register Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'New to GLAM Rider? ',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF6B7280),
                        fontSize: 14,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.pushReplacementNamed(context, '/register');
                      },
                      child: Text(
                        'Register as Partner',
                        style: GoogleFonts.inter(
                          color: AppColors.accent,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
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
    );
  }
}

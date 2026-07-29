import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';
import '../widgets/no_internet_widget.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool _hasNetworkError = false;
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();

  String _selectedGender = 'male';
  bool _locationDetected = false;
  bool _isDetectingLocation = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _detectLocation() async {
    setState(() {
      _isDetectingLocation = true;
      _locationDetected = false;
    });

    try {
      // Check if location services enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showError('Location services are disabled. Please enable GPS.');
        setState(() => _isDetectingLocation = false);
        return;
      }

      // Check & request permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showError('Location permission denied.');
          setState(() => _isDetectingLocation = false);
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        _showError('Location permission permanently denied. Enable from Settings.');
        setState(() => _isDetectingLocation = false);
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      // Reverse geocode via OpenStreetMap Nominatim (free, no package needed)
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json'
        '&lat=${position.latitude}&lon=${position.longitude}&zoom=10',
      );
      final response = await http.get(
        url,
        headers: {'User-Agent': 'GLAMRiderApp/1.0'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final address = data['address'] as Map<String, dynamic>? ?? {};
        final city = address['city'] ??
            address['town'] ??
            address['village'] ??
            address['county'] ??
            address['state'] ??
            'Unknown';
        setState(() {
          _cityController.text = city;
          _locationDetected = true;
          _isDetectingLocation = false;
        });
      } else {
        setState(() => _isDetectingLocation = false);
        _showError('Could not detect city. Please enter manually.');
      }
    } catch (e) {
      setState(() => _isDetectingLocation = false);
      _showError('Location detection failed. Please enter city manually.');
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.inter(color: Colors.white)),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  bool get _isFormValid =>
      _nameController.text.trim().isNotEmpty &&
      _phoneController.text.trim().length == 10 &&
      _cityController.text.trim().isNotEmpty;

  Future<void> _onNext() async {
    if (!_isFormValid || _isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final lang = prefs.getString('language') ?? 'hindi';

      final res = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'full_name': _nameController.text.trim(),
          'phone_number': _phoneController.text.trim(),
          'gender': _selectedGender,
          'city': _cityController.text.trim(),
          'preferred_language': lang == 'hi' ? 'hindi' : 'english',
        }),
      );

      final body = jsonDecode(res.body);

      if (res.statusCode == 201 || res.statusCode == 200) {
        final token = body['data']['token'];
        final rider = body['data']['rider'];

        await prefs.setString('token', token);
        await prefs.setString('rider_id', rider['id']);
        await prefs.setString('rider_phone', rider['phone_number']);

        if (!mounted) return;
        Navigator.pushNamed(context, '/select-client');
      } else if (res.statusCode == 409) {
        // If phone already registered, auto-login rider
        final loginRes = await http.post(
          Uri.parse('${AppConstants.apiBaseUrl}/auth/login/rider'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'phone_number': _phoneController.text.trim()}),
        );
        if (loginRes.statusCode == 200) {
          final loginData = jsonDecode(loginRes.body)['data'];
          await prefs.setString('token', loginData['token']);
          await prefs.setString('rider_id', loginData['rider']['id']);
          await prefs.setString('rider_phone', loginData['rider']['phone_number']);

          if (!mounted) return;
          Navigator.pushNamed(context, '/select-client');
        } else {
          _showError(body['message'] ?? 'Registration failed.');
        }
      } else {
        _showError(body['message'] ?? 'Registration failed. Check details.');
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
        _hasNetworkError = true;
      });
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasNetworkError) {
      return NoInternetWidget(
        title: 'Register as Partner',
        showBackButton: false,
        onRetry: () {
          setState(() {
            _hasNetworkError = false;
          });
          _onNext();
        },
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      body: Column(
        children: [
          // ── TOP HEADER — Dark Indigo ──────────────────────────────
          Container(
            color: AppColors.accent,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    Text(
                      'Tell us about yourself',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── FORM BODY ─────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Full Name
                  _FieldLabel('FULL NAME'),
                  const SizedBox(height: 6),
                  _InputField(
                    controller: _nameController,
                    hint: 'Ramesh Kumar',
                    onChanged: (_) => setState(() {}),
                  ),

                  const SizedBox(height: 18),

                  // Mobile Number
                  _FieldLabel('MOBILE NUMBER'),
                  const SizedBox(height: 6),
                  _InputField(
                    controller: _phoneController,
                    hint: '98XXXXXX21',
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    onChanged: (_) => setState(() {}),
                  ),

                  const SizedBox(height: 18),

                  // Gender
                  _FieldLabel('GENDER'),
                  const SizedBox(height: 10),
                  Row(
                    children: ['male', 'female', 'other'].map((g) {
                      final isSelected = _selectedGender == g;
                      return Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _selectedGender = g);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 9),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.accent.withOpacity(0.08)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(50),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.accent
                                    : const Color(0xFFD1D5DB),
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Text(
                              g[0].toUpperCase() + g.substring(1),
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected
                                    ? AppColors.accent
                                    : const Color(0xFF374151),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 18),

                  // City
                  _FieldLabel('CITY'),
                  const SizedBox(height: 6),
                  _InputField(
                    controller: _cityController,
                    hint: 'Enter your city',
                    onChanged: (_) => setState(() {}),
                  ),

                  const SizedBox(height: 14),

                  // Detect Location Button
                  GestureDetector(
                    onTap: _isDetectingLocation ? null : () {
                      HapticFeedback.lightImpact();
                      _detectLocation();
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.accent,
                          width: 1.5,
                          strokeAlign: BorderSide.strokeAlignInside,
                        ),
                        // Dashed effect via custom painter
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _isDetectingLocation
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.accent,
                                  ),
                                )
                              : const Text('📍',
                                  style: TextStyle(fontSize: 16)),
                          const SizedBox(width: 8),
                          Text(
                            _isDetectingLocation
                                ? 'Detecting location...'
                                : 'Detect my location automatically',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Location detected success text
                  if (_locationDetected) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const SizedBox(width: 4),
                        const Icon(Icons.check_circle_rounded,
                            color: Color(0xFF059669), size: 15),
                        const SizedBox(width: 6),
                        Text(
                          'Location detected ✓',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF059669),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          // ── NEXT BUTTON — Bottom ──────────────────────────────────
          Container(
            color: AppColors.surfaceLight,
            padding:
                const EdgeInsets.fromLTRB(20, 12, 20, 32),
            child: GestureDetector(
              onTap: (_isFormValid && !_isSubmitting)
                  ? () {
                      HapticFeedback.mediumImpact();
                      _onNext();
                    }
                  : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: _isFormValid
                      ? AppColors.accent
                      : const Color(0xFFD1D5DB),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Center(
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Next: Choose Client',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ),
          ),

          // ── ALREADY A RIDER? LOG IN LINK ──────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Already a rider? ',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF6B7280),
                    fontSize: 14,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.pushNamed(context, '/login');
                  },
                  child: Text(
                    'Log In',
                    style: GoogleFonts.inter(
                      color: AppColors.accent,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
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

// ── Reusable Widgets ─────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF6B7280),
        letterSpacing: 0.8,
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final Function(String)? onChanged;

  const _InputField({
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.inputFormatters,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF111827)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(
            fontSize: 14, color: const Color(0xFF9CA3AF)),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: AppColors.accent, width: 1.5),
        ),
      ),
    );
  }
}

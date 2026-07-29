import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';
import '../widgets/no_internet_widget.dart';

class SelfieBgvScreen extends StatefulWidget {
  const SelfieBgvScreen({super.key});

  @override
  State<SelfieBgvScreen> createState() => _SelfieBgvScreenState();
}

class _SelfieBgvScreenState extends State<SelfieBgvScreen> {
  bool _hasNetworkError = false;
  File? _selfieFile;
  bool _isUploading = false;
  bool _isVerified = false;
  String? _errorMessage;
  bool _showBgvTracker = false;

  // Onboarding Data variables matching Image 1 & Image 2
  String _bgvStatus = 'verifying'; // 'verifying', 'approved', 'rejected'
  String _riderName = 'Ramesh';
  String _clientName = 'Flipkart Minutes';
  String _workerId = 'FKM-KOL-004821';
  String _hubName = 'Salt Lake Sector V Hub';
  String _tlName = 'Rohit Sharma';
  String _tlContact = '98300 00001';

  @override
  void initState() {
    super.initState();
    _checkExistingSelfie();
  }

  Future<void> _checkExistingSelfie() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final savedPhone = prefs.getString('rider_phone');
      if (savedPhone != null && savedPhone.isNotEmpty) {
        _riderName = prefs.getString('rider_name') ?? 'Rider';
      }

      if (token == null) return;

      final res = await http.get(
        Uri.parse('${AppConstants.apiBaseUrl}/documents/status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body)['data'];
        if (data != null) {
          setState(() {
            if (data['rider_name'] != null && data['rider_name'].toString().isNotEmpty) {
              _riderName = data['rider_name'];
            }
            if (data['client_name'] != null && data['client_name'].toString().isNotEmpty) {
              _clientName = data['client_name'];
            }
            if (data['worker_id'] != null && data['worker_id'].toString().isNotEmpty) {
              _workerId = data['worker_id'];
            }
            if (data['hub_name'] != null && data['hub_name'].toString().isNotEmpty) {
              _hubName = data['hub_name'];
            }
            if (data['tl_name'] != null && data['tl_name'].toString().isNotEmpty) {
              _tlName = data['tl_name'];
            }
            if (data['tl_contact'] != null && data['tl_contact'].toString().isNotEmpty) {
              _tlContact = data['tl_contact'];
            }
            if (data['overall_status'] == 'approved') {
              _bgvStatus = 'approved';
              _showBgvTracker = true;
              _isVerified = true;
            }

            if (data['checklist'] is List) {
              final List checklist = data['checklist'];
              for (var item in checklist) {
                if (item['document_type'] == 'selfie' && item['is_uploaded'] == true) {
                  _isVerified = true;
                  _showBgvTracker = true; // Skip selfie screen on app restart
                  if (item['status'] == 'approved' || data['overall_status'] == 'approved') {
                    _bgvStatus = 'approved';
                  }
                }
              }
            }
          });
        }
      }
    } catch (_) {
      setState(() {
        _hasNetworkError = true;
      });
    }
  }

  Future<void> _takeOrPickSelfie() async {
    HapticFeedback.selectionClick();
    setState(() {
      _errorMessage = null;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );

      if (result != null && result.files.single.path != null) {
        final path = result.files.single.path!;
        final file = File(path);

        setState(() {
          _selfieFile = file;
          _isUploading = true;
        });

        await _uploadSelfie(file);
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Could not capture photo. Please try again.";
        _isUploading = false;
      });
    }
  }

  Future<void> _uploadSelfie(File file) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        setState(() {
          _errorMessage = "Session expired. Please log in again.";
          _isUploading = false;
        });
        return;
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConstants.apiBaseUrl}/documents/upload'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.fields['document_type'] = 'selfie';

      final filename = file.path.split('/').last;
      final ext = filename.split('.').last.toLowerCase();

      MediaType mimeType = (ext == 'png')
          ? MediaType('image', 'png')
          : MediaType('image', 'jpeg');

      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          file.path,
          filename: filename,
          contentType: mimeType,
        ),
      );

      var streamedRes = await request.send();
      var res = await http.Response.fromStream(streamedRes);

      if (res.statusCode == 200 || res.statusCode == 201) {
        setState(() {
          _isVerified = true;
          _isUploading = false;
          _errorMessage = null;
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Selfie verified successfully!',
              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600),
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        final errJson = jsonDecode(res.body);
        setState(() {
          _errorMessage = errJson['message'] ?? "We couldn't detect your face clearly. Please look straight at the camera.";
          _isUploading = false;
          _isVerified = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Network upload failed. Please try again.";
        _isUploading = false;
        _isVerified = false;
      });
    }
  }

  Future<void> _logout() async {
    HapticFeedback.mediumImpact();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF1E1B4B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 28),
              ),
              const SizedBox(height: 16),
              Text(
                'Log Out',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Are you sure you want to log out from GLAM Rider?',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.white.withOpacity(0.2)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text(
                        'Logout',
                        style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/language', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasNetworkError) {
      return NoInternetWidget(
        title: _showBgvTracker ? 'BGV Status Timeline' : 'Selfie Verification',
        showLogout: true,
        onLogout: _logout,
        onRetry: () {
          setState(() {
            _hasNetworkError = false;
          });
          _checkExistingSelfie();
        },
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      body: Column(
        children: [
          // ── TOP HEADER ─────────────────────────────────────────
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
                            _showBgvTracker
                                ? (_bgvStatus == 'approved' ? 'Client Onboarding' : 'BGV Status Timeline')
                                : 'Selfie Verification',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            _showBgvTracker
                                ? (_bgvStatus == 'approved'
                                    ? 'Onboarding complete & deployment details'
                                    : 'Real-time background verification progress')
                                : 'Look straight at the camera in good lighting',
                            style: GoogleFonts.inter(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Logout',
                      onPressed: _logout,
                      icon: const Icon(Icons.logout_rounded,
                          color: Colors.white, size: 22),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── BODY ────────────────────────────────────────────────
          Expanded(
            child: _showBgvTracker ? _buildBgvTrackerView() : _buildSelfieView(),
          ),
        ],
      ),
    );
  }

  Widget _buildSelfieView() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 12),

        // ── CIRCULAR CAMERA / SELFIE PREVIEW FRAME ────────────────
        Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accent.withOpacity(0.06),
                  border: Border.all(
                    color: _isVerified
                        ? const Color(0xFF10B981)
                        : _errorMessage != null
                            ? const Color(0xFFDC2626)
                            : AppColors.accent,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: _selfieFile != null
                      ? Image.file(_selfieFile!, fit: BoxFit.cover)
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.photo_camera_front_rounded,
                              size: 72,
                              color: AppColors.accent.withOpacity(0.8),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap below to capture',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: const Color(0xFF6B7280),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              if (_isUploading)
                Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withOpacity(0.4),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // ── ERROR BANNER (Matching Screenshot UI) ─────────────────
        if (_errorMessage != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFCA5A5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: Color(0xFF991B1B), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Verification failed',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF991B1B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _errorMessage!,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF7F1D1D),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],

        // ── SUCCESS BANNER ────────────────────────────────────────
        if (_isVerified && _errorMessage == null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFA7F3D0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: Color(0xFF065F46), size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Selfie verified successfully!',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF065F46),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],

        // ── ACTION BUTTON: TAKE / RETAKE PHOTO ─────────────────────
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.accent, width: 2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          onPressed: _isUploading ? null : _takeOrPickSelfie,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _selfieFile != null || _isVerified ? Icons.refresh_rounded : Icons.camera_alt_rounded,
                color: AppColors.accent,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                _selfieFile != null || _isVerified ? 'Retake Photo' : 'Take Photo',
                style: GoogleFonts.inter(
                  color: AppColors.accent,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // ── ACTION BUTTON: CONTINUE TO BGV ────────────────────────
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _isVerified ? AppColors.accent : const Color(0xFFE5E7EB),
            foregroundColor: _isVerified ? Colors.white : const Color(0xFF9CA3AF),
            elevation: _isVerified ? 3 : 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          onPressed: _isVerified
              ? () {
                  HapticFeedback.mediumImpact();
                  setState(() {
                    _showBgvTracker = true;
                  });
                }
              : null,
          child: Text(
            'Continue to Background Verification',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  // ── DYNAMIC BGV TRACKER SWITCHER ──────────────────────────────
  Widget _buildBgvTrackerView() {
    if (_bgvStatus == 'approved') {
      return _buildClientOnboardedCompleteView();
    }
    return _buildBgvStatusTimelineView();
  }

  // ── IMAGE 1: 6. BGV STATUS TIMELINE ────────────────────────────
  Widget _buildBgvStatusTimelineView() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 4),

        // 1. Top Hourglass Status Header Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              const Text('⏳', style: TextStyle(fontSize: 40)),
              const SizedBox(height: 14),
              Text(
                'Your background verification\nis in progress',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF111827),
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Usually takes 24–48 hours. We'll notify\nyou the moment it clears.",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF6B7280),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // 2. Timeline Status List Card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTimelineRow('Registered', isCompleted: true),
              const SizedBox(height: 16),
              _buildTimelineRow('Documents submitted', isCompleted: true),
              const SizedBox(height: 16),
              _buildTimelineRow('Background verification', isInProgress: true),
              const SizedBox(height: 16),
              _buildTimelineRow('BGV cleared', isPending: true),
              const SizedBox(height: 16),
              _buildTimelineRow('Client onboarding', isPending: true),
              const SizedBox(height: 16),
              _buildTimelineRow('Ready to work', isPending: true),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // 3. Push Notification & WhatsApp Alert Box (Image 1 Exact Match)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFEEF2FF), // Soft light blue/indigo
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🔔', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "We'll send a push notification &\nWhatsApp update",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF3730A3),
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // 4. Distinct Refresh Status Button (Positioned below with clear spacing)
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.accent, width: 1.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          onPressed: () {
            HapticFeedback.lightImpact();
            _checkExistingSelfie();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Refreshing BGV Status from GLAM Admin Server...',
                  style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600),
                ),
                backgroundColor: AppColors.accent,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            );
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.refresh_rounded, color: AppColors.accent, size: 20),
              const SizedBox(width: 8),
              Text(
                'Refresh Status',
                style: GoogleFonts.inter(
                  color: AppColors.accent,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildTimelineRow(String title, {bool isCompleted = false, bool isInProgress = false, bool isPending = false}) {
    Color dotColor;
    Color textColor;
    FontWeight fontWeight;

    if (isCompleted) {
      dotColor = const Color(0xFF10B981); // Emerald green
      textColor = const Color(0xFF111827);
      fontWeight = FontWeight.w700;
    } else if (isInProgress) {
      dotColor = const Color(0xFFD97706); // Amber / Brown
      textColor = const Color(0xFF111827);
      fontWeight = FontWeight.w700;
    } else {
      dotColor = const Color(0xFFE5E7EB); // Light grey
      textColor = const Color(0xFF9CA3AF); // Grey
      fontWeight = FontWeight.w600;
    }

    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 14),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: fontWeight,
            color: textColor,
          ),
        ),
      ],
    );
  }

  // ── IMAGE 2: 7. CLIENT ONBOARDING COMPLETE ──────────────────────
  Widget _buildClientOnboardedCompleteView() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 4),

        // 1. Celebration Banner Card (Image 2 Exact Match)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF312E81), // Solid Deep Indigo matching mockup
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF312E81).withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              const Text('🎉', style: TextStyle(fontSize: 44)),
              const SizedBox(height: 14),
              Text(
                "You're onboarded with\n$_clientName!",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Welcome to the GLAM rider network,\n$_riderName',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.85),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // 2. Rider Deployment Table Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildTableRow('Worker ID', _workerId),
              const Divider(height: 24, color: Color(0xFFF3F4F6)),
              _buildTableRow('Hub', _hubName),
              const Divider(height: 24, color: Color(0xFFF3F4F6)),
              _buildTableRow('Hub Location', 'Open in Maps →', isLink: true),
              const Divider(height: 24, color: Color(0xFFF3F4F6)),
              _buildTableRow('Reporting TL', _tlName),
              const Divider(height: 24, color: Color(0xFFF3F4F6)),
              _buildTableRow('TL Contact', _tlContact),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // 3. Download Client App Button
        GestureDetector(
          onTap: () {
            HapticFeedback.mediumImpact();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Opening download page for $_clientName App...',
                  style: GoogleFonts.inter(color: Colors.white),
                ),
                backgroundColor: AppColors.accent,
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1B4B), // Dark Indigo Pill
              borderRadius: BorderRadius.circular(50),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.download_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Download $_clientName App',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        // 4. Next Steps Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Next steps',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 16),
              _buildNumberedNextStep(1, 'Download & log in using this mobile number'),
              const SizedBox(height: 14),
              _buildNumberedNextStep(2, 'Reach your hub for first shift briefing'),
              const SizedBox(height: 14),
              _buildNumberedNextStep(3, 'Go online and accept your first order'),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // 5. View My Payout Dashboard Button
        GestureDetector(
          onTap: () {
            HapticFeedback.mediumImpact();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Payout Dashboard Coming Soon! We\'ll notify you once active.',
                  style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600),
                ),
                backgroundColor: AppColors.accent,
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(50),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                'View My Payout Dashboard',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildTableRow(String label, String value, {bool isLink = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: const Color(0xFF6B7280),
            fontWeight: FontWeight.w400,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isLink ? const Color(0xFF4338CA) : const Color(0xFF111827),
          ),
        ),
      ],
    );
  }

  Widget _buildNumberedNextStep(int number, String text) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: Color(0xFFEEF2FF),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$number',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF4338CA),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF4B5563),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

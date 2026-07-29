import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';
import '../widgets/no_internet_widget.dart';

class _DocItem {
  final String key;
  final String title;
  final String subtitle;
  final IconData icon;
  String status; // 'not_uploaded', 'verifying', 'approved', 'rejected'
  String? rejectionReason;
  String? fileName;

  _DocItem({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.status = 'not_uploaded',
    this.rejectionReason,
    this.fileName,
  });
}

class DocumentCenterScreen extends StatefulWidget {
  const DocumentCenterScreen({super.key});

  @override
  State<DocumentCenterScreen> createState() => _DocumentCenterScreenState();
}

class _DocumentCenterScreenState extends State<DocumentCenterScreen> {
  bool _hasNetworkError = false;

  final List<_DocItem> _documents = [
    _DocItem(
      key: 'aadhaar',
      title: 'Aadhaar Card',
      subtitle: 'Front and back side PDF or photo',
      icon: Icons.badge_outlined,
    ),
    _DocItem(
      key: 'pan',
      title: 'PAN Card',
      subtitle: 'Clear photo or scanned PDF of PAN',
      icon: Icons.credit_card_outlined,
    ),
    _DocItem(
      key: 'driving_licence',
      title: 'Driving Licence',
      subtitle: 'Valid LMV / Transport licence',
      icon: Icons.drive_eta_outlined,
    ),
    _DocItem(
      key: 'vehicle_rc',
      title: 'Vehicle RC',
      subtitle: 'Registration Certificate of your vehicle',
      icon: Icons.directions_car_outlined,
    ),
    _DocItem(
      key: 'bank_passbook',
      title: 'Bank Passbook / Cheque',
      subtitle: 'For weekly payout transfer',
      icon: Icons.account_balance_outlined,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fetchDocumentStatus();
  }

  Future<void> _fetchDocumentStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
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
        if (data != null && data['checklist'] is List) {
          final List checklist = data['checklist'];
          setState(() {
            for (var item in checklist) {
              final docKey = item['document_type'];
              final doc = _documents.firstWhere(
                (d) => d.key == docKey,
                orElse: () => _documents.first,
              );
              if (item['is_uploaded'] == true) {
                doc.status = item['status'] ?? 'verifying';
                doc.rejectionReason = item['rejection_reason'];
                doc.fileName = item['file_name'];
              }
            }
          });
        }
      } else if (res.statusCode == 401) {
        await prefs.clear();
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(context, '/register', (route) => false);
      }
    } catch (_) {
      setState(() {
        _hasNetworkError = true;
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

  // Opens real phone file storage & uploads directly to backend!
  Future<void> _pickAndUploadDocument(_DocItem doc) async {
    HapticFeedback.selectionClick();
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null || token.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Session expired or token missing. Please register/login first.',
              style: GoogleFonts.inter(color: Colors.white),
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
        return;
      }

      FilePickerResult? result;
      try {
        result = await FilePicker.platform.pickFiles(
          type: FileType.any,
        );
      } catch (pickerErr) {
        debugPrint('[FILE_PICKER] Custom pick failed, retrying: $pickerErr');
        result = await FilePicker.platform.pickFiles();
      }

      if (result != null && result.files.isNotEmpty && result.files.single.path != null) {
        HapticFeedback.mediumImpact();
        final pickedFile = result.files.single;

        final ext = (pickedFile.extension ?? pickedFile.name.split('.').last).toLowerCase();
        final allowed = ['pdf', 'png', 'jpg', 'jpeg'];
        if (!allowed.contains(ext)) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Invalid format ($ext). Only PDF, PNG, JPG allowed.',
                style: GoogleFonts.inter(color: Colors.white),
              ),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          );
          return;
        }

        // Show uploading status in UI
        setState(() {
          doc.status = 'verifying';
          doc.fileName = 'Uploading... (${pickedFile.name})';
        });

        var request = http.MultipartRequest(
          'POST',
          Uri.parse('${AppConstants.apiBaseUrl}/documents/upload'),
        );

        request.headers['Authorization'] = 'Bearer $token';
        request.fields['document_type'] = doc.key;

        MediaType mimeType;
        if (ext == 'pdf') {
          mimeType = MediaType('application', 'pdf');
        } else if (ext == 'png') {
          mimeType = MediaType('image', 'png');
        } else if (ext == 'jpg' || ext == 'jpeg') {
          mimeType = MediaType('image', 'jpeg');
        } else {
          mimeType = MediaType('application', 'octet-stream');
        }

        request.files.add(
          await http.MultipartFile.fromPath(
            'file',
            pickedFile.path!,
            filename: pickedFile.name,
            contentType: mimeType,
          ),
        );

        var streamedRes = await request.send();
        var res = await http.Response.fromStream(streamedRes);

        if (res.statusCode == 200 || res.statusCode == 201) {
          setState(() {
            doc.status = 'verifying';
            doc.fileName = pickedFile.name;
            doc.rejectionReason = null;
          });

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${doc.title} uploaded successfully to GLAM Dashboard!',
                style: GoogleFonts.inter(color: Colors.white),
              ),
              backgroundColor: const Color(0xFF059669),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          );
        } else {
          String errMsg = 'Upload failed.';
          try {
            final errBody = jsonDecode(res.body);
            errMsg = errBody['message'] ?? errMsg;
          } catch (_) {}

          setState(() {
            doc.status = 'not_uploaded';
            doc.fileName = null;
          });
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                errMsg,
                style: GoogleFonts.inter(color: Colors.white),
              ),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('[DOC_UPLOAD_ERROR] $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upload error: ${e.toString()}',
              style: GoogleFonts.inter(color: Colors.white)),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  int get _uploadedCount => _documents.where((d) => d.status != 'not_uploaded').length;
  bool get _canProceed => _uploadedCount == _documents.length;

  void _onProceed() {
    HapticFeedback.mediumImpact();
    if (!_canProceed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'All ${_documents.length} documents must be uploaded before proceeding to BGV Tracking. ($_uploadedCount/${_documents.length} completed)',
            style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppColors.accent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }
    Navigator.pushNamed(context, '/selfie-bgv');
  }

  @override
  Widget build(BuildContext context) {
    if (_hasNetworkError) {
      return NoInternetWidget(
        title: 'Upload Required Documents',
        showLogout: true,
        onLogout: _logout,
        onRetry: () {
          setState(() {
            _hasNetworkError = false;
          });
          _fetchDocumentStatus();
        },
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      body: Column(
        children: [
          // ── TOP HEADER — Accent Indigo with Title at Top ─────────
          Container(
            color: AppColors.accent,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Upload Required Documents',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Verification documents for BGV',
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

          // ── DOCUMENT LIST ────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              children: _documents.map((doc) => _buildDocCard(doc)).toList(),
            ),
          ),

          // ── BOTTOM PROCEED BUTTON ────────────────────────────────
          Container(
            color: AppColors.surfaceLight,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            child: GestureDetector(
              onTap: _onProceed,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: _canProceed
                      ? AppColors.accent
                      : const Color(0xFF9CA3AF),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Center(
                  child: Text(
                    'Proceed to Selfie & BGV Tracking',
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
        ],
      ),
    );
  }

  Widget _buildDocCard(_DocItem doc) {
    Color badgeBg;
    Color badgeText;
    String statusLabel;
    IconData statusIcon;

    switch (doc.status) {
      case 'approved':
        badgeBg = const Color(0xFFD1FAE5);
        badgeText = const Color(0xFF047857);
        statusLabel = 'Verified ✓';
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'verifying':
      case 'pending':
      case 'local_check_passed':
        badgeBg = const Color(0xFFFEF3C7);
        badgeText = const Color(0xFFB45309);
        statusLabel = 'Verifying...';
        statusIcon = Icons.access_time_rounded;
        break;
      case 'rejected':
        badgeBg = const Color(0xFFFEE2E2);
        badgeText = const Color(0xFFB91C1C);
        statusLabel = 'Action Needed';
        statusIcon = Icons.warning_amber_rounded;
        break;
      default:
        badgeBg = const Color(0xFFF3F4F6);
        badgeText = const Color(0xFF6B7280);
        statusLabel = 'Not Uploaded';
        statusIcon = Icons.upload_file_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: doc.status == 'rejected'
              ? const Color(0xFFFCA5A5)
              : doc.status == 'approved'
                  ? const Color(0xFFA7F3D0)
                  : const Color(0xFFE5E7EB),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Icon + Title/Subtitle + Upload Action Button on Right Side
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Document Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(doc.icon, color: AppColors.accent, size: 20),
              ),

              const SizedBox(width: 12),

              // Title & Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doc.title,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      doc.fileName ?? doc.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: doc.fileName != null
                            ? AppColors.accent
                            : const Color(0xFF6B7280),
                        fontWeight: doc.fileName != null
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Action Button on the Right Side (as in image)
              GestureDetector(
                onTap: doc.status == 'approved'
                    ? null
                    : () => _pickAndUploadDocument(doc),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: doc.status == 'approved'
                        ? const Color(0xFFF3F4F6)
                        : doc.status == 'rejected'
                            ? const Color(0xFFDC2626)
                            : AppColors.accent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    doc.status == 'approved'
                        ? 'Completed'
                        : doc.status == 'rejected'
                            ? 'Re-upload'
                            : 'Upload',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: doc.status == 'approved'
                          ? const Color(0xFF9CA3AF)
                          : Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Bottom Row: Status Tag below
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, color: badgeText, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      statusLabel,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: badgeText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Rejection Reason Box if rejected
          if (doc.status == 'rejected' && doc.rejectionReason != null) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      color: Color(0xFFDC2626), size: 14),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Reason: ${doc.rejectionReason}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFFDC2626),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

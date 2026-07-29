import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';
import '../widgets/no_internet_widget.dart';

// Client model matching backend tb_clients
class _Client {
  final int id;
  final String name;
  final String code;
  final String description;
  final double ratePerOrder;
  final double avgDailyEarning;
  final String payoutCycle;

  _Client({
    required this.id,
    required this.name,
    required this.code,
    required this.description,
    required this.ratePerOrder,
    required this.avgDailyEarning,
    required this.payoutCycle,
  });

  factory _Client.fromJson(Map<String, dynamic> json) => _Client(
        id: json['id'],
        name: json['name'],
        code: json['code'],
        description: json['description'] ?? '',
        ratePerOrder: double.parse(json['rate_per_order'].toString()),
        avgDailyEarning: double.parse(json['avg_daily_earning'].toString()),
        payoutCycle: json['payout_cycle'],
      );
}

// Brand colors per client code
Color _clientColor(String code) {
  switch (code) {
    case 'FKM':
      return const Color(0xFFF5A623); // Flipkart yellow-orange
    case 'ZEPTO':
      return const Color(0xFF8B2FC9); // Zepto purple
    case 'BLINKIT':
      return const Color(0xFF1DA462); // Blinkit green
    default:
      return AppColors.accent;
  }
}

class ClientSelectScreen extends StatefulWidget {
  const ClientSelectScreen({super.key});

  @override
  State<ClientSelectScreen> createState() => _ClientSelectScreenState();
}

class _ClientSelectScreenState extends State<ClientSelectScreen> {
  List<_Client> _clients = [];
  int? _selectedId;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchClients();
  }

  Future<void> _fetchClients() async {
    try {
      final res = await http.get(
        Uri.parse('${AppConstants.apiBaseUrl}/clients'),
        headers: {'Content-Type': 'application/json'},
      );
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        // Backend wraps in { data: [...] } or returns array directly
        final List raw = json['data'] is List
            ? json['data']
            : json is List
                ? json
                : [];
        setState(() {
          _clients = raw.map((e) => _Client.fromJson(e)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load clients. Please try again.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Network error. Check connection.';
        _isLoading = false;
      });
    }
  }

  Future<void> _onConfirm() async {
    if (_selectedId == null) return;
    HapticFeedback.mediumImpact();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token != null) {
        await http.post(
          Uri.parse('${AppConstants.apiBaseUrl}/riders/select-client'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({'client_id': _selectedId}),
        );
      }
    } catch (_) {}

    if (!mounted) return;
    Navigator.pushNamed(context, '/documents');
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
    if (_error != null) {
      return NoInternetWidget(
        title: 'Choose Client',
        showLogout: true,
        onLogout: _logout,
        onRetry: () {
          setState(() {
            _isLoading = true;
            _error = null;
          });
          _fetchClients();
        },
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      body: Column(
        children: [
          // ── TOP HEADER — Same indigo as other screens ─────────────
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
                      child: Text(
                        'Choose your client',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
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

          // ── BODY ─────────────────────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.accent),
                  )
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                        children: [
                          // Heading + subtitle
                          Text(
                            'Choose who you want to work with',
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF111827),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'You can add more clients later',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Client Cards
                          ..._clients.map((client) {
                            final isSelected = _selectedId == client.id;
                            final color = _clientColor(client.code);
                            return GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() => _selectedId = client.id);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.only(bottom: 14),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.accent
                                        : const Color(0xFFE5E7EB),
                                    width: isSelected ? 2 : 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isSelected
                                          ? AppColors.accent.withOpacity(0.08)
                                          : Colors.black.withOpacity(0.04),
                                      blurRadius: isSelected ? 12 : 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    // Brand color dot
                                    Container(
                                      width: 42,
                                      height: 42,
                                      decoration: BoxDecoration(
                                        color: color,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          client.name[0],
                                          style: GoogleFonts.inter(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 18,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),

                                    // Client Info
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            client.name,
                                            style: GoogleFonts.inter(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              color: const Color(0xFF111827),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${client.payoutCycle[0].toUpperCase()}${client.payoutCycle.substring(1)} payout',
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              color: const Color(0xFF6B7280),
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          Row(
                                            children: [
                                              // Avg daily earning
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      '₹${client.avgDailyEarning.toStringAsFixed(0)}',
                                                      style: GoogleFonts.inter(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        color: const Color(
                                                            0xFF111827),
                                                      ),
                                                    ),
                                                    Text(
                                                      'avg. per day',
                                                      style: GoogleFonts.inter(
                                                        fontSize: 11,
                                                        color: const Color(
                                                            0xFF9CA3AF),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              // Divider
                                              Container(
                                                width: 1,
                                                height: 32,
                                                color: const Color(0xFFE5E7EB),
                                              ),
                                              const SizedBox(width: 12),
                                              // Rate per order
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      '₹${client.ratePerOrder.toStringAsFixed(0)}',
                                                      style: GoogleFonts.inter(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        color: const Color(
                                                            0xFF111827),
                                                      ),
                                                    ),
                                                    Text(
                                                      'per order',
                                                      style: GoogleFonts.inter(
                                                        fontSize: 11,
                                                        color: const Color(
                                                            0xFF9CA3AF),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Radio indicator
                                    const SizedBox(width: 8),
                                    AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      width: 22,
                                      height: 22,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isSelected
                                            ? AppColors.accent
                                            : Colors.transparent,
                                        border: Border.all(
                                          color: isSelected
                                              ? AppColors.accent
                                              : const Color(0xFFD1D5DB),
                                          width: 2,
                                        ),
                                      ),
                                      child: isSelected
                                          ? const Icon(Icons.check_rounded,
                                              color: Colors.white, size: 14)
                                          : null,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
          ),

          // ── CONFIRM BUTTON — Bottom ───────────────────────────────
          Container(
            color: AppColors.surfaceLight,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            child: GestureDetector(
              onTap: _selectedId == null ? null : _onConfirm,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: _selectedId == null
                      ? const Color(0xFFD1D5DB)
                      : AppColors.accent,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Center(
                  child: Text(
                    'Confirm & Continue',
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
}

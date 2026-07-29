import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/constants.dart';

class NoInternetWidget extends StatelessWidget {
  final String title;
  final VoidCallback onRetry;
  final bool showBackButton;
  final bool showLogout;
  final VoidCallback? onLogout;

  const NoInternetWidget({
    super.key,
    required this.title,
    required this.onRetry,
    this.showBackButton = true,
    this.showLogout = false,
    this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      body: Column(
        children: [
          // ── TOP HEADER — Dynamic title matching current screen ────
          Container(
            color: AppColors.accent,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                child: Row(
                  children: [
                    if (showBackButton)
                      IconButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white, size: 20),
                      )
                    else
                      const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (showLogout && onLogout != null)
                      IconButton(
                        tooltip: 'Logout',
                        onPressed: onLogout,
                        icon: const Icon(Icons.logout_rounded,
                            color: Colors.white, size: 22),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // ── CENTER BODY — Exact Match with Image Mockup ──────────
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Satellite Dish Icon Container
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          Icons.satellite_alt_rounded,
                          size: 48,
                          color: AppColors.accent.withOpacity(0.85),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // No Internet Connection Heading
                    Text(
                      'No internet connection',
                      style: GoogleFonts.inter(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF111827),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Progress is saved message
                    Text(
                      'Check your connection and try again. Your progress is saved.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF6B7280),
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Retry Pill Button
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        onRetry();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 48, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(50),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accent.withOpacity(0.25),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          'Retry',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

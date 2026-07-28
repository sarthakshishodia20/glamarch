import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  State<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen>
    with SingleTickerProviderStateMixin {
  String _selectedCode = ''; // 'en' or 'hi'

  // Only English & Hindi in Phase 1
  final List<Map<String, String>> _languages = [
    {'code': 'en', 'name': 'English', 'sub': 'English'},
    {'code': 'hi', 'name': 'हिंदी', 'sub': 'Hindi'},
  ];

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();

    // Restore previously selected language if user comes back
    _restoreSaved();
  }

  Future<void> _restoreSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('language') ?? '';
    if (saved.isNotEmpty) {
      setState(() => _selectedCode = saved);
    }
  }

  Future<void> _onContinue() async {
    if (_selectedCode.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', _selectedCode);
    if (!mounted) return;
    // Navigate to Screen 2: Registration
    // Navigator.pushNamed(context, '/register');
    // Placeholder until next screen is built:
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _selectedCode == 'hi'
              ? 'भाषा सेव हो गई! अगली स्क्रीन जल्द आएगी।'
              : 'Language saved! Next screen coming soon.',
        ),
        backgroundColor: AppColors.accent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: size.height * 0.08),

                  // ── GLAM Logo Circle ──────────────────────────────────
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'GLAM',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── Heading ───────────────────────────────────────────
                  Text(
                    'Choose your language',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 10),

                  // ── Subtitle: Script examples ─────────────────────────
                  Text(
                    'अपनी भाषा चुनें',
                    style: GoogleFonts.inter(
                      color: Colors.white.withOpacity(0.55),
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                    ),
                  ),

                  SizedBox(height: size.height * 0.06),

                  // ── Language Option Cards ─────────────────────────────
                  ...List.generate(_languages.length, (i) {
                    final lang = _languages[i];
                    final isSelected = _selectedCode == lang['code'];
                    return GestureDetector(
                      onTap: () => setState(() => _selectedCode = lang['code']!),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        margin: const EdgeInsets.only(bottom: 14),
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 18,
                          horizontal: 20,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.accent
                              : Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.accent
                                : Colors.white.withOpacity(0.15),
                            width: 1.5,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppColors.accent.withOpacity(0.35),
                                    blurRadius: 14,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : [],
                        ),
                        child: Row(
                          children: [
                            // Radio circle indicator
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.transparent,
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.white.withOpacity(0.4),
                                  width: 2,
                                ),
                              ),
                              child: isSelected
                                  ? Center(
                                      child: Container(
                                        width: 10,
                                        height: 10,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: AppColors.accent,
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            // Language label
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  lang['name']!,
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (lang['sub'] != lang['name']) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    lang['sub']!,
                                    style: GoogleFonts.inter(
                                      color: Colors.white.withOpacity(0.6),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                  const Spacer(),

                  // ── Continue Button ───────────────────────────────────
                  AnimatedOpacity(
                    opacity: _selectedCode.isEmpty ? 0.45 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: GestureDetector(
                      onTap: _selectedCode.isEmpty ? null : _onContinue,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: _selectedCode.isEmpty
                              ? Colors.white.withOpacity(0.2)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Text(
                            _selectedCode == 'hi'
                                ? 'जारी रखें  /  Continue'
                                : 'Continue  /  जारी रखें',
                            style: GoogleFonts.inter(
                              color: _selectedCode.isEmpty
                                  ? Colors.white
                                  : AppColors.primary,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 36),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

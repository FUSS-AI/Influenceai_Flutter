import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

/// Persona preset for the setup screen.
class _Preset {
  final String id;
  final String name;
  final String tagline;
  final String emoji;
  final Color accentColor;

  const _Preset({
    required this.id,
    required this.name,
    required this.tagline,
    required this.emoji,
    required this.accentColor,
  });
}

/// Persona selection screen — glassmorphic redesign.
///
/// Features a scrollable list of frosted-glass persona cards,
/// an expandable advanced-options drawer, and a glowing CTA button.
class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen>
    with SingleTickerProviderStateMixin {
  final _api = ApiService();

  static const _presets = [
    _Preset(
      id: 'vlog_star',
      name: 'Vlog Star',
      tagline: 'Trendy lifestyle creator',
      emoji: '⭐',
      accentColor: Color(0xFFFFD166),
    ),
    _Preset(
      id: 'fitness_guru',
      name: 'Fitness Guru',
      tagline: 'Health & wellness coach',
      emoji: '💪',
      accentColor: Color(0xFF00D4AA),
    ),
    _Preset(
      id: 'tech_bro',
      name: 'Tech Influencer',
      tagline: 'Silicon Valley vibes',
      emoji: '🚀',
      accentColor: Color(0xFF7C5CFC),
    ),
    _Preset(
      id: 'custom',
      name: 'Custom',
      tagline: 'Enter your own ID',
      emoji: '🎛️',
      accentColor: Color(0xFFFF6B9D),
    ),
  ];

  String _selectedId = 'vlog_star';
  final _customIdController = TextEditingController();
  final _userIdController = TextEditingController();
  final _instructionsController = TextEditingController();
  bool _showAdvanced = false;
  bool _isLoading = false;
  String? _errorMessage;

  late AnimationController _btnPulseCtrl;
  late Animation<double> _btnPulse;

  String get _effectiveId =>
      _selectedId == 'custom' ? _customIdController.text.trim() : _selectedId;

  bool get _canStart => !_isLoading && _effectiveId.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _btnPulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _btnPulse = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _btnPulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _btnPulseCtrl.dispose();
    _customIdController.dispose();
    _userIdController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  Future<void> _startSession() async {
    if (!_canStart) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final session = await _api.createSession(
        _effectiveId,
        userId: _userIdController.text.trim().isEmpty
            ? null
            : _userIdController.text.trim(),
        instructionsOverride: _instructionsController.text.trim().isEmpty
            ? null
            : _instructionsController.text.trim(),
      );

      if (mounted) {
        Navigator.pushNamed(context, '/session', arguments: {
          'session': session,
          'personaName': _selectedId == 'custom'
              ? _customIdController.text.trim()
              : _presets.firstWhere((p) => p.id == _selectedId).name,
          'personaEmoji': _selectedId == 'custom'
              ? '🤖'
              : _presets.firstWhere((p) => p.id == _selectedId).emoji,
        });
      }
    } on ApiError catch (e) {
      setState(() =>
          _errorMessage = 'Server error (${e.statusCode}): ${e.message}');
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060B18),
      body: Stack(
        children: [
          // ── Mesh gradient background ──────────────────────────────────
          Positioned(
            top: -150,
            left: -100,
            child: Container(
              width: 600,
              height: 600,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF7C5CFC).withValues(alpha: 0.15),
                    const Color(0xFF7C5CFC).withValues(alpha: 0.05),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -120,
            right: -80,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF00D4AA).withValues(alpha: 0.12),
                    const Color(0xFF00D4AA).withValues(alpha: 0.03),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.4,
            right: -60,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFF6B9D).withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ── Main content ──────────────────────────────────────────────
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Header badge ──
                      Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.1),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: const Color(0xFF00D4AA),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF00D4AA)
                                              .withValues(alpha: 0.6),
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'InfluenceAI Voice SDK',
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white.withValues(alpha: 0.7),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // ── Title ──
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [
                            Color(0xFFFFFFFF),
                            Color(0xFFB8A4FF),
                          ],
                        ).createShader(bounds),
                        child: Text(
                          'Select Your\nAI Persona',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.15,
                            letterSpacing: -1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Choose an influencer to start a live voice session',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.35),
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // ── Persona cards (vertical list) ──
                      ..._presets.map((p) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _buildPresetCard(p),
                          )),
                      const SizedBox(height: 8),

                      // ── Custom influencer ID ──
                      if (_selectedId == 'custom') ...[
                        _buildGlassTextField(
                          controller: _customIdController,
                          label: 'Influencer ID',
                          placeholder: 'e.g. vlog_star',
                        ),
                        const SizedBox(height: 12),
                      ],

                      // ── Advanced options toggle ──
                      GestureDetector(
                        onTap: () =>
                            setState(() => _showAdvanced = !_showAdvanced),
                        child: Row(
                          children: [
                            AnimatedRotation(
                              turns: _showAdvanced ? 0.25 : 0.0,
                              duration: const Duration(milliseconds: 200),
                              child: Icon(
                                Icons.chevron_right,
                                size: 16,
                                color: Colors.white.withValues(alpha: 0.25),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Advanced options',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.25),
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ── Expandable advanced drawer ──
                      AnimatedCrossFade(
                        firstChild: const SizedBox.shrink(),
                        secondChild: Padding(
                          padding: const EdgeInsets.only(top: 14),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: BackdropFilter(
                              filter:
                                  ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.04),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color:
                                        Colors.white.withValues(alpha: 0.08),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    _buildGlassTextField(
                                      controller: _userIdController,
                                      label: 'User ID (optional)',
                                      placeholder: 'user_abc123',
                                    ),
                                    const SizedBox(height: 12),
                                    _buildGlassTextField(
                                      controller: _instructionsController,
                                      label: 'Instructions override',
                                      placeholder:
                                          'Override the system prompt…',
                                      maxLines: 3,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        crossFadeState: _showAdvanced
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                        duration: const Duration(milliseconds: 300),
                      ),

                      const SizedBox(height: 24),

                      // ── Error ──
                      if (_errorMessage != null) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF6B6B)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: const Color(0xFFFF6B6B)
                                        .withValues(alpha: 0.25)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.warning_amber_rounded,
                                      size: 14, color: Color(0xFFFF6B6B)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        color: const Color(0xFFFF6B6B),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // ── Start button with pulsing glow ──
                      AnimatedBuilder(
                        animation: _btnPulse,
                        builder: (_, __) => GestureDetector(
                          onTap: _canStart ? _startSession : null,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              gradient: _canStart
                                  ? const LinearGradient(
                                      colors: [
                                        Color(0xFF7C5CFC),
                                        Color(0xFF5B3FD4),
                                      ],
                                    )
                                  : null,
                              color: _canStart
                                  ? null
                                  : Colors.white.withValues(alpha: 0.04),
                              boxShadow: _canStart
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF7C5CFC)
                                            .withValues(
                                                alpha:
                                                    0.2 +
                                                        _btnPulse.value * 0.25),
                                        blurRadius:
                                            20 + _btnPulse.value * 20,
                                        offset: const Offset(0, 6),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (_isLoading)
                                  const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                else
                                  Icon(
                                    Icons.graphic_eq_rounded,
                                    size: 18,
                                    color: _canStart
                                        ? Colors.white
                                        : Colors.white
                                            .withValues(alpha: 0.2),
                                  ),
                                const SizedBox(width: 10),
                                Text(
                                  _isLoading
                                      ? 'Connecting…'
                                      : 'Start Voice Session',
                                  style: GoogleFonts.outfit(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: _canStart
                                        ? Colors.white
                                        : Colors.white
                                            .withValues(alpha: 0.2),
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Build helpers ─────────────────────────────────────────────────────────

  Widget _buildPresetCard(_Preset preset) {
    final isSelected = _selectedId == preset.id;
    return GestureDetector(
      onTap: () => setState(() => _selectedId = preset.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: isSelected ? 16 : 8,
              sigmaY: isSelected ? 16 : 8,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: isSelected
                    ? preset.accentColor.withValues(alpha: 0.1)
                    : Colors.white.withValues(alpha: 0.04),
                border: Border.all(
                  color: isSelected
                      ? preset.accentColor.withValues(alpha: 0.4)
                      : Colors.white.withValues(alpha: 0.06),
                  width: isSelected ? 1.5 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: preset.accentColor.withValues(alpha: 0.15),
                          blurRadius: 30,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  // Emoji avatar circle
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: preset.accentColor.withValues(alpha: 0.12),
                      border: Border.all(
                        color: preset.accentColor.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Center(
                      child: Text(preset.emoji,
                          style: const TextStyle(fontSize: 22)),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Name + tagline
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          preset.name,
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          preset.tagline,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Selection indicator
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? preset.accentColor
                          : Colors.white.withValues(alpha: 0.06),
                      border: Border.all(
                        color: isSelected
                            ? preset.accentColor
                            : Colors.white.withValues(alpha: 0.15),
                        width: 2,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color:
                                    preset.accentColor.withValues(alpha: 0.5),
                                blurRadius: 12,
                              ),
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, size: 13, color: Colors.white)
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassTextField({
    required TextEditingController controller,
    required String label,
    required String placeholder,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.45),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: GoogleFonts.outfit(fontSize: 13, color: Colors.white),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: GoogleFonts.outfit(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.2),
            ),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  BorderSide(color: Colors.white.withValues(alpha: 0.08)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  BorderSide(color: Colors.white.withValues(alpha: 0.08)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                  color: const Color(0xFF7C5CFC).withValues(alpha: 0.5)),
            ),
          ),
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }
}

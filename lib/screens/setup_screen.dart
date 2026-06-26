import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

/// Persona preset for the setup screen.
class _Preset {
  final String id;
  final String name;
  final String tagline;
  final String emoji;

  const _Preset({
    required this.id,
    required this.name,
    required this.tagline,
    required this.emoji,
  });
}

/// Persona selection screen — mirrors Vue `SetupView.vue`.
///
/// Lets the user pick a persona, optionally enter a custom influencer ID,
/// user ID, and instructions override, then creates a session and navigates
/// to the voice call screen.
class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _api = ApiService();

  static const _presets = [
    _Preset(
      id: 'vlog_star',
      name: 'Vlog Star',
      tagline: 'Trendy lifestyle creator',
      emoji: '⭐',
    ),
    _Preset(
      id: 'fitness_guru',
      name: 'Fitness Guru',
      tagline: 'Health & wellness coach',
      emoji: '💪',
    ),
    _Preset(
      id: 'tech_bro',
      name: 'Tech Influencer',
      tagline: 'Silicon Valley vibes',
      emoji: '🚀',
    ),
    _Preset(
      id: 'custom',
      name: 'Custom',
      tagline: 'Enter your own influencer ID',
      emoji: '🎛️',
    ),
  ];

  String _selectedId = 'vlog_star';
  final _customIdController = TextEditingController();
  final _userIdController = TextEditingController();
  final _instructionsController = TextEditingController();
  bool _showAdvanced = false;
  bool _isLoading = false;
  String? _errorMessage;

  String get _effectiveId =>
      _selectedId == 'custom' ? _customIdController.text.trim() : _selectedId;

  bool get _canStart =>
      !_isLoading && _effectiveId.isNotEmpty;

  @override
  void dispose() {
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
      backgroundColor: const Color(0xFF0A0A0F),
      body: Stack(
        children: [
          // ── Ambient background glows ──────────────────────────────────
          Positioned(
            top: -100,
            left: -50,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            right: -30,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF06B6D4).withValues(alpha: 0.08),
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
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Header badge ──
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color:
                                  const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFF8B5CF6),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'InfluenceAI Voice Client',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF8B5CF6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Title ──
                      Text(
                        'Choose a Persona',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Select an AI influencer to start a live voice session',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.4),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // ── Persona cards (2×2 grid) ──
                      GridView.count(
                        crossAxisCount: 2,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 2.0,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: _presets.map(_buildPresetCard).toList(),
                      ),
                      const SizedBox(height: 16),

                      // ── Custom influencer ID ──
                      if (_selectedId == 'custom') ...[
                        _buildTextField(
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
                            Icon(
                              _showAdvanced
                                  ? Icons.keyboard_arrow_down
                                  : Icons.chevron_right,
                              size: 14,
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Advanced options',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.3),
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (_showAdvanced) ...[
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: _userIdController,
                          label: 'User ID (optional — blank auto-generates)',
                          placeholder: 'user_abc123',
                        ),
                        const SizedBox(height: 10),
                        _buildTextField(
                          controller: _instructionsController,
                          label: 'Instructions override (optional)',
                          placeholder: 'Override the persona\'s system prompt…',
                          maxLines: 3,
                        ),
                      ],

                      const SizedBox(height: 20),

                      // ── Error ──
                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.red.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded,
                                  size: 14, color: Colors.redAccent),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: Colors.redAccent,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // ── Start button ──
                      GestureDetector(
                        onTap: _canStart ? _startSession : null,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: _canStart
                                ? const Color(0xFF8B5CF6)
                                : Colors.white.withValues(alpha: 0.05),
                            boxShadow: _canStart
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF8B5CF6)
                                          .withValues(alpha: 0.35),
                                      blurRadius: 24,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_isLoading)
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              else
                                Icon(
                                  Icons.mic,
                                  size: 16,
                                  color: _canStart
                                      ? Colors.white
                                      : Colors.white.withValues(alpha: 0.25),
                                ),
                              const SizedBox(width: 8),
                              Text(
                                _isLoading
                                    ? 'Creating session…'
                                    : 'Start Voice Session',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _canStart
                                      ? Colors.white
                                      : Colors.white.withValues(alpha: 0.25),
                                ),
                              ),
                            ],
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
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isSelected
              ? const Color(0xFF8B5CF6).withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.03),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF8B5CF6).withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.08),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                    blurRadius: 20,
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(preset.emoji,
                    style: const TextStyle(fontSize: 24, height: 1)),
                const SizedBox(height: 6),
                Text(
                  preset.name,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  preset.tagline,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            if (isSelected)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF8B5CF6),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
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
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.25),
            ),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.5)),
            ),
          ),
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }
}

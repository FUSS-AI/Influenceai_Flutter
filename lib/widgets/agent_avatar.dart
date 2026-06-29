import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Animated avatar widget with layered glowing aura based on agent state.
///
/// Enhanced design with multi-ring glow effects, gradient overlays,
/// and smooth state transitions for a premium feel.
class AgentAvatar extends StatefulWidget {
  /// Current agent state: `idle`, `listening`, `thinking`, `speaking`, `blocked`.
  final String agentState;

  /// Persona display name.
  final String personaName;

  /// Emoji to display inside the avatar.
  final String emoji;

  /// Avatar size (diameter).
  final double size;

  const AgentAvatar({
    super.key,
    required this.agentState,
    required this.personaName,
    this.emoji = '🤖',
    this.size = 180,
  });

  @override
  State<AgentAvatar> createState() => _AgentAvatarState();
}

class _AgentAvatarState extends State<AgentAvatar>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _ringController;
  late AnimationController _glowController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _ringAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _ringAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ringController, curve: Curves.easeOut),
    );

    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _ringController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  Color get _stateColor {
    switch (widget.agentState) {
      case 'listening':
        return const Color(0xFF00D4AA); // neon mint
      case 'thinking':
        return const Color(0xFF60A5FA); // sky blue
      case 'speaking':
        return const Color(0xFFA78BFA); // lavender
      case 'blocked':
        return const Color(0xFFFF6B6B); // coral red
      default:
        return const Color(0xFF7C5CFC).withValues(alpha: 0.3); // dim indigo
    }
  }

  Color get _secondaryColor {
    switch (widget.agentState) {
      case 'listening':
        return const Color(0xFF00B894);
      case 'thinking':
        return const Color(0xFF7C5CFC);
      case 'speaking':
        return const Color(0xFFFF6B9D);
      case 'blocked':
        return const Color(0xFFFF8E8E);
      default:
        return const Color(0xFF5B3FD4);
    }
  }

  String get _stateLabel {
    switch (widget.agentState) {
      case 'listening':
        return 'Listening';
      case 'thinking':
        return 'Processing…';
      case 'speaking':
        return 'Speaking';
      case 'blocked':
        return 'Blocked';
      default:
        return 'Connected';
    }
  }

  IconData get _stateIcon {
    switch (widget.agentState) {
      case 'listening':
        return Icons.hearing;
      case 'thinking':
        return Icons.auto_awesome;
      case 'speaking':
        return Icons.graphic_eq_rounded;
      case 'blocked':
        return Icons.block;
      default:
        return Icons.circle;
    }
  }

  bool get _isActive =>
      widget.agentState == 'speaking' ||
      widget.agentState == 'listening' ||
      widget.agentState == 'thinking';

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Avatar with layered glow aura ─────────────────────────────
        SizedBox(
          width: widget.size + 50,
          height: widget.size + 50,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Layer 1: Outer ambient glow
              if (_isActive)
                AnimatedBuilder(
                  animation: _glowAnimation,
                  builder: (_, __) => Container(
                    width: widget.size + 70,
                    height: widget.size + 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _stateColor.withValues(
                              alpha: 0.15 * _glowAnimation.value),
                          blurRadius: 80,
                          spreadRadius: 20,
                        ),
                        BoxShadow(
                          color: _secondaryColor.withValues(
                              alpha: 0.08 * _glowAnimation.value),
                          blurRadius: 100,
                          spreadRadius: 40,
                        ),
                      ],
                    ),
                  ),
                ),

              // Layer 2: Expanding rings (3 staggered)
              if (_isActive) ...[
                AnimatedBuilder(
                  animation: _ringAnimation,
                  builder: (_, __) => _buildRing(
                    scale: 1.0 + _ringAnimation.value * 0.35,
                    opacity: (1.0 - _ringAnimation.value) * 0.3,
                  ),
                ),
                AnimatedBuilder(
                  animation: _ringAnimation,
                  builder: (_, __) => _buildRing(
                    scale:
                        1.0 + ((_ringAnimation.value + 0.33) % 1.0) * 0.35,
                    opacity:
                        (1.0 - ((_ringAnimation.value + 0.33) % 1.0)) * 0.2,
                  ),
                ),
                AnimatedBuilder(
                  animation: _ringAnimation,
                  builder: (_, __) => _buildRing(
                    scale:
                        1.0 + ((_ringAnimation.value + 0.66) % 1.0) * 0.35,
                    opacity:
                        (1.0 - ((_ringAnimation.value + 0.66) % 1.0)) * 0.15,
                  ),
                ),
              ],

              // Layer 3: Inner glow ring (speaking)
              if (widget.agentState == 'speaking')
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (_, __) => Container(
                    width: widget.size + 16,
                    height: widget.size + 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          _stateColor.withValues(
                              alpha: 0.25 * _pulseAnimation.value),
                          _secondaryColor.withValues(
                              alpha: 0.15 * _pulseAnimation.value),
                        ],
                      ),
                    ),
                  ),
                ),

              // Layer 4: Main avatar circle
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (_, child) => Transform.scale(
                  scale: _isActive ? _pulseAnimation.value : 1.0,
                  child: child,
                ),
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF0D1527),
                        const Color(0xFF111B30),
                      ],
                    ),
                    border: Border.all(
                      color: _stateColor.withValues(alpha: 0.35),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                      if (_isActive)
                        BoxShadow(
                          color: _stateColor.withValues(alpha: 0.2),
                          blurRadius: 40,
                        ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Emoji
                      Text(
                        widget.emoji,
                        style: TextStyle(fontSize: widget.size * 0.32),
                      ),
                      // Gradient overlay when active
                      if (_isActive)
                        Positioned.fill(
                          child: AnimatedBuilder(
                            animation: _pulseController,
                            builder: (_, __) => DecoratedBox(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    _stateColor.withValues(
                                        alpha:
                                            0.2 * _pulseAnimation.value),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // ── State badge (pill) ────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: _stateColor.withValues(alpha: 0.1),
            border: Border.all(
              color: _stateColor.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _AnimatedDot(color: _stateColor),
              const SizedBox(width: 6),
              Icon(
                _stateIcon,
                size: 12,
                color: _stateColor.withValues(alpha: 0.8),
              ),
              const SizedBox(width: 5),
              Text(
                _stateLabel,
                style: GoogleFonts.outfit(
                  color: _stateColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 6),

        // ── Name ─────────────────────────────────────────────────────
        Text(
          widget.personaName,
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          'AI Voice Agent',
          style: GoogleFonts.outfit(
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.3),
            letterSpacing: 0.3,
          ),
        ),
      ],
      ),
    );
  }

  Widget _buildRing({required double scale, required double opacity}) {
    return Transform.scale(
      scale: scale,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: _stateColor.withValues(alpha: opacity),
            width: 1.5,
          ),
        ),
      ),
    );
  }
}

// ── Animated dot ──────────────────────────────────────────────────────────────

class _AnimatedDot extends StatefulWidget {
  final Color color;
  const _AnimatedDot({required this.color});

  @override
  State<_AnimatedDot> createState() => _AnimatedDotState();
}

class _AnimatedDotState extends State<_AnimatedDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) => Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color.withValues(alpha: 0.5 + _controller.value * 0.5),
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: 0.4 * _controller.value),
              blurRadius: 8,
            ),
          ],
        ),
      ),
    );
  }
}

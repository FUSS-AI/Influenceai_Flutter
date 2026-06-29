import 'package:flutter/material.dart';

/// Animated avatar widget with pulsing rings based on agent state.
///
/// Mirrors the avatar section of the Vue `SessionRoom.vue` template.
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
  late Animation<double> _pulseAnimation;
  late Animation<double> _ringAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _ringAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ringController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _ringController.dispose();
    super.dispose();
  }

  Color get _stateColor {
    switch (widget.agentState) {
      case 'listening':
        return const Color(0xFF4ADE80); // green
      case 'thinking':
        return const Color(0xFF60A5FA); // blue
      case 'speaking':
        return const Color(0xFFA78BFA); // purple
      case 'blocked':
        return const Color(0xFFF87171); // red
      default:
        return Colors.white24;
    }
  }

  String get _stateLabel {
    switch (widget.agentState) {
      case 'listening':
        return 'Listening';
      case 'thinking':
        return 'Thinking…';
      case 'speaking':
        return 'Speaking';
      case 'blocked':
        return 'Blocked 🚫';
      default:
        return 'Connected';
    }
  }

  bool get _isActive =>
      widget.agentState == 'speaking' ||
      widget.agentState == 'listening' ||
      widget.agentState == 'thinking';

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Avatar with animated rings ────────────────────────────────
        SizedBox(
          width: widget.size + 40,
          height: widget.size + 40,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Pulsing rings (only when active)
              if (_isActive) ...[
                AnimatedBuilder(
                  animation: _ringAnimation,
                  builder: (_, __) => _buildRing(
                    scale: 1.0 + _ringAnimation.value * 0.3,
                    opacity: (1.0 - _ringAnimation.value) * 0.4,
                  ),
                ),
                AnimatedBuilder(
                  animation: _ringAnimation,
                  builder: (_, __) => _buildRing(
                    scale: 1.0 + ((_ringAnimation.value + 0.5) % 1.0) * 0.3,
                    opacity:
                        (1.0 - ((_ringAnimation.value + 0.5) % 1.0)) * 0.25,
                  ),
                ),
              ],

              // Glow effect when speaking
              if (widget.agentState == 'speaking')
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (_, __) => Container(
                    width: widget.size + 20,
                    height: widget.size + 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _stateColor
                              .withValues(alpha: 0.4 * _pulseAnimation.value),
                          blurRadius: 60,
                          spreadRadius: 20,
                        ),
                      ],
                    ),
                  ),
                ),

              // Main avatar circle
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
                    color: Colors.white.withValues(alpha: 0.05),
                    border: Border.all(
                      color: _stateColor.withValues(alpha: 0.4),
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(
                        widget.emoji,
                        style: TextStyle(fontSize: widget.size * 0.35),
                      ),
                      // Gradient overlay when speaking
                      if (widget.agentState == 'speaking')
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
                                        alpha: 0.3 * _pulseAnimation.value),
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

        const SizedBox(height: 16),

        // ── State badge ───────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated dot
              _AnimatedDot(color: _stateColor),
              const SizedBox(width: 6),
              Text(
                _stateLabel,
                style: TextStyle(
                  color: _stateColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // ── Name ──────────────────────────────────────────────────────
        Text(
          widget.personaName,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'AI Voice Agent',
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withValues(alpha: 0.4),
          ),
        ),
      ],
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
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color.withValues(alpha: 0.5 + _controller.value * 0.5),
        ),
      ),
    );
  }
}



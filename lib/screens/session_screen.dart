import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../services/voice_session.dart';
import '../widgets/agent_avatar.dart';

/// Immersive voice call screen.
///
/// The agent avatar is the full-screen centrepiece. The transcript floats as a
/// translucent glass overlay at the bottom. Controls sit in a floating dock.
class SessionScreen extends StatefulWidget {
  const SessionScreen({super.key});

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  late VoiceSession _session;
  final _scrollController = ScrollController();
  final _api = ApiService();

  late String _personaName;
  late String _personaEmoji;
  late Map<String, dynamic> _sessionDetails;

  bool _isLeaving = false;
  bool _didConnect = false;
  bool _transcriptExpanded = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didConnect) {
      final args =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      _sessionDetails = args['session'] as Map<String, dynamic>;
      _personaName = args['personaName'] as String;
      _personaEmoji = (args['personaEmoji'] as String?) ?? '🤖';

      _session = VoiceSession();
      _session.addListener(_onSessionChanged);
      _connectToRoom();
      _didConnect = true;
    }
  }

  Future<void> _connectToRoom() async {
    try {
      await _session.connect(
        _sessionDetails['livekit_url'] as String,
        _sessionDetails['token'] as String,
      );
    } catch (_) {
      // Error is surfaced via _session.error
    }
  }

  void _onSessionChanged() {
    if (mounted) {
      setState(() {});
      // Auto-scroll transcript to bottom
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  Future<void> _handleLeave() async {
    if (_isLeaving) return;
    setState(() => _isLeaving = true);
    try {
      await _session.disconnect();
      await _api.endSession(_sessionDetails['session_id'] as String);
    } catch (_) {
      // best-effort
    } finally {
      _session.removeListener(_onSessionChanged);
      _session.dispose();
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060B18),
      body: Stack(
        children: [
          // ── Ambient mesh gradients ─────────────────────────────────
          Positioned(
            top: -100,
            left: MediaQuery.of(context).size.width * 0.15,
            child: Container(
              width: 600,
              height: 600,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF7C5CFC).withValues(alpha: 0.18),
                    const Color(0xFF7C5CFC).withValues(alpha: 0.04),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            right: -50,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF00D4AA).withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ── Main content ──────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),

                // Connection error banner
                if (_session.error != null) _buildErrorBanner(),

                // Immersive body — avatar centred, transcript floating
                Expanded(
                  child: Stack(
                    children: [
                      // ── Centred avatar ──────────────────────────────
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        bottom: _transcriptExpanded ? 260 : 60,
                        child: Center(
                          child: AgentAvatar(
                            agentState: _session.agentState,
                            personaName: _personaName,
                            emoji: _personaEmoji,
                            size: MediaQuery.of(context).size.width > 700
                                ? 180
                                : 130,
                          ),
                        ),
                      ),

                      // ── Floating transcript overlay ────────────────
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 8,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: _transcriptExpanded ? 220 : 44,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: BackdropFilter(
                              filter:
                                  ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0D1527)
                                      .withValues(alpha: 0.75),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color:
                                        Colors.white.withValues(alpha: 0.08),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    // Toolbar
                                    GestureDetector(
                                      onTap: () => setState(() =>
                                          _transcriptExpanded =
                                              !_transcriptExpanded),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 10),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.chat_bubble_outline,
                                              size: 14,
                                              color: const Color(0xFF7C5CFC)
                                                  .withValues(alpha: 0.7),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Live Transcript',
                                              style: GoogleFonts.outfit(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white
                                                    .withValues(alpha: 0.6),
                                              ),
                                            ),
                                            const Spacer(),
                                            if (_session.transcript.isNotEmpty)
                                              GestureDetector(
                                                onTap: _session.clearTranscript,
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                  decoration: BoxDecoration(
                                                    borderRadius: BorderRadius.circular(10),
                                                    color: Colors.white.withValues(alpha: 0.05),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(Icons.close, size: 11, color: Colors.white.withValues(alpha: 0.3)),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        'Clear',
                                                        style: GoogleFonts.outfit(
                                                          fontSize: 11,
                                                          color: Colors.white.withValues(alpha: 0.3),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            const SizedBox(width: 8),
                                            Text(
                                              '${_session.transcript.length}',
                                              style: GoogleFonts.outfit(
                                                fontSize: 11,
                                                color: Colors.white
                                                    .withValues(alpha: 0.3),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            AnimatedRotation(
                                              turns: _transcriptExpanded
                                                  ? 0.5
                                                  : 0.0,
                                              duration: const Duration(
                                                  milliseconds: 200),
                                              child: Icon(
                                                Icons.keyboard_arrow_up,
                                                size: 18,
                                                color: Colors.white
                                                    .withValues(alpha: 0.3),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                    // Messages
                                    if (_transcriptExpanded)
                                      Expanded(
                                        child:
                                            _session.transcript.isEmpty
                                                ? _buildEmptyTranscript()
                                                : ListView.builder(
                                                    controller:
                                                        _scrollController,
                                                    padding:
                                                        const EdgeInsets
                                                            .symmetric(
                                                            horizontal: 14,
                                                            vertical: 4),
                                                    itemCount: _session
                                                            .transcript
                                                            .length +
                                                        (_isThinkingOrSpeaking
                                                            ? 1
                                                            : 0),
                                                    itemBuilder:
                                                        (context, index) {
                                                      if (index ==
                                                          _session.transcript
                                                              .length) {
                                                        return _buildTypingIndicator();
                                                      }
                                                      return _buildMessageBubble(
                                                          _session.transcript[
                                                              index]);
                                                    },
                                                  ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Floating control dock ───────────────────────────
                _buildControlDock(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool get _isThinkingOrSpeaking =>
      _session.agentState == 'thinking' || _session.agentState == 'speaking';

  // ── Header ──────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    final stateInfo = _getStateInfo();
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            border: Border(
              bottom:
                  BorderSide(color: Colors.white.withValues(alpha: 0.05)),
            ),
          ),
          child: Row(
            children: [
              // End session
              GestureDetector(
                onTap: _isLeaving ? null : _handleLeave,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.white.withValues(alpha: 0.05),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.arrow_back_rounded,
                          size: 14,
                          color: Colors.white.withValues(alpha: 0.5)),
                      const SizedBox(width: 4),
                      Text(
                        'End',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),

              // Title + Live indicator
              Column(
                children: [
                  Text(
                    _personaName,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: stateInfo.$2,
                          boxShadow: [
                            BoxShadow(
                              color: stateInfo.$2.withValues(alpha: 0.6),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        stateInfo.$1,
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: stateInfo.$2.withValues(alpha: 0.8),
                          letterSpacing: 0.3,
                        ),
                      ),
                      if (_session.connectionState == 'connected') ...[
                        const SizedBox(width: 8),
                        Text(
                          '•',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.3),
                              fontSize: 10),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _session.duration,
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.5),
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              const Spacer(),

              // Loading spinner when leaving
              SizedBox(
                width: 70,
                child: _isLeaving
                    ? const Align(
                        alignment: Alignment.centerRight,
                        child: SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white24,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Error banner ────────────────────────────────────────────────────────

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: const Color(0xFFFF6B6B).withValues(alpha: 0.1),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              size: 14, color: Color(0xFFFF6B6B)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _session.error!,
              style: GoogleFonts.outfit(
                  fontSize: 12, color: const Color(0xFFFF6B6B)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Floating control dock ───────────────────────────────────────────────

  Widget _buildControlDock() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24, top: 8),
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF0D1527).withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Mic button
                  _buildDockButton(
                    icon: _session.micEnabled ? Icons.mic : Icons.mic_off,
                    isActive: _session.micEnabled,
                    color: const Color(0xFF7C5CFC),
                    onTap: _session.toggleMic,
                  ),
                  const SizedBox(width: 8),

                  // Interrupt button (only visible when agent is speaking)
                  if (_session.agentState == 'speaking') ...[
                    _buildDockButton(
                      icon: Icons.stop_rounded,
                      isActive: true,
                      color: const Color(0xFFFFD166), // Warning yellow/orange
                      onTap: _session.interrupt,
                    ),
                    const SizedBox(width: 8),
                  ],

                  // End call button
                  _buildDockButton(
                    icon: Icons.call_end_rounded,
                    isActive: true,
                    color: const Color(0xFFFF6B6B),
                    onTap: _handleLeave,
                    isDestructive: true,
                  ),
                  const SizedBox(width: 8),

                  // Transcript toggle
                  _buildDockButton(
                    icon: Icons.subtitles_rounded,
                    isActive: _transcriptExpanded,
                    color: const Color(0xFF00D4AA),
                    onTap: () => setState(
                        () => _transcriptExpanded = !_transcriptExpanded),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDockButton({
    required IconData icon,
    required bool isActive,
    required Color color,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final bgColor = isActive || isDestructive
        ? color.withValues(alpha: 0.2)
        : Colors.white.withValues(alpha: 0.05);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(26),
        splashColor: color.withValues(alpha: 0.3),
        highlightColor: color.withValues(alpha: 0.1),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: bgColor,
            border: Border.all(
              color: isActive || isDestructive
                  ? color.withValues(alpha: 0.4)
                  : Colors.white.withValues(alpha: 0.1),
            ),
            boxShadow: isActive || isDestructive
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.25),
                      blurRadius: 16,
                    ),
                  ]
                : null,
          ),
          child: Icon(
            icon,
            size: 22,
            color: isActive || isDestructive
                ? color
                : Colors.white.withValues(alpha: 0.4),
          ),
        ),
      ),
    );
  }

  // ── Transcript helpers ──────────────────────────────────────────────────

  Widget _buildEmptyTranscript() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.graphic_eq_rounded,
              size: 24, color: Colors.white.withValues(alpha: 0.15)),
          const SizedBox(height: 8),
          Text(
            'Start speaking to see transcripts',
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(transcript) {
    final isUser = transcript.speaker == 'user';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF7C5CFC).withValues(alpha: 0.15),
              ),
              child: Center(
                child: Text(_personaEmoji,
                    style: const TextStyle(fontSize: 11)),
              ),
            ),
            const SizedBox(width: 6),
          ],

          Flexible(
            child: Container(
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.6),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isUser
                    ? const Color(0xFF00D4AA).withValues(alpha: 0.1)
                    : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(14),
                  topRight: const Radius.circular(14),
                  bottomLeft: isUser
                      ? const Radius.circular(14)
                      : const Radius.circular(4),
                  bottomRight: isUser
                      ? const Radius.circular(4)
                      : const Radius.circular(14),
                ),
                border: Border.all(
                  color: isUser
                      ? const Color(0xFF00D4AA).withValues(alpha: 0.15)
                      : Colors.white.withValues(alpha: 0.06),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isUser ? 'You' : _personaName,
                        style: GoogleFonts.outfit(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: isUser
                              ? const Color(0xFF00D4AA)
                                  .withValues(alpha: 0.7)
                              : const Color(0xFF7C5CFC)
                                  .withValues(alpha: 0.7),
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        transcript.timestamp,
                        style: GoogleFonts.outfit(
                          fontSize: 9,
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    transcript.text,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: Colors.white.withValues(
                          alpha: transcript.isFinal ? 0.85 : 0.5),
                      fontStyle: transcript.isBackchannel
                          ? FontStyle.italic
                          : FontStyle.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (isUser) ...[
            const SizedBox(width: 6),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF00D4AA).withValues(alpha: 0.15),
              ),
              child: Icon(Icons.mic,
                  size: 12,
                  color: const Color(0xFF00D4AA).withValues(alpha: 0.7)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.05),
            ),
            child: Center(
                child: Text(_personaEmoji,
                    style: const TextStyle(fontSize: 11))),
          ),
          const SizedBox(width: 6),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(14),
              ),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: const _BouncingDots(),
          ),
        ],
      ),
    );
  }

  (String, Color) _getStateInfo() {
    switch (_session.connectionState) {
      case 'connecting':
        return ('Connecting…', const Color(0xFFFFD166));
      case 'reconnecting':
        return ('Reconnecting…', const Color(0xFFFFD166));
      case 'failed':
        return ('Failed', const Color(0xFFFF6B6B));
    }

    switch (_session.agentState) {
      case 'listening':
        return ('Listening', const Color(0xFF00D4AA));
      case 'thinking':
        return ('Thinking…', const Color(0xFF60A5FA));
      case 'speaking':
        return ('Speaking', const Color(0xFFA78BFA));
      case 'blocked':
        return ('Blocked', const Color(0xFFFF6B6B));
      default:
        return ('Connected', Colors.white54);
    }
  }
}

// ── Bouncing dots (typing indicator) ──────────────────────────────────────────

class _BouncingDots extends StatefulWidget {
  const _BouncingDots();

  @override
  State<_BouncingDots> createState() => _BouncingDotsState();
}

class _BouncingDotsState extends State<_BouncingDots>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(3, (i) {
      return AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      )..repeat(reverse: true);
    });

    // Stagger the animations
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 150), () {
        if (mounted) _controllers[i].forward();
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _controllers[i],
          builder: (_, __) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF7C5CFC)
                  .withValues(alpha: 0.3 + _controllers[i].value * 0.5),
            ),
          ),
        );
      }),
    );
  }
}

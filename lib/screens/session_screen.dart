import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/voice_session.dart';
import '../widgets/agent_avatar.dart';

/// Voice call screen — mirrors Vue `SessionRoom.vue`.
///
/// Shows the animated avatar, live transcript, and session controls (mic, end call).
/// Receives session details and persona info via route arguments.
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
      backgroundColor: const Color(0xFF0A0A0F),
      body: Stack(
        children: [
          // ── Ambient glows ───────────────────────────────────────────
          Positioned(
            top: -50,
            left: MediaQuery.of(context).size.width * 0.2,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            right: MediaQuery.of(context).size.width * 0.2,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF06B6D4).withValues(alpha: 0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ── Main content ────────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),

                // Connection error banner
                if (_session.error != null) _buildErrorBanner(),

                // Body — avatar + transcript
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // On wide screens, side-by-side layout
                      if (constraints.maxWidth > 700) {
                        return Row(
                          children: [
                            // Left: Avatar + controls
                            SizedBox(
                              width: 360,
                              child: _buildAvatarPanel(),
                            ),
                            Container(
                              width: 1,
                              color: Colors.white.withValues(alpha: 0.05),
                            ),
                            // Right: Transcript
                            Expanded(child: _buildTranscriptPanel()),
                          ],
                        );
                      }
                      // On narrow screens, stacked layout
                      return Column(
                        children: [
                          _buildAvatarPanel(compact: true),
                          Expanded(child: _buildTranscriptPanel()),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
      ),
      child: Row(
        children: [
          // End session
          GestureDetector(
            onTap: _isLeaving ? null : _handleLeave,
            child: Row(
              children: [
                Icon(Icons.arrow_back,
                    size: 16,
                    color: Colors.white.withValues(alpha: 0.5)),
                const SizedBox(width: 6),
                Text(
                  'End Session',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),

          // Title + Live indicator
          Column(
            children: [
              Text(
                _personaName,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF4ADE80),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Live',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),

          // Loading spinner when leaving
          SizedBox(
            width: 80,
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
    );
  }

  // ── Error banner ────────────────────────────────────────────────────────

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Colors.red.withValues(alpha: 0.1),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              size: 14, color: Colors.redAccent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _session.error!,
              style: GoogleFonts.inter(fontSize: 12, color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  // ── Avatar panel ────────────────────────────────────────────────────────

  Widget _buildAvatarPanel({bool compact = false}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 24,
        vertical: compact ? 16 : 32,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated avatar
          AgentAvatar(
            agentState: _session.agentState,
            personaName: _personaName,
            emoji: _personaEmoji,
            size: compact ? 120 : 180,
          ),

          SizedBox(height: compact ? 16 : 24),

          // Controls: mic toggle + end call
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Mic button
              _buildControlButton(
                icon: _session.micEnabled ? Icons.mic : Icons.mic_off,
                label: _session.micEnabled ? 'Mute' : 'Unmute',
                color: _session.micEnabled
                    ? const Color(0xFF8B5CF6)
                    : Colors.white24,
                onTap: _session.toggleMic,
              ),
              const SizedBox(width: 12),

              // End call button
              _buildControlButton(
                icon: Icons.call_end,
                label: 'End',
                color: Colors.redAccent,
                onTap: _handleLeave,
                isDestructive: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.2),
              border: Border.all(color: color.withValues(alpha: 0.4)),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: Colors.white.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }

  // ── Transcript panel ────────────────────────────────────────────────────

  Widget _buildTranscriptPanel() {
    return Column(
      children: [
        // Toolbar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.chat_bubble_outline,
                  size: 14,
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.7)),
              const SizedBox(width: 8),
              Text(
                'Live Transcript',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              const Spacer(),
              if (_session.transcript.isNotEmpty)
                GestureDetector(
                  onTap: _session.clearTranscript,
                  child: Row(
                    children: [
                      Icon(Icons.close,
                          size: 11,
                          color: Colors.white.withValues(alpha: 0.25)),
                      const SizedBox(width: 3),
                      Text(
                        'Clear',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.25),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),

        // Message list
        Expanded(
          child: _session.transcript.isEmpty
              ? _buildEmptyTranscript()
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _session.transcript.length +
                      (_isThinkingOrSpeaking ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _session.transcript.length) {
                      return _buildTypingIndicator();
                    }
                    return _buildMessageBubble(_session.transcript[index]);
                  },
                ),
        ),

        // Footer status bar
        _buildFooterBar(),
      ],
    );
  }

  bool get _isThinkingOrSpeaking =>
      _session.agentState == 'thinking' || _session.agentState == 'speaking';

  Widget _buildEmptyTranscript() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.05),
            ),
            child: Icon(Icons.mic,
                size: 24, color: Colors.white.withValues(alpha: 0.2)),
          ),
          const SizedBox(height: 12),
          Text(
            'Conversation will appear here',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.3),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Start speaking to see live transcripts',
            style: GoogleFonts.inter(
              fontSize: 11,
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
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            // Agent avatar
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                border: Border.all(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.3)),
              ),
              child: Center(
                child: Text(_personaEmoji,
                    style: const TextStyle(fontSize: 12)),
              ),
            ),
            const SizedBox(width: 8),
          ],

          // Bubble
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.65),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser
                    ? const Color(0xFF06B6D4).withValues(alpha: 0.1)
                    : transcript.isBackchannel
                        ? const Color(0xFF8B5CF6).withValues(alpha: 0.05)
                        : const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft:
                      isUser ? const Radius.circular(16) : const Radius.circular(4),
                  bottomRight:
                      isUser ? const Radius.circular(4) : const Radius.circular(16),
                ),
                border: Border.all(
                  color: isUser
                      ? const Color(0xFF06B6D4).withValues(alpha: 0.2)
                      : const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Speaker label + timestamp
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isUser ? 'You' : _personaName,
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.5),
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        transcript.timestamp,
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    transcript.text,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.white.withValues(
                          alpha: transcript.isFinal ? 0.9 : 0.6),
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
            const SizedBox(width: 8),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF06B6D4).withValues(alpha: 0.1),
                border: Border.all(
                    color: const Color(0xFF06B6D4).withValues(alpha: 0.3)),
              ),
              child: Icon(Icons.mic,
                  size: 13,
                  color: const Color(0xFF06B6D4).withValues(alpha: 0.7)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.05),
              border:
                  Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child:
                Center(child: Text(_personaEmoji, style: const TextStyle(fontSize: 12))),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(16),
              ),
              border: Border.all(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.2)),
            ),
            child: const _BouncingDots(),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterBar() {
    final stateInfo = _getStateInfo();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${_session.transcript.length} message${_session.transcript.length != 1 ? 's' : ''}',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.3),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: stateInfo.$2,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                stateInfo.$1,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: stateInfo.$2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  (String, Color) _getStateInfo() {
    // Priority: connection states first, then agent states
    switch (_session.connectionState) {
      case 'connecting':
        return ('Connecting…', const Color(0xFFFACC15));
      case 'reconnecting':
        return ('Reconnecting…', const Color(0xFFFACC15));
      case 'failed':
        return ('Failed', Colors.redAccent);
    }

    switch (_session.agentState) {
      case 'listening':
        return ('Listening', const Color(0xFF4ADE80));
      case 'thinking':
        return ('Thinking…', const Color(0xFF60A5FA));
      case 'speaking':
        return ('Speaking', const Color(0xFFA78BFA));
      case 'blocked':
        return ('Blocked', Colors.redAccent);
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
              color: const Color(0xFF8B5CF6)
                  .withValues(alpha: 0.4 + _controllers[i].value * 0.4),
            ),
          ),
        );
      }),
    );
  }
}

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:livekit_client/livekit_client.dart';
import '../models/transcript_entry.dart';

/// Agent state attribute key published by the LiveKit agent SDK.
const String _agentStateKey = 'lk.agent.state';

// ── Voice Session ──────────────────────────────────────────────────────────────

/// Manages a LiveKit voice session with an AI agent.
///
/// Wraps a LiveKit [Room],
/// exposes reactive state via [ChangeNotifier], and handles:
///   - Connection lifecycle with state tracking
///   - Agent-state updates via participant attributes
///   - Automatic audio rendering
///   - Mic toggle synced to room state
///   - Live transcript via STT transcription events
///   - Echo suppression for user STT segments
class VoiceSession extends ChangeNotifier {
  late final Room _room;
  late final EventsListener<RoomEvent> _listener;

  // ── Reactive state ──────────────────────────────────────────────────────

  String _connectionState = 'disconnected';
  String _agentState = 'idle';
  bool _micEnabled = false;
  String? _error;
  final List<TranscriptEntry> _transcript = [];

  // ── Echo-detection state ────────────────────────────────────────────────
  // Plain list — only referenced imperatively, never rendered.
  final List<_EchoPhrase> _recentAgentPhrases = [];

  // ── Duration tracking ───────────────────────────────────────────────────
  Timer? _timer;
  int _durationSeconds = 0;
  String _duration = '00:00';

  // ── Getters ─────────────────────────────────────────────────────────────

  /// Current connection state:
  /// `disconnected` | `connecting` | `connected` | `reconnecting` | `failed`
  String get connectionState => _connectionState;

  /// Current agent state:
  /// `idle` | `listening` | `thinking` | `speaking` | `blocked`
  String get agentState => _agentState;

  /// Whether the local microphone is enabled.
  bool get micEnabled => _micEnabled;

  /// Last error message, or null.
  String? get error => _error;

  /// Formatted connection duration (e.g., '02:15').
  String get duration => _duration;

  /// Live conversation transcript (unmodifiable view).
  List<TranscriptEntry> get transcript => List.unmodifiable(_transcript);

  // ── Constructor ─────────────────────────────────────────────────────────

  VoiceSession() {
    _room = Room(
      roomOptions: const RoomOptions(
        defaultAudioCaptureOptions: AudioCaptureOptions(
          echoCancellation: true,
          noiseSuppression: true,
          autoGainControl: true,
        ),
        adaptiveStream: true,
        dynacast: true,
      ),
    );
    _listener = _room.createListener();
    _attachListeners();
  }

  // ── Room event listeners ────────────────────────────────────────────────

  void _attachListeners() {
    // Connection state changes
    _listener.on<RoomConnectedEvent>((event) {
      _connectionState = 'connected';
      _error = null;
      _startTimer();
      notifyListeners();
    });
    _listener.on<RoomDisconnectedEvent>((event) {
      _connectionState = 'disconnected';
      _agentState = 'idle';
      _micEnabled = false;
      _stopTimer();
      notifyListeners();
    });
    _listener.on<RoomReconnectingEvent>((event) {
      _connectionState = 'reconnecting';
      notifyListeners();
    });
    _listener.on<RoomReconnectedEvent>((event) {
      _connectionState = 'connected';
      _error = null;
      notifyListeners();
    });

    // Agent state via participant attributes
    _listener.on<ParticipantAttributesChanged>((event) {
      final participant = event.participant;
      if (participant.kind == ParticipantKind.AGENT) {
        final state = participant.attributes[_agentStateKey];
        if (state != null && state.isNotEmpty) {
          _agentState = state;
          notifyListeners();
        }
      }
    });

    // Handle agent joining after our own connect (race condition guard)
    _listener.on<ParticipantConnectedEvent>((event) {
      final participant = event.participant;
      if (participant.kind == ParticipantKind.AGENT) {
        final state = participant.attributes[_agentStateKey];
        if (state != null && state.isNotEmpty) {
          _agentState = state;
          notifyListeners();
        }
      }
    });

    // Audio rendering — attach remote audio tracks
    _listener.on<TrackSubscribedEvent>((event) {
      if (event.track.kind == TrackType.AUDIO) {
        // LiveKit Flutter SDK handles audio playback automatically
        // for remote audio tracks once subscribed.
        debugPrint('[VoiceSession] Remote audio track subscribed');
      }
    });

    // Mic state sync
    _listener.on<TrackMutedEvent>((event) {
      if (event.participant == _room.localParticipant &&
          event.publication.source == TrackSource.microphone) {
        _micEnabled = false;
        notifyListeners();
      }
    });

    _listener.on<TrackUnmutedEvent>((event) {
      if (event.participant == _room.localParticipant &&
          event.publication.source == TrackSource.microphone) {
        _micEnabled = true;
        notifyListeners();
      }
    });

    // Native LiveKit STT transcription events
    _listener.on<TranscriptionEvent>((event) {
      for (final segment in event.segments) {
        final isAgent = event.participant?.kind == ParticipantKind.AGENT;
        final speaker = isAgent ? 'agent' : 'user';

        if (speaker == 'agent') {
          _rememberAgentPhrase(segment.text);
        } else if (_isUserEcho(segment.text)) {
          debugPrint('[VoiceSession] Suppressed user STT echo: ${segment.text}');
          continue;
        }

        _upsertEntry(TranscriptEntry(
          id: segment.id,
          speaker: speaker,
          text: segment.text,
          isFinal: segment.isFinal,
        ));
      }
      notifyListeners();
    });

    // Backchannel data messages from the agent
    _listener.on<DataReceivedEvent>((event) {
      if (event.topic != 'backchannel') return;
      try {
        final data = jsonDecode(utf8.decode(event.data));
        if (data['type'] == 'backchannel' && data['text'] != null) {
          _addBackchannelEntry(data['text'] as String);
        }
      } catch (e) {
        debugPrint('[VoiceSession] Failed to parse backchannel message: $e');
      }
    });
  }

  // ── Transcript management ───────────────────────────────────────────────

  void _upsertEntry(TranscriptEntry entry) {
    final idx = _transcript.indexWhere((m) => m.id == entry.id);
    if (idx >= 0) {
      // Update existing entry — preserve original timestamp
      _transcript[idx].text = entry.text;
      _transcript[idx].isFinal = entry.isFinal;
    } else {
      _transcript.add(entry);
    }
  }

  void _addBackchannelEntry(String text) {
    _rememberAgentPhrase(text);
    _transcript.add(TranscriptEntry(
      id: 'bc-${DateTime.now().millisecondsSinceEpoch}-${text.hashCode}',
      speaker: 'agent',
      text: text,
      isFinal: true,
      isBackchannel: true,
    ));
    notifyListeners();
  }

  // ── Echo detection ──────────────────────────────────────────────────────
  // Detects when the user's STT output echoes the agent's recent speech.

  String _normaliseEchoText(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  void _rememberAgentPhrase(String text) {
    final norm = _normaliseEchoText(text);
    if (norm.isEmpty) return;
    final now = DateTime.now().millisecondsSinceEpoch;

    // Prune phrases older than 14s, then append; cap at 16 entries
    _recentAgentPhrases.removeWhere((e) => now - e.at > 14000);
    _recentAgentPhrases.add(_EchoPhrase(norm, now));
    if (_recentAgentPhrases.length > 16) {
      _recentAgentPhrases.removeRange(0, _recentAgentPhrases.length - 16);
    }
  }

  bool _isUserEcho(String text) {
    final norm = _normaliseEchoText(text);
    if (norm.isEmpty) return false;
    final now = DateTime.now().millisecondsSinceEpoch;

    // Prune stale entries
    _recentAgentPhrases.removeWhere((e) => now - e.at > 14000);

    return _recentAgentPhrases.any((phrase) {
      if (norm == phrase.norm) return true;
      // Short phrase (≤5 words) that starts the agent's utterance → likely echo
      if (phrase.norm.startsWith(norm) && norm.split(' ').length <= 5) return true;
      // User phrase is a substring of what agent said → echo fragment
      if (norm.length <= phrase.norm.length && phrase.norm.contains(norm)) return true;
      return false;
    });
  }

  // ── Timer logic ─────────────────────────────────────────────────────────

  void _startTimer() {
    _durationSeconds = 0;
    _duration = '00:00';
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _durationSeconds++;
      final m = (_durationSeconds ~/ 60).toString().padLeft(2, '0');
      final s = (_durationSeconds % 60).toString().padLeft(2, '0');
      _duration = '$m:$s';
      notifyListeners();
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  // ── Public API ──────────────────────────────────────────────────────────

  /// Connect to a LiveKit room.
  ///
  /// [serverUrl] — LiveKit WebSocket URL (e.g. `wss://livekit.example.com`).
  /// [token] — JWT token returned by `createSession()`.
  Future<void> connect(String serverUrl, String token) async {
    _error = null;
    _connectionState = 'connecting';
    notifyListeners();

    try {
      await _room.connect(serverUrl, token);
      await _room.localParticipant?.setMicrophoneEnabled(true);
      _micEnabled = true;
      _connectionState = 'connected';
    } catch (e) {
      _connectionState = 'failed';
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
    notifyListeners();
  }

  /// Disconnect from the LiveKit room.
  Future<void> disconnect() async {
    if (_connectionState == 'connected') {
      try {
        final payload = utf8.encode(jsonEncode({
          'type': 'end_session',
          'reason': 'user_actively_ended',
        }));
        await _room.localParticipant?.publishData(payload, reliable: true);
        debugPrint('[VoiceSession] end_session signal published successfully!');
        // Give the WebRTC data channel 300ms to flush the packet before disconnecting
        await Future.delayed(const Duration(milliseconds: 300));
      } catch (e) {
        debugPrint('[VoiceSession] end_session signal failed: $e');
      }
    }
    await _room.disconnect();
    _connectionState = 'disconnected';
    _agentState = 'idle';
    _micEnabled = false;
    _stopTimer();
    notifyListeners();
  }

  bool _isInterrupted = false;

  /// Whether the AI is currently interrupted and waiting to be resumed.
  bool get isInterrupted => _isInterrupted;

  /// Send an interrupt signal to halt AI generation instantly.
  Future<void> interrupt() async {
    if (_connectionState != 'connected') return;
    try {
      final payload = utf8.encode(jsonEncode({'type': 'interrupt'}));
      await _room.localParticipant?.publishData(payload, reliable: true);
      _isInterrupted = true;
      notifyListeners();
    } catch (e) {
      debugPrint('[VoiceSession] interrupt failed: $e');
    }
  }

  /// Send a resume signal to un-mute the AI generation.
  Future<void> resume() async {
    if (_connectionState != 'connected') return;
    try {
      final payload = utf8.encode(jsonEncode({'type': 'resume'}));
      await _room.localParticipant?.publishData(payload, reliable: true);
      _isInterrupted = false;
      notifyListeners();
    } catch (e) {
      debugPrint('[VoiceSession] resume failed: $e');
    }
  }

  /// Toggle the local microphone on/off.
  Future<void> toggleMic() async {
    final next = !_micEnabled;
    try {
      await _room.localParticipant?.setMicrophoneEnabled(next);
      _micEnabled = next;
      notifyListeners();
    } catch (e) {
      debugPrint('[VoiceSession] toggleMic failed: $e');
    }
  }

  /// Clear the transcript buffer.
  void clearTranscript() {
    _transcript.clear();
    notifyListeners();
  }

  /// Returns only finalised messages ready for server persistence.
  List<Map<String, dynamic>> finalMessages() {
    return _transcript
        .where((m) => m.isFinal)
        .map((m) => {
              'speaker': m.speaker,
              'text': m.text,
              'timestamp': m.timestamp,
            })
        .toList();
  }

  // ── Cleanup ─────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _listener.dispose();
    _stopTimer();
    _room.disconnect();
    _room.dispose();
    super.dispose();
  }
}

// ── Internal helpers ────────────────────────────────────────────────────────

class _EchoPhrase {
  final String norm;
  final int at; // milliseconds since epoch

  _EchoPhrase(this.norm, this.at);
}

/// Data model for a single transcript message.
///
/// Represents a single transcript message in a voice session.
class TranscriptEntry {
  /// Unique identifier for this transcript segment.
  final String id;

  /// Who said it: `'user'` or `'agent'`.
  final String speaker;

  /// The transcribed text content.
  String text;

  /// Whether this segment has been finalised by the STT engine.
  bool isFinal;

  /// Whether this is a backchannel message from the agent.
  final bool isBackchannel;

  /// Human-readable timestamp (HH:mm:ss).
  final String timestamp;

  TranscriptEntry({
    required this.id,
    required this.speaker,
    required this.text,
    this.isFinal = false,
    this.isBackchannel = false,
    String? timestamp,
  }) : timestamp = timestamp ?? _formatTime(DateTime.now());

  static String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}:'
        '${dt.second.toString().padLeft(2, '0')}';
  }
}

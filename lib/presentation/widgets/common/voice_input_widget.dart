// lib/presentation/widgets/common/voice_input_widget.dart
//
// Mic-button widget for voice text input.
// Uses the SpeechService abstraction so the production platform impl
// can be swapped in without touching this widget, and tests can inject
// a FakeSpeechService.
//
// Requirements: 1.5, 5.7
// Developer: Developer 6

import 'package:flutter/material.dart';
import '../../../config/localization/app_localizations.dart';
import '../../../config/theme.dart';

/// Describes the current state of the voice input button.
enum VoiceInputState { idle, listening, unavailable }

/// Abstract speech-to-text service interface.
///
/// Inject a real platform implementation (e.g. using the `speech_to_text`
/// package) or a [FakeSpeechService] in tests.
abstract class SpeechService {
  Future<bool> initialize();
  Future<void> startListening({required void Function(String text) onResult});
  Future<void> stopListening();
  bool get isListening;
  bool get isAvailable;
}

/// No-op implementation used when speech recognition is not available
/// (e.g. on web, desktop CI, or when no package is installed).
class NoOpSpeechService implements SpeechService {
  const NoOpSpeechService();

  @override
  bool get isAvailable => false;

  @override
  bool get isListening => false;

  @override
  Future<bool> initialize() async => false;

  @override
  Future<void> startListening(
      {required void Function(String text) onResult}) async {}

  @override
  Future<void> stopListening() async {}
}

/// A mic-button widget for voice text input.
///
/// Renders a pulsing circle while listening. If the injected [SpeechService]
/// is unavailable, the button appears disabled and shows a tooltip.
///
/// ```dart
/// VoiceInputWidget(onResult: (text) => _controller.text = text)
/// ```
class VoiceInputWidget extends StatefulWidget {
  /// Called when the recogniser commits a final result.
  final void Function(String text) onResult;

  /// Optional custom [SpeechService]. Defaults to [NoOpSpeechService].
  final SpeechService? speechService;

  /// Diameter of the mic button in logical pixels. Defaults to 56.
  final double size;

  const VoiceInputWidget({
    super.key,
    required this.onResult,
    this.speechService,
    this.size = 56,
  });

  @override
  State<VoiceInputWidget> createState() => _VoiceInputWidgetState();
}

class _VoiceInputWidgetState extends State<VoiceInputWidget>
    with SingleTickerProviderStateMixin {
  late final SpeechService _service;
  VoiceInputState _voiceState = VoiceInputState.idle;

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _service = widget.speechService ?? const NoOpSpeechService();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.22).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _initialize();
  }

  Future<void> _initialize() async {
    final available = await _service.initialize();
    if (mounted) {
      setState(() => _voiceState =
          available ? VoiceInputState.idle : VoiceInputState.unavailable);
    }
  }

  Future<void> _toggle() async {
    if (_voiceState == VoiceInputState.unavailable) return;

    if (_service.isListening) {
      await _service.stopListening();
      _pulseController.stop();
      if (mounted) setState(() => _voiceState = VoiceInputState.idle);
    } else {
      setState(() => _voiceState = VoiceInputState.listening);
      _pulseController.repeat(reverse: true);
      await _service.startListening(onResult: (text) {
        if (mounted) {
          widget.onResult(text);
          _pulseController.stop();
          setState(() => _voiceState = VoiceInputState.idle);
        }
      });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isUnavailable = _voiceState == VoiceInputState.unavailable;
    final isListening = _voiceState == VoiceInputState.listening;

    final color = isUnavailable
        ? AppTheme.textSecondary
        : isListening
            ? AppTheme.errorColor
            : AppTheme.primaryColor;

    final tooltip = isUnavailable
        ? loc.voiceNotAvailable
        : isListening
            ? loc.voiceListening
            : loc.voiceInputHint;

    return Tooltip(
      message: tooltip,
      child: Semantics(
        label: tooltip,
        button: true,
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: isListening ? _pulseAnimation.value : 1.0,
              child: child,
            );
          },
          child: GestureDetector(
            onTap: _toggle,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: color.withValues(alpha: isListening ? 0.15 : 0.08),
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 1.5),
              ),
              child: Icon(
                isListening ? Icons.mic : Icons.mic_none,
                color: color,
                size: widget.size * 0.45,
                semanticLabel: tooltip,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

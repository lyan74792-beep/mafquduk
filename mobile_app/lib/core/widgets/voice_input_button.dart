// Microphone icon button that transcribes speech into a [TextEditingController].
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../l10n/l10n.dart';
import '../theme/app_colors.dart';
import 'async_view.dart';

class VoiceInputButton extends StatefulWidget {
  const VoiceInputButton({
    super.key,
    required this.controller,
  });

  final TextEditingController controller;

  @override
  State<VoiceInputButton> createState() => _VoiceInputButtonState();
}

class _VoiceInputButtonState extends State<VoiceInputButton> {
  final SpeechToText _speech = SpeechToText();
  bool _listening = false;

  static String _localeFor(String lang) {
    switch (lang) {
      case 'en':
        return 'en_US';
      case 'tr':
        return 'tr_TR';
      case 'ur':
        return 'ur_PK';
      case 'ar':
      default:
        return 'ar_SA';
    }
  }

  Future<void> _toggle() async {
    if (_listening) {
      await _speech.stop();
      if (mounted) {
        setState(() => _listening = false);
      }
      return;
    }

    bool available = false;
    try {
      available = await _speech.initialize(
        onStatus: (status) {
          if ((status == 'done' || status == 'notListening') && mounted) {
            setState(() => _listening = false);
          }
        },
        onError: (_) {
          if (mounted) {
            setState(() => _listening = false);
          }
        },
      );
    } catch (_) {
      available = false;
    }

    if (!available) {
      if (mounted) {
        showSnack(context, t('voiceUnavailable'), isError: true);
      }
      return;
    }

    setState(() => _listening = true);
    await _speech.listen(
      listenOptions: SpeechListenOptions(localeId: _localeFor(L10n.instance.lang)),
      onResult: _onResult,
    );
  }

  void _onResult(SpeechRecognitionResult result) {
    if (!result.finalResult) return;
    final words = result.recognizedWords.trim();
    if (words.isEmpty) return;
    final existing = widget.controller.text.trim();
    final updated = existing.isEmpty ? words : '$existing $words';
    widget.controller.value = TextEditingValue(
      text: updated,
      selection: TextSelection.collapsed(offset: updated.length),
    );
    if (mounted) {
      setState(() => _listening = false);
    }
  }

  @override
  void dispose() {
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: _listening ? t('stopVoiceInput') : t('voiceInput'),
      onPressed: _toggle,
      icon: Icon(
        _listening ? Icons.mic : Icons.mic_none_outlined,
        color: _listening ? AppColors.danger : AppColors.govGreen,
      ),
    );
  }
}

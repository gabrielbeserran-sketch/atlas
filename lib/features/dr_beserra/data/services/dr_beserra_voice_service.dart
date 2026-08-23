import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

class DrBeserraVoiceState {
  const DrBeserraVoiceState({
    this.available = false,
    this.initialized = false,
    this.listening = false,
    this.transcript = '',
    this.finalResult = false,
    this.errorMessage = '',
  });

  final bool available;
  final bool initialized;
  final bool listening;
  final String transcript;
  final bool finalResult;
  final String errorMessage;

  DrBeserraVoiceState copyWith({
    bool? available,
    bool? initialized,
    bool? listening,
    String? transcript,
    bool? finalResult,
    String? errorMessage,
  }) =>
      DrBeserraVoiceState(
        available: available ?? this.available,
        initialized: initialized ?? this.initialized,
        listening: listening ?? this.listening,
        transcript: transcript ?? this.transcript,
        finalResult: finalResult ?? this.finalResult,
        errorMessage: errorMessage ?? this.errorMessage,
      );
}

class DrBeserraVoiceService {
  DrBeserraVoiceService._();

  static final DrBeserraVoiceService instance = DrBeserraVoiceService._();

  final SpeechToText _speech = SpeechToText();
  final ValueNotifier<DrBeserraVoiceState> state =
      ValueNotifier<DrBeserraVoiceState>(const DrBeserraVoiceState());

  String? _preferredLocaleId;

  Future<bool> initialize() async {
    if (state.value.initialized) {
      return state.value.available;
    }

    final available = await _speech.initialize(
      onStatus: _onStatus,
      onError: (error) {
        state.value = state.value.copyWith(
          listening: false,
          finalResult: false,
          errorMessage: error.errorMsg,
        );
      },
    );

    if (available) {
      final locales = await _speech.locales();
      final portuguese = locales.where((item) {
        final locale = item.localeId.toLowerCase().replaceAll('-', '_');
        return locale == 'pt_br' || locale.startsWith('pt_');
      }).toList(growable: false);
      if (portuguese.isNotEmpty) {
        _preferredLocaleId = portuguese.first.localeId;
      }
    }

    state.value = DrBeserraVoiceState(
      available: available,
      initialized: true,
      listening: false,
      errorMessage: available
          ? ''
          : 'Reconhecimento de voz não está disponível neste dispositivo.',
    );
    return available;
  }

  Future<bool> startListening() async {
    final available = await initialize();
    if (!available || _speech.isListening) return available;

    state.value = state.value.copyWith(
      listening: true,
      transcript: '',
      finalResult: false,
      errorMessage: '',
    );

    await _speech.listen(
      onResult: _onResult,
      listenOptions: SpeechListenOptions(
        localeId: _preferredLocaleId,
        listenMode: ListenMode.dictation,
        partialResults: true,
        cancelOnError: true,
      ),
    );
    return true;
  }

  Future<void> stopListening() async {
    if (_speech.isListening) {
      await _speech.stop();
    }
    state.value = state.value.copyWith(listening: false);
  }

  Future<void> cancelListening() async {
    if (_speech.isListening) {
      await _speech.cancel();
    }
    state.value = state.value.copyWith(
      listening: false,
      transcript: '',
      finalResult: false,
    );
  }

  void clearFinalResult() {
    state.value = state.value.copyWith(finalResult: false);
  }

  void _onResult(SpeechRecognitionResult result) {
    state.value = state.value.copyWith(
      transcript: result.recognizedWords.trim(),
      finalResult: result.finalResult,
      listening: !result.finalResult && _speech.isListening,
      errorMessage: '',
    );
  }

  void _onStatus(String status) {
    final normalized = status.toLowerCase();
    final listening =
        normalized == 'listening' || normalized == 'starting';
    if (normalized == 'done' || normalized == 'notlistening') {
      state.value = state.value.copyWith(listening: false);
      return;
    }
    state.value = state.value.copyWith(listening: listening);
  }
}

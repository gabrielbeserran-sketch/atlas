#include "include/speech_to_text_windows/speech_to_text_windows.h"

void SpeechToTextWindowsRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  // Intencionalmente no-op no Windows.
  // O Atlas não inicia reconhecimento de voz no desktop RC.
  (void)registrar;
}

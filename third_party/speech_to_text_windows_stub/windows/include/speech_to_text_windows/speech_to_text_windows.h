#ifndef FLUTTER_PLUGIN_SPEECH_TO_TEXT_WINDOWS_H_
#define FLUTTER_PLUGIN_SPEECH_TO_TEXT_WINDOWS_H_

#include <flutter_plugin_registrar.h>

#ifdef SPEECH_TO_TEXT_WINDOWS_PLUGIN_IMPL
#define SPEECH_TO_TEXT_WINDOWS_PLUGIN_EXPORT __declspec(dllexport)
#else
#define SPEECH_TO_TEXT_WINDOWS_PLUGIN_EXPORT __declspec(dllimport)
#endif

extern "C" SPEECH_TO_TEXT_WINDOWS_PLUGIN_EXPORT void
SpeechToTextWindowsRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar);

#endif  // FLUTTER_PLUGIN_SPEECH_TO_TEXT_WINDOWS_H_

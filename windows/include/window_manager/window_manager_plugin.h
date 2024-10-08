#ifndef FLUTTER_PLUGIN_WINDOW_MANAGER_PLUGIN_H_
#define FLUTTER_PLUGIN_WINDOW_MANAGER_PLUGIN_H_

#include <any>
#include <map>
#include <string>
#include <vector>
#include <windows.h>

#include <flutter_plugin_registrar.h>

#include <memory>

#ifdef FLUTTER_PLUGIN_IMPL
#define FLUTTER_PLUGIN_EXPORT __declspec(dllexport)
#else
#define FLUTTER_PLUGIN_EXPORT __declspec(dllimport)
#endif

#if defined(__cplusplus)
extern "C" {
#endif

FLUTTER_PLUGIN_EXPORT void WindowManagerPluginRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar);

class FlutterWindow;

typedef std::shared_ptr<FlutterWindow> (*WindowCreatedCallback)(
    std::vector<std::string> command_line_arguments);
FLUTTER_PLUGIN_EXPORT void WindowManagerPluginSetWindowCreatedCallback(
    WindowCreatedCallback callback);

#if defined(__cplusplus)
}  // extern "C"
#endif

#endif  // FLUTTER_PLUGIN_WINDOW_MANAGER_PLUGIN_H_

//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <disk_space_2/disk_space_2_plugin.h>
#include <ffmpeg_kit_flutter_new/f_fmpeg_kit_flutter_plugin.h>
#include <gal/gal_plugin_c_api.h>

void RegisterPlugins(flutter::PluginRegistry* registry) {
  DiskSpace_2PluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("DiskSpace_2Plugin"));
  FFmpegKitFlutterPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("FFmpegKitFlutterPlugin"));
  GalPluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("GalPluginCApi"));
}

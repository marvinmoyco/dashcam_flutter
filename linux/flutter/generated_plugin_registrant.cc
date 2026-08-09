//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <disk_space_2/disk_space_2_plugin.h>
#include <ffmpeg_kit_flutter_new/f_fmpeg_kit_flutter_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) disk_space_2_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "DiskSpace_2Plugin");
  disk_space_2_plugin_register_with_registrar(disk_space_2_registrar);
  g_autoptr(FlPluginRegistrar) ffmpeg_kit_flutter_new_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "FFmpegKitFlutterPlugin");
  f_fmpeg_kit_flutter_plugin_register_with_registrar(ffmpeg_kit_flutter_new_registrar);
}

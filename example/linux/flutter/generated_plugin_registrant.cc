//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <pro_video_editor/pro_video_editor_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) pro_video_editor_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "ProVideoEditorPlugin");
  pro_video_editor_plugin_register_with_registrar(pro_video_editor_registrar);
}

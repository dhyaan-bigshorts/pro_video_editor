#include "video_metadata.h"

#include <flutter/standard_method_codec.h>
#include <gst/gst.h>
#include <gst/pbutils/pbutils.h>
#include <fstream>
#include <unistd.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <string>
#include <vector>
#include <map>
#include <ctime>

namespace pro_video_editor {

void HandleGetMetadata(
    const flutter::EncodableMap& args,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {

    // Get videoBytes
    auto itVideo = args.find(flutter::EncodableValue("videoBytes"));
    if (itVideo == args.end()) {
        result->Error("InvalidArgument", "Missing videoBytes");
        return;
    }
    const auto* videoBytes = std::get_if<std::vector<uint8_t>>(&itVideo->second);
    if (!videoBytes) {
        result->Error("InvalidArgument", "Invalid videoBytes format");
        return;
    }

    // Get extension
    auto itExt = args.find(flutter::EncodableValue("extension"));
    if (itExt == args.end()) {
        result->Error("InvalidArgument", "Missing extension");
        return;
    }
    const auto* extStr = std::get_if<std::string>(&itExt->second);
    if (!extStr) {
        result->Error("InvalidArgument", "Invalid extension format");
        return;
    }

    // Write to temp file
    char tempName[] = "/tmp/pro_video_XXXXXX";
    int fd = mkstemp(tempName);
    if (fd == -1) {
        result->Error("FileError", "Failed to create temp file");
        return;
    }
    write(fd, videoBytes->data(), videoBytes->size());
    close(fd);

    // Get file size and creation time
    struct stat file_stat;
    int fileSize = 0;
    std::string dateStr;
    if (stat(tempName, &file_stat) == 0) {
        fileSize = file_stat.st_size;

        char buffer[64];
        std::tm* tm = std::localtime(&file_stat.st_ctime);
        std::strftime(buffer, sizeof(buffer), "%Y-%m-%d %H:%M:%S", tm);
        dateStr = buffer;
    }

    // Init GStreamer
    gst_init(nullptr, nullptr);

    GstDiscoverer* discoverer = gst_discoverer_new(5 * GST_SECOND, nullptr);
    if (!discoverer) {
        unlink(tempName);
        result->Error("GStreamerError", "Failed to create discoverer");
        return;
    }

    GstDiscovererInfo* info = gst_discoverer_discover_uri(discoverer, ("file://" + std::string(tempName)).c_str(), nullptr);
    unlink(tempName);

    if (!info) {
        g_object_unref(discoverer);
        result->Error("GStreamerError", "Failed to get metadata");
        return;
    }

    const GstDiscovererStreamInfo* streamInfo = gst_discoverer_info_get_stream_info(info);
    const GstCaps* caps = gst_discoverer_stream_info_get_caps(streamInfo);

    int width = 0, height = 0, bitrate = 0, rotation = 0;
    double duration_ms = 0.0;

    if (caps) {
        const GstStructure* s = gst_caps_get_structure(caps, 0);
        gst_structure_get_int(s, "width", &width);
        gst_structure_get_int(s, "height", &height);
    }

    duration_ms = (double)gst_discoverer_info_get_duration(info) / GST_MSECOND;

    // Metadata (title, artist, etc.)
    const GstTagList* tags = gst_discoverer_info_get_tags(info);
    gchar* title = nullptr;
    if (tags) {
        gst_tag_list_get_string(tags, GST_TAG_TITLE, &title);
    }

    flutter::EncodableMap result_map;
    result_map[flutter::EncodableValue("fileSize")] = flutter::EncodableValue(static_cast<int64_t>(fileSize));
    result_map[flutter::EncodableValue("duration")] = flutter::EncodableValue(duration_ms);
    result_map[flutter::EncodableValue("width")] = flutter::EncodableValue(width);
    result_map[flutter::EncodableValue("height")] = flutter::EncodableValue(height);
    result_map[flutter::EncodableValue("rotation")] = flutter::EncodableValue(rotation);
    result_map[flutter::EncodableValue("bitrate")] = flutter::EncodableValue(bitrate);
    result_map[flutter::EncodableValue("title")] = flutter::EncodableValue(title ? title : "");
    result_map[flutter::EncodableValue("artist")] = flutter::EncodableValue("");
    result_map[flutter::EncodableValue("author")] = flutter::EncodableValue("");
    result_map[flutter::EncodableValue("album")] = flutter::EncodableValue("");
    result_map[flutter::EncodableValue("albumArtist")] = flutter::EncodableValue("");
    result_map[flutter::EncodableValue("date")] = flutter::EncodableValue(dateStr);

    if (title) g_free(title);
    gst_discoverer_info_unref(info);
    g_object_unref(discoverer);

    result->Success(flutter::EncodableValue(result_map));
}

}  // namespace pro_video_editor

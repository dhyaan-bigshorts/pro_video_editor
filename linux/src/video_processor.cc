#include "video_metadata.h"

extern "C" {
#include <libavformat/avformat.h>
#include <libavutil/dict.h>
}

#include <flutter/standard_method_codec.h>
#include <fstream>
#include <string>
#include <vector>
#include <sstream>
#include <filesystem>
#include <chrono>
#include <iomanip>
#include <iostream>

namespace fs = std::filesystem;
namespace pro_video_editor {

std::string GenerateTempFilename(const std::string& extension) {
    std::stringstream filename;
    auto now = std::chrono::system_clock::now();
    auto time = std::chrono::system_clock::to_time_t(now);
    auto ms = std::chrono::duration_cast<std::chrono::milliseconds>(now.time_since_epoch()) % 1000;

    std::tm tm = *std::localtime(&time);
    filename << "/tmp/vid_"
             << std::put_time(&tm, "%Y%m%d%H%M%S")
             << ms.count()
             << extension;
    return filename.str();
}

bool WriteBytesToFile(const std::string& path, const std::vector<uint8_t>& bytes) {
    std::ofstream out(path, std::ios::binary);
    if (!out.is_open()) return false;
    out.write(reinterpret_cast<const char*>(bytes.data()), bytes.size());
    return true;
}

void HandleGetVideoInformation(
    const flutter::EncodableMap& args,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {

    // Extract videoBytes
    auto itVideo = args.find(flutter::EncodableValue("videoBytes"));
    if (itVideo == args.end() || !std::holds_alternative<std::vector<uint8_t>>(itVideo->second)) {
        result->Error("InvalidArgument", "Missing or invalid videoBytes");
        return;
    }
    const auto& videoBytes = std::get<std::vector<uint8_t>>(itVideo->second);

    // Extract extension
    auto itExt = args.find(flutter::EncodableValue("extension"));
    if (itExt == args.end() || !std::holds_alternative<std::string>(itExt->second)) {
        result->Error("InvalidArgument", "Missing or invalid extension");
        return;
    }
    std::string extension = std::get<std::string>(itExt->second);
    if (extension.empty() || extension[0] != '.') extension = "." + extension;

    // Write video to temp file
    std::string tempFilePath = GenerateTempFilename(extension);
    if (!WriteBytesToFile(tempFilePath, videoBytes)) {
        result->Error("FileError", "Failed to write video temp file");
        return;
    }

    // Use FFmpeg to extract metadata
    AVFormatContext* fmt_ctx = nullptr;
    if (avformat_open_input(&fmt_ctx, tempFilePath.c_str(), nullptr, nullptr) != 0) {
        fs::remove(tempFilePath);
        result->Error("FFmpegError", "Could not open video file");
        return;
    }

    if (avformat_find_stream_info(fmt_ctx, nullptr) < 0) {
        avformat_close_input(&fmt_ctx);
        fs::remove(tempFilePath);
        result->Error("FFmpegError", "Failed to find stream info");
        return;
    }

    int video_stream_index = -1;
    for (unsigned i = 0; i < fmt_ctx->nb_streams; ++i) {
        if (fmt_ctx->streams[i]->codecpar->codec_type == AVMEDIA_TYPE_VIDEO) {
            video_stream_index = i;
            break;
        }
    }

    if (video_stream_index == -1) {
        avformat_close_input(&fmt_ctx);
        fs::remove(tempFilePath);
        result->Error("FFmpegError", "No video stream found");
        return;
    }

    AVStream* video_stream = fmt_ctx->streams[video_stream_index];
    double duration_ms = (fmt_ctx->duration > 0)
        ? static_cast<double>(fmt_ctx->duration) / (AV_TIME_BASE / 1000)
        : static_cast<double>(video_stream->duration) * av_q2d(video_stream->time_base) * 1000.0;

    int width = video_stream->codecpar->width;
    int height = video_stream->codecpar->height;
    int64_t file_size = fs::file_size(tempFilePath);

    avformat_close_input(&fmt_ctx);
    fs::remove(tempFilePath);

    // Return result to Flutter
    flutter::EncodableMap result_map;
    result_map[flutter::EncodableValue("duration")] = flutter::EncodableValue(duration_ms);
    result_map[flutter::EncodableValue("width")] = flutter::EncodableValue(width);
    result_map[flutter::EncodableValue("height")] = flutter::EncodableValue(height);
    result_map[flutter::EncodableValue("fileSize")] = flutter::EncodableValue(file_size);

    result->Success(flutter::EncodableValue(result_map));
}

}  // namespace pro_video_editor

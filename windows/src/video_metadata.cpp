#include "video_metadata.h"

#include <windows.h>
#include <mfapi.h>
#include <mfidl.h>
#include <mfreadwrite.h>
#include <propvarutil.h>
#include <shlwapi.h>
#include <combaseapi.h>
#include <flutter/standard_method_codec.h>
#include <string>
#include <vector>
#include <algorithm>

#pragma comment(lib, "mfplat.lib")
#pragma comment(lib, "mfreadwrite.lib")
#pragma comment(lib, "mfuuid.lib")
#pragma comment(lib, "shlwapi.lib")

namespace pro_video_editor {

	void HandleGetVideoInformation(
		const flutter::EncodableMap& args,
		std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
		// Extract videoBytes
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

		// Extract extension
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
		std::wstring extension(extStr->begin(), extStr->end());

		// Generate temp file path
		wchar_t temp_path[MAX_PATH];
		GetTempPathW(MAX_PATH, temp_path);
		GUID guid;
		CoCreateGuid(&guid);
		wchar_t guidStr[64];
		StringFromGUID2(guid, guidStr, 64);

		std::wstring temp_file = std::wstring(temp_path) + L"vid_" + guidStr + L"." + extension;
		temp_file.erase(std::remove(temp_file.begin(), temp_file.end(), L'{'), temp_file.end());
		temp_file.erase(std::remove(temp_file.begin(), temp_file.end(), L'}'), temp_file.end());

		// Write video to temp file
		HANDLE file_handle = CreateFileW(temp_file.c_str(), GENERIC_WRITE, 0, nullptr, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, nullptr);
		if (file_handle == INVALID_HANDLE_VALUE) {
			result->Error("FileError", "Failed to create temp file");
			return;
		}
		DWORD bytes_written;
		if (!WriteFile(file_handle, videoBytes->data(), static_cast<DWORD>(videoBytes->size()), &bytes_written, nullptr)) {
			CloseHandle(file_handle);
			DeleteFileW(temp_file.c_str());
			result->Error("FileError", "Failed to write to temp file");
			return;
		}
		CloseHandle(file_handle);

		// Re-open for size
		file_handle = CreateFileW(temp_file.c_str(), GENERIC_READ, FILE_SHARE_READ, nullptr, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, nullptr);
		if (file_handle == INVALID_HANDLE_VALUE) {
			DeleteFileW(temp_file.c_str());
			result->Error("FileError", "Failed to open temp file for reading size");
			return;
		}
		LARGE_INTEGER file_size;
		if (!GetFileSizeEx(file_handle, &file_size)) {
			CloseHandle(file_handle);
			DeleteFileW(temp_file.c_str());
			result->Error("FileError", "Failed to get file size");
			return;
		}
		CloseHandle(file_handle);

		// Media Foundation setup
		IMFSourceReader* source_reader = nullptr;
		IMFAttributes* attributes = nullptr;
		HRESULT hr = MFCreateAttributes(&attributes, 1);
		if (FAILED(hr)) {
			DeleteFileW(temp_file.c_str());
			result->Error("MediaError", "Failed to create attributes");
			return;
		}
		hr = MFCreateSourceReaderFromURL(temp_file.c_str(), attributes, &source_reader);
		attributes->Release();
		if (FAILED(hr)) {
			DeleteFileW(temp_file.c_str());
			result->Error("MediaError", "Failed to create source reader");
			return;
		}

		// Get duration
		PROPVARIANT duration_var;
		PropVariantInit(&duration_var);
		double duration_ms = 0.0;
		hr = source_reader->GetPresentationAttribute(static_cast<DWORD>(MF_SOURCE_READER_MEDIASOURCE), MF_PD_DURATION, &duration_var);
		if (SUCCEEDED(hr) && duration_var.vt == VT_UI8) {
			duration_ms = static_cast<double>(duration_var.uhVal.QuadPart) / 10'000;
		}
		PropVariantClear(&duration_var);

		// Get dimensions
		UINT32 width = 0, height = 0;
		IMFMediaType* media_type = nullptr;
		hr = source_reader->GetNativeMediaType(static_cast<DWORD>(MF_SOURCE_READER_FIRST_VIDEO_STREAM), 0, &media_type);
		if (SUCCEEDED(hr) && media_type) {
			MFGetAttributeSize(media_type, MF_MT_FRAME_SIZE, &width, &height);
			media_type->Release();
		}

		source_reader->Release();
		DeleteFileW(temp_file.c_str());

		// Return result
		flutter::EncodableMap result_map;
		result_map[flutter::EncodableValue("duration")] = flutter::EncodableValue(duration_ms);
		result_map[flutter::EncodableValue("width")] = flutter::EncodableValue(static_cast<int>(width));
		result_map[flutter::EncodableValue("height")] = flutter::EncodableValue(static_cast<int>(height));
		result_map[flutter::EncodableValue("fileSize")] = flutter::EncodableValue(static_cast<int64_t>(file_size.QuadPart));

		result->Success(flutter::EncodableValue(result_map));
	}

}  // namespace pro_video_editor
import 'dart:io';

import 'package:fishkart_vendor/exceptions/local_files_handling/image_picking_exceptions.dart';
import 'package:fishkart_vendor/exceptions/local_files_handling/local_file_handling_exception.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

// Result class to return both path and XFile
class ImagePickResult {
  final String path;
  final XFile xFile;

  ImagePickResult({required this.path, required this.xFile});
}

Future<ImagePickResult> choseImageFromLocalFiles(
  BuildContext context, {
  int maxSizeInKB = 1024,
  int minSizeInKB = 5,
}) async {
  // Skip permission request on web platforms as it's not supported
  if (!kIsWeb) {
    PermissionStatus storageStatus;
    PermissionStatus photosStatus;
    if (Platform.isAndroid) {
      storageStatus = await Permission.storage.request();
      photosStatus = await Permission.photos.request();
      // Check if either permission is permanently denied
      if (storageStatus.isPermanentlyDenied ||
          photosStatus.isPermanentlyDenied) {
        // Optionally, open app settings automatically or instruct user to tap a button
        throw LocalFileHandlingStorageReadPermissionDeniedException(
          message:
              "Permission permanently denied. Please tap here to open app settings and enable storage/photos permission.",
        );
      }
      // Check if either permission is granted
      if (!storageStatus.isGranted && !photosStatus.isGranted) {
        throw LocalFileHandlingStorageReadPermissionDeniedException(
          message:
              "Permission required to read storage/photos, please give permission",
        );
      }
    } else if (Platform.isIOS) {
      photosStatus = await Permission.photos.request();
      if (photosStatus.isPermanentlyDenied) {
        throw LocalFileHandlingStorageReadPermissionDeniedException(
          message:
              "Permission permanently denied. Please tap here to open app settings and enable photos permission.",
        );
      }
      if (!photosStatus.isGranted) {
        throw LocalFileHandlingStorageReadPermissionDeniedException(
          message: "Permission required to read photos, please give permission",
        );
      }
    } else {
      photosStatus = await Permission.photos.request();
      if (photosStatus.isPermanentlyDenied) {
        throw LocalFileHandlingStorageReadPermissionDeniedException(
          message:
              "Permission permanently denied. Please tap here to open app settings and enable photos permission.",
        );
      }
      // Helper to open app settings for permissions
      Future<void> openAppSettingsForPermissions() async {
        await openAppSettings();
      }

      if (!photosStatus.isGranted) {
        throw LocalFileHandlingStorageReadPermissionDeniedException(
          message: "Permission required to read photos, please give permission",
        );
      }
    }
  }

  final imgPicker = ImagePicker();
  final imgSource = await showDialog(
    builder: (context) {
      return AlertDialog(
        title: Text("Chose image source"),
        actions: [
          TextButton(
            child: Text("Camera"),
            onPressed: () {
              Navigator.pop(context, ImageSource.camera);
            },
          ),
          TextButton(
            child: Text("Gallery"),
            onPressed: () {
              Navigator.pop(context, ImageSource.gallery);
            },
          ),
        ],
      );
    },
    context: context,
  );
  if (imgSource == null)
    throw LocalImagePickingInvalidImageException(
      message: "No image source selected",
    );
  final XFile? imagePicked = await imgPicker.pickImage(source: imgSource);
  if (imagePicked == null) {
    throw LocalImagePickingInvalidImageException();
  } else {
    // For web, we need to handle file size differently
    int fileLength;
    if (kIsWeb) {
      // On web, use the bytes length from XFile
      final bytes = await imagePicked.readAsBytes();
      fileLength = bytes.length;
    } else {
      // On mobile platforms, use File.length()
      fileLength = await File(imagePicked.path).length();
    }

    if (fileLength > (maxSizeInKB * 1024) ||
        fileLength < (minSizeInKB * 1024)) {
      throw LocalImagePickingFileSizeOutOfBoundsException(
        message: "Image size should not exceed 1MB",
      );
    } else {
      // Return both path and XFile for better compatibility
      return ImagePickResult(path: imagePicked.path, xFile: imagePicked);
    }
  }
}

// Legacy function for backward compatibility
Future<String> choseImageFromLocalFilesLegacy(
  BuildContext context, {
  int maxSizeInKB = 1024,
  int minSizeInKB = 5,
}) async {
  final result = await choseImageFromLocalFiles(
    context,
    maxSizeInKB: maxSizeInKB,
    minSizeInKB: minSizeInKB,
  );
  return result.path;
}

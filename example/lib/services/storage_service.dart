import 'dart:convert';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import '../models/file_item.dart';
import 'pdf_service.dart';

class StorageService {
  static const String _filesKey = 'saved_files';
  static const String _recentFilesKey = 'recent_files';
  static const String _historyPrefix = 'tool_history_';
  static const String _userKey = 'user_data';

  // Notifies listeners whenever files or recent files change
  static final ValueNotifier<int> changes = ValueNotifier<int>(0);

  // User Management
  static Future<void> saveUserData({
    required String email,
    required String name,
    required String loginMethod,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final userData = {
      'email': email,
      'name': name,
      'login_method': loginMethod,
      'login_time': DateTime.now().toIso8601String(),
    };
    await prefs.setString(_userKey, jsonEncode(userData));
    await prefs.setBool('is_logged_in', true);
  }

  static Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString(_userKey);
    if (userDataString != null) {
      return jsonDecode(userDataString);
    }
    return null;
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_logged_in') ?? false;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('is_logged_in');
    await prefs.remove(_userKey);
  }

  // File Management - Save actual files to device
  static Future<Map<String, dynamic>?> saveScannedDocument({
    required String title,
    required String content,
    required String type,
    Uint8List? imageData,
    String? imagePath,
    List<String>? imagePaths,
    String format = 'JPEG',
    String quality = 'Regular',
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final directory = await getApplicationDocumentsDirectory();
      final documentsPath = '${directory.path}/ProScan';
      
      // Create ProScan directory if it doesn't exist
      final documentsDir = Directory(documentsPath);
      if (!await documentsDir.exists()) {
        await documentsDir.create(recursive: true);
      }
      
      // Generate unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${title.replaceAll(RegExp(r'[^\w\s-]'), '')}_$timestamp';
      String filePath;
      int fileSize = 0;
      final List<String> savedImagePaths = [];
      String? previewImagePath;

      // Save file based on type
      if (imageData != null) {
        // Save image data
        filePath = '$documentsPath/$fileName.jpg';
        final file = File(filePath);
        await file.writeAsBytes(imageData);
        fileSize = imageData.length;
        savedImagePaths.add(filePath);
        previewImagePath = filePath;

        // Convert single image to PDF when requested
        if (format.toUpperCase() == 'PDF') {
          final pdfPath = await PdfService.convertImagesToPdf(
            imagePaths: [filePath],
            fileName: fileName,
            quality: quality,
          );
          if (pdfPath != null) {
            filePath = pdfPath;
            fileSize = await PdfService.getPdfSize(pdfPath);
          }
        }
      } else if (imagePaths != null && imagePaths.isNotEmpty) {
        // Copy multiple images into app storage
        String? firstSaved;
        for (int i = 0; i < imagePaths.length; i++) {
          final src = imagePaths[i];
          final sourceFile = src.startsWith('file://')
              ? File.fromUri(Uri.parse(src))
              : File(src);
          if (await sourceFile.exists()) {
            final dest = '$documentsPath/${fileName}_${i + 1}.jpg';
            await sourceFile.copy(dest);
            savedImagePaths.add(dest);
            if (firstSaved == null) {
              firstSaved = dest;
              fileSize = await File(dest).length();
            }
          } else {
            print('Source image file does not exist for index $i');
          }
        }
        if (savedImagePaths.isEmpty) {
          filePath = '$documentsPath/$fileName.txt';
          final file = File(filePath);
          await file.writeAsString(content);
          fileSize = content.length;
        }
        
        // Convert to PDF if format is PDF
        if (format.toUpperCase() == 'PDF' && savedImagePaths.isNotEmpty) {
          previewImagePath = firstSaved;
          print('Converting ${savedImagePaths.length} images to PDF...');
          final pdfPath = await PdfService.convertImagesToPdf(
            imagePaths: savedImagePaths,
            fileName: fileName,
            quality: quality,
          );
          
          if (pdfPath != null) {
            filePath = pdfPath;
            fileSize = await PdfService.getPdfSize(pdfPath);
            savedImagePaths.clear();
            print('PDF created: $pdfPath (${fileSize} bytes)');
          } else {
            print('PDF conversion failed, using image files');
            filePath = firstSaved ?? '$documentsPath/$fileName.txt';
          }
        } else {
          filePath = firstSaved ?? '$documentsPath/$fileName.txt';
        }
      } else if (imagePath != null) {
        // Check if the source file exists and copy it
        final sourceFile = imagePath.startsWith('file://')
            ? File.fromUri(Uri.parse(imagePath))
            : File(imagePath);
        if (await sourceFile.exists()) {
          filePath = '$documentsPath/$fileName.jpg';
          await sourceFile.copy(filePath);
          fileSize = await sourceFile.length();
          previewImagePath = filePath;
          print('Copied image from $imagePath to $filePath');

          // Convert single image to PDF when requested
          if (format.toUpperCase() == 'PDF') {
            final pdfPath = await PdfService.convertImagesToPdf(
              imagePaths: [filePath],
              fileName: fileName,
              quality: quality,
            );
            if (pdfPath != null) {
              filePath = pdfPath;
              fileSize = await PdfService.getPdfSize(pdfPath);
              savedImagePaths.clear();
              print('PDF created: $pdfPath (${fileSize} bytes)');
            } else {
              print('PDF conversion failed, using image file');
            }
          }
        } else {
          print('Source image file does not exist');
          // Save as text placeholder if image doesn't exist
          filePath = '$documentsPath/$fileName.txt';
          final file = File(filePath);
          await file.writeAsString(content);
          fileSize = content.length;
        }
      } else {
        // Save as text/PDF placeholder
        filePath = '$documentsPath/$fileName.txt';
        final file = File(filePath);
        await file.writeAsString(content);
        fileSize = content.length;
      }
      
      // Create new file item with actual file path
      final newFile = FileItem(
        name: title,
        type: 'file',
        fileCount: savedImagePaths.isNotEmpty ? savedImagePaths.length : 1,
        date: _formatDate(DateTime.now()),
        thumbnail: _getThumbnailForType(type),
      );

      // Save to files list
      final filesString = prefs.getString(_filesKey) ?? '[]';
      final filesList = List<Map<String, dynamic>>.from(jsonDecode(filesString));
      final fileJson = newFile.toJson();
      fileJson['filePath'] = filePath;
      fileJson['fileSize'] = fileSize;
      if (savedImagePaths.isNotEmpty) {
        fileJson['imagePaths'] = savedImagePaths;
      }
      if (previewImagePath != null) {
        fileJson['previewImagePath'] = previewImagePath;
      }
      filesList.insert(0, fileJson); // Add to beginning
      await prefs.setString(_filesKey, jsonEncode(filesList));

      // Save to recent files
      final recentFile = {
        'title': title,
        'date': _formatDate(DateTime.now()),
        'content': content,
        'thumbnail': _getThumbnailForType(type),
        'filePath': filePath,
        'fileSize': fileSize,
        if (savedImagePaths.isNotEmpty) 'imagePaths': savedImagePaths,
        if (previewImagePath != null) 'previewImagePath': previewImagePath,
      };
      
      final recentFilesString = prefs.getString(_recentFilesKey) ?? '[]';
      final recentFilesList = List<Map<String, dynamic>>.from(jsonDecode(recentFilesString));
      recentFilesList.insert(0, recentFile); // Add to beginning
      
      // Keep only last 20 recent files
      if (recentFilesList.length > 20) {
        recentFilesList.removeRange(20, recentFilesList.length);
      }
      
      await prefs.setString(_recentFilesKey, jsonEncode(recentFilesList));

      // Emit change event so UIs can refresh immediately
      changes.value = changes.value + 1;

      return {
        'filePath': filePath,
        'imagePaths': savedImagePaths,
        if (previewImagePath != null) 'previewImagePath': previewImagePath,
      };
    } catch (e) {
      print('Error saving document: $e');
      return null;
    }
  }

  static Future<void> addExternalFile({
    required String name,
    required String filePath,
    int? fileSize,
    List<String>? imagePaths,
    String? previewImagePath,
    String type = 'document',
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final filesString = prefs.getString(_filesKey) ?? '[]';
      final filesList = List<Map<String, dynamic>>.from(jsonDecode(filesString));

      final size = fileSize ?? await File(filePath).length();
      final item = FileItem(
        name: name,
        type: 'file',
        fileCount: (imagePaths?.isNotEmpty ?? false) ? imagePaths!.length : 1,
        date: _formatDate(now),
        thumbnail: _getThumbnailForType(type),
      );
      final json = item.toJson();
      json['filePath'] = filePath;
      json['fileSize'] = size;
      if (imagePaths != null && imagePaths.isNotEmpty) json['imagePaths'] = imagePaths;
      if (previewImagePath != null) json['previewImagePath'] = previewImagePath;
      filesList.insert(0, json);
      await prefs.setString(_filesKey, jsonEncode(filesList));

      final recentFilesString = prefs.getString(_recentFilesKey) ?? '[]';
      final recentFilesList = List<Map<String, dynamic>>.from(jsonDecode(recentFilesString));
      recentFilesList.insert(0, {
        'title': name,
        'date': _formatDate(now),
        'thumbnail': _getThumbnailForType(type),
        'filePath': filePath,
        'fileSize': size,
        if (imagePaths != null && imagePaths.isNotEmpty) 'imagePaths': imagePaths,
        if (previewImagePath != null) 'previewImagePath': previewImagePath,
      });
      if (recentFilesList.length > 20) {
        recentFilesList.removeRange(20, recentFilesList.length);
      }
      await prefs.setString(_recentFilesKey, jsonEncode(recentFilesList));

      changes.value = changes.value + 1;
    } catch (e) {
      print('addExternalFile error: $e');
    }
  }

  static Future<void> addHistory(String tool, Map<String, dynamic> entry) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_historyPrefix$tool';
      final listString = prefs.getString(key) ?? '[]';
      final list = List<Map<String, dynamic>>.from(jsonDecode(listString));
      list.insert(0, entry);
      if (list.length > 50) list.removeRange(50, list.length);
      await prefs.setString(key, jsonEncode(list));
    } catch (e) {
      print('addHistory error: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getHistory(String tool) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_historyPrefix$tool';
      final listString = prefs.getString(key) ?? '[]';
      return List<Map<String, dynamic>>.from(jsonDecode(listString));
    } catch (e) {
      return [];
    }
  }

  static Future<List<FileItem>> getAllFiles() async {
    final prefs = await SharedPreferences.getInstance();
    final filesString = prefs.getString(_filesKey) ?? '[]';
    final filesList = List<Map<String, dynamic>>.from(jsonDecode(filesString));
    return filesList.map((json) => FileItem.fromJson(json)).toList();
  }

  static Future<List<Map<String, dynamic>>> getAllFilesRaw() async {
    final prefs = await SharedPreferences.getInstance();
    final filesString = prefs.getString(_filesKey) ?? '[]';
    return List<Map<String, dynamic>>.from(jsonDecode(filesString));
  }

  static Future<List<Map<String, dynamic>>> getRecentFiles() async {
    final prefs = await SharedPreferences.getInstance();
    final recentFilesString = prefs.getString(_recentFilesKey) ?? '[]';
    return List<Map<String, dynamic>>.from(jsonDecode(recentFilesString));
  }

  static Future<void> deleteFile(String fileName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Find and delete actual file from device
      final filesString = prefs.getString(_filesKey) ?? '[]';
      final filesList = List<Map<String, dynamic>>.from(jsonDecode(filesString));
      
      // Find file to delete
      final fileToDelete = filesList.firstWhere(
        (file) => file['name'] == fileName,
        orElse: () => {},
      );
      
      // Delete actual file from device
      if (fileToDelete.isNotEmpty && fileToDelete['filePath'] != null) {
        final file = File(fileToDelete['filePath']);
        if (await file.exists()) {
          await file.delete();
        }
      }
      
      // Remove from files list
      filesList.removeWhere((file) => file['name'] == fileName);
      await prefs.setString(_filesKey, jsonEncode(filesList));

      // Remove from recent files
      final recentFilesString = prefs.getString(_recentFilesKey) ?? '[]';
      final recentFilesList = List<Map<String, dynamic>>.from(jsonDecode(recentFilesString));
      recentFilesList.removeWhere((file) => file['title'] == fileName);
      await prefs.setString(_recentFilesKey, jsonEncode(recentFilesList));

      // Emit change event so UIs can refresh
      changes.value = changes.value + 1;
    } catch (e) {
      print('Error deleting file: $e');
    }
  }

  static Future<void> renameFile(String oldName, String newName) async {
    final prefs = await SharedPreferences.getInstance();

    // Update in files
    final filesString = prefs.getString(_filesKey) ?? '[]';
    final filesList = List<Map<String, dynamic>>.from(jsonDecode(filesString));
    for (var file in filesList) {
      if (file['name'] == oldName) {
        file['name'] = newName;
        break;
      }
    }
    await prefs.setString(_filesKey, jsonEncode(filesList));

    // Update in recent files
    final recentFilesString = prefs.getString(_recentFilesKey) ?? '[]';
    final recentFilesList = List<Map<String, dynamic>>.from(jsonDecode(recentFilesString));
    for (var file in recentFilesList) {
      if (file['title'] == oldName) {
        file['title'] = newName;
        break;
      }
    }
    await prefs.setString(_recentFilesKey, jsonEncode(recentFilesList));

    // Emit change event so UIs can refresh
    changes.value = changes.value + 1;
  }

  static Future<void> createFolder(String folderName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final directory = await getApplicationDocumentsDirectory();
      final folderPath = '${directory.path}/ProScan/$folderName';
      
      // Create actual folder on device
      final folder = Directory(folderPath);
      if (!await folder.exists()) {
        await folder.create(recursive: true);
      }
      
      final newFolder = FileItem(
        name: folderName,
        type: 'folder',
        fileCount: 0,
        date: _formatDate(DateTime.now()),
      );

      final filesString = prefs.getString(_filesKey) ?? '[]';
      final filesList = List<Map<String, dynamic>>.from(jsonDecode(filesString));
      final folderJson = newFolder.toJson();
      folderJson['folderPath'] = folderPath;
      filesList.insert(0, folderJson);
      await prefs.setString(_filesKey, jsonEncode(filesList));
    } catch (e) {
      print('Error creating folder: $e');
    }
  }

  // Get storage info
  static Future<Map<String, dynamic>> getStorageInfo() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final documentsPath = '${directory.path}/ProScan';
      final documentsDir = Directory(documentsPath);
      
      int totalFiles = 0;
      int totalSize = 0;
      
      if (await documentsDir.exists()) {
        await for (final entity in documentsDir.list(recursive: true)) {
          if (entity is File) {
            totalFiles++;
            totalSize += await entity.length();
          }
        }
      }
      
      return {
        'totalFiles': totalFiles,
        'totalSize': totalSize,
        'storagePath': documentsPath,
      };
    } catch (e) {
      return {
        'totalFiles': 0,
        'totalSize': 0,
        'storagePath': 'Unknown',
      };
    }
  }

  // Move file or folder into target folder
  static Future<void> moveItemToFolder({
    required String itemName,
    required String targetFolderName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final filesString = prefs.getString(_filesKey) ?? '[]';
    final filesList = List<Map<String, dynamic>>.from(jsonDecode(filesString));

    Map<String, dynamic>? item;
    Map<String, dynamic>? targetFolder;

    for (final f in filesList) {
      if (f['name'] == itemName) item = f;
      if (f['name'] == targetFolderName && f['type'] == 'folder') targetFolder = f;
    }

    if (item == null || targetFolder == null) {
      return;
    }

    final targetPath = targetFolder['folderPath'];
    if (targetPath == null) return;

    Future<String> moveFilePath(String sourcePath) async {
      try {
        final src = sourcePath.startsWith('file://') ? File.fromUri(Uri.parse(sourcePath)) : File(sourcePath);
        if (!await src.exists()) return sourcePath;
        final fileName = sourcePath.split('/').last;
        final destPath = '$targetPath/$fileName';
        await src.rename(destPath);
        return destPath;
      } catch (_) {
        return sourcePath;
      }
    }

    if (item['type'] == 'folder') {
      final folderPath = item['folderPath'];
      if (folderPath != null) {
        try {
          final src = Directory(folderPath);
          if (await src.exists()) {
            final folderName = folderPath.split('/').last;
            final newDirPath = '$targetPath/$folderName';
            await src.rename(newDirPath);
            item['folderPath'] = newDirPath;
          }
        } catch (_) {}
      }
    } else {
      // Move file
      if (item['filePath'] != null) {
        final newPath = await moveFilePath(item['filePath']);
        item['filePath'] = newPath;
      }
      // Move imagePaths if any
      if (item['imagePaths'] is List) {
        final List<dynamic> images = item['imagePaths'];
        final List<String> newImages = [];
        for (final p in images) {
          if (p is String) {
            newImages.add(await moveFilePath(p));
          }
        }
        item['imagePaths'] = newImages;
      }

      // Update recent files entry
      final recentFilesString = prefs.getString(_recentFilesKey) ?? '[]';
      final recentFilesList = List<Map<String, dynamic>>.from(jsonDecode(recentFilesString));
      for (final rf in recentFilesList) {
        if (rf['title'] == itemName) {
          if (rf['filePath'] != null) {
            rf['filePath'] = item['filePath'];
          }
          if (rf['imagePaths'] is List && item['imagePaths'] is List) {
            rf['imagePaths'] = item['imagePaths'];
          }
          break;
        }
      }
      await prefs.setString(_recentFilesKey, jsonEncode(recentFilesList));
    }

    await prefs.setString(_filesKey, jsonEncode(filesList));
  }

  // Helper methods
  static String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  static String _getThumbnailForType(String type) {
    switch (type.toLowerCase()) {
      case 'document':
        return '📄';
      case 'id_card':
        return '🪪';
      case 'business_card':
        return '💼';
      case 'book':
        return '📖';
      case 'qr_code':
        return '🔲';
      default:
        return '📄';
    }
  }
}

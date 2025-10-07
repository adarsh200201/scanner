import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

import '../models/scanned_doc.dart';

class StorageRepository {
  StorageRepository._();
  static final StorageRepository instance = StorageRepository._();

  static const String boxName = 'scanned_docs';
  static const String baseFolder = 'local_storage';
  static const String docsFolder = 'docs';

  Box<ScannedDoc>? _box;

  Future<void> init() async {
    if (!kIsWeb) {
      await Hive.initFlutter();
    } else {
      await Hive.initFlutter();
    }
    if (!Hive.isAdapterRegistered(29)) {
      Hive.registerAdapter(ScannedDocAdapter());
    }
    _box ??= await Hive.openBox<ScannedDoc>(boxName);
  }

  bool get isReady => _box != null && _box!.isOpen;

  Future<String> ensureDocsDir() async {
    if (kIsWeb) {
      throw UnsupportedError('Local file storage is not supported on web.');
    }
    final Directory appDir = await getApplicationDocumentsDirectory();
    final String base = '${appDir.path}/$baseFolder';
    final Directory baseDir = Directory(base);
    if (!await baseDir.exists()) {
      await baseDir.create(recursive: true);
    }
    final String docsPath = '$base/$docsFolder';
    final Directory docsDir = Directory(docsPath);
    if (!await docsDir.exists()) {
      await docsDir.create(recursive: true);
    }
    return docsPath;
  }

  Future<ScannedDoc> addDocumentFromBytes({
    required String name,
    required Uint8List bytes,
    String extension = 'pdf',
    String type = 'document',
    List<String> tags = const [],
    String? notes,
    bool uploaded = false,
  }) async {
    final dir = await ensureDocsDir();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final safeName = name.replaceAll(RegExp(r'[^\w\s-]'), '').trim();
    final fileName = '${safeName}_$timestamp.$extension';
    final filePath = '$dir/$fileName';

    File? file;
    try {
      file = File(filePath);
      await file.writeAsBytes(bytes, flush: true);
    } catch (e) {
      rethrow;
    }

    final int size = await file.length();
    final doc = ScannedDoc(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
      path: filePath,
      createdAt: DateTime.now(),
      uploaded: uploaded,
      type: type,
      fileSize: size,
      imagePaths: const [],
      previewImagePath: null,
      tags: tags,
      notes: notes,
    );

    try {
      await _ensureBox();
      await _box!.put(doc.id, doc);
      return doc;
    } catch (e) {
      try { await file.delete(); } catch (_) {}
      rethrow;
    }
  }

  Future<ScannedDoc> addDocumentFromExistingPath({
    required String name,
    required String sourcePath,
    String type = 'document',
    List<String> imagePaths = const [],
    String? previewImagePath,
    List<String> tags = const [],
    String? notes,
    bool uploaded = false,
  }) async {
    final dir = await ensureDocsDir();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final safeName = name.replaceAll(RegExp(r'[^\w\s-]'), '').trim();
    final String ext = sourcePath.split('.').last;
    final destPath = '$dir/${safeName}_$timestamp.$ext';

    File? src;
    try {
      src = sourcePath.startsWith('file://') ? File.fromUri(Uri.parse(sourcePath)) : File(sourcePath);
      if (!await src.exists()) {
        throw FileSystemException('Source file does not exist', sourcePath);
      }
      await src.copy(destPath);
    } catch (e) {
      rethrow;
    }

    final int size = await File(destPath).length();
    final doc = ScannedDoc(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
      path: destPath,
      createdAt: DateTime.now(),
      uploaded: uploaded,
      type: type,
      fileSize: size,
      imagePaths: imagePaths,
      previewImagePath: previewImagePath,
      tags: tags,
      notes: notes,
    );

    try {
      await _ensureBox();
      await _box!.put(doc.id, doc);
      return doc;
    } catch (e) {
      try { await File(destPath).delete(); } catch (_) {}
      rethrow;
    }
  }

  Future<void> markUploadedByPath(String path, {bool uploaded = true}) async {
    await _ensureBox();
    for (final key in _box!.keys) {
      final doc = _box!.get(key);
      if (doc != null && doc.path == path) {
        final updated = ScannedDoc(
          id: doc.id,
          name: doc.name,
          path: doc.path,
          createdAt: doc.createdAt,
          uploaded: uploaded,
          type: doc.type,
          fileSize: doc.fileSize,
          imagePaths: doc.imagePaths,
          previewImagePath: doc.previewImagePath,
          tags: doc.tags,
          notes: doc.notes,
        );
        await _box!.put(doc.id, updated);
        break;
      }
    }
  }

  List<ScannedDoc> listDocuments() {
    if (!isReady) return const [];
    return _box!.values.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> renameByPath(String path, String newName) async {
    await _ensureBox();
    for (final key in _box!.keys) {
      final doc = _box!.get(key);
      if (doc != null && doc.path == path) {
        final Directory parent = File(path).parent;
        final String ext = path.contains('.') ? '.${path.split('.').last}' : '';
        final String safeName = newName.replaceAll(RegExp(r'[^\w\s-]'), '').trim();
        final String newPath = '${parent.path}/$safeName$ext';
        try {
          await File(path).rename(newPath);
        } catch (_) {}
        final updated = ScannedDoc(
          id: doc.id,
          name: newName,
          path: newPath,
          createdAt: doc.createdAt,
          uploaded: doc.uploaded,
          type: doc.type,
          fileSize: doc.fileSize,
          imagePaths: doc.imagePaths,
          previewImagePath: doc.previewImagePath,
          tags: doc.tags,
          notes: doc.notes,
        );
        await _box!.put(doc.id, updated);
        break;
      }
    }
  }

  Future<void> deleteByPath(String path) async {
    await _ensureBox();
    String? idToDelete;
    for (final key in _box!.keys) {
      final doc = _box!.get(key);
      if (doc != null && doc.path == path) {
        idToDelete = doc.id;
        break;
      }
    }
    if (idToDelete != null) {
      try { await File(path).delete(); } catch (_) {}
      final doc = _box!.get(idToDelete);
      if (doc != null && doc.imagePaths.isNotEmpty) {
        for (final p in doc.imagePaths) {
          try { await File(p).delete(); } catch (_) {}
        }
      }
      await _box!.delete(idToDelete);
    }
  }

  Future<String?> getPreviewPath(String path) async {
    await _ensureBox();
    for (final key in _box!.keys) {
      final doc = _box!.get(key);
      if (doc != null && doc.path == path) {
        return doc.previewImagePath ?? path;
      }
    }
    return null;
  }

  Future<void> _ensureBox() async {
    if (_box == null || !_box!.isOpen) {
      await init();
    }
  }
}

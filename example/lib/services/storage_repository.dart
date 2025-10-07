import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../models/scanned_doc.dart';

class StorageRepository {
  StorageRepository._();
  static final StorageRepository instance = StorageRepository._();

  static const String boxName = 'scanned_docs';
  Box<ScannedDoc>? _box;

  Future<void> init() async {
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(ScannedDocAdapter());
    }
    _box = await Hive.openBox<ScannedDoc>(boxName);
  }

  bool get isReady => _box != null && _box!.isOpen;

  Future<ScannedDoc> addDocument({
    required String name,
    required String path,
    String type = 'document',
    int fileSize = 0,
    List<String> imagePaths = const [],
    String? previewImagePath,
    bool uploaded = false,
  }) async {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final doc = ScannedDoc(
      id: id,
      name: name,
      path: path,
      createdAt: DateTime.now(),
      uploaded: uploaded,
      type: type,
      fileSize: fileSize,
      imagePaths: imagePaths,
      previewImagePath: previewImagePath,
    );
    await _box!.put(id, doc);
    return doc;
  }

  List<ScannedDoc> listDocuments() {
    if (!isReady) return const [];
    return _box!.values.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<Map<String, dynamic>> listDocumentsAsMaps() {
    return listDocuments().map((d) => {
          'name': d.name,
          'type': 'file',
          'fileCount': d.imagePaths.isNotEmpty ? d.imagePaths.length : 1,
          'date': _formatDate(d.createdAt),
          'thumbnail': '📄',
          'filePath': d.path,
          'fileSize': d.fileSize,
          if (d.imagePaths.isNotEmpty) 'imagePaths': d.imagePaths,
          if (d.previewImagePath != null) 'previewImagePath': d.previewImagePath,
        }).toList();
  }

  Future<void> renameByPath(String path, String newName) async {
    for (final e in _box!.values) {
      if (e.path == path) {
        e.name = newName;
        await _box!.put(e.id, e);
        break;
      }
    }
  }

  Future<void> deleteByPath(String path) async {
    final keys = _box!.keys.toList(growable: false);
    for (final k in keys) {
      final e = _box!.get(k);
      if (e != null && e.path == path) {
        await _box!.delete(k);
        break;
      }
    }
  }

  Future<String> ensureAppDocsDir() async {
    final directory = await getApplicationDocumentsDirectory();
    final documentsPath = '${directory.path}/ProScan';
    final dir = Directory(documentsPath);
    if (!await dir.exists()) await dir.create(recursive: true);
    return documentsPath;
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

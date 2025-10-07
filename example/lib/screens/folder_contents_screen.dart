import 'dart:io';
import 'package:flutter/material.dart';
import '../models/file_item.dart';
import '../services/storage_service.dart';
import 'document_viewer.dart';

class FolderContentsScreen extends StatefulWidget {
  final String folderName;
  final String folderPath;
  const FolderContentsScreen({Key? key, required this.folderName, required this.folderPath}) : super(key: key);

  @override
  State<FolderContentsScreen> createState() => _FolderContentsScreenState();
}

class _FolderContentsScreenState extends State<FolderContentsScreen> {
  List<Map<String, dynamic>> _filesRaw = [];
  List<Map<String, dynamic>> _recent = [];

  bool _isImage(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.jpg') || lower.endsWith('.jpeg') || lower.endsWith('.png');
  }

  String _normalizePath(String path) => path.startsWith('file://')
      ? File.fromUri(Uri.parse(path)).path
      : path;

  int _countFilesUnder(String folderPath) {
    try {
      final basePath = folderPath.endsWith('/') ? folderPath : folderPath + '/';
      int count = 0;
      for (final m in _filesRaw) {
        if (m['type'] == 'file' && m['filePath'] is String) {
          final p = (m['filePath'] as String).replaceAll(RegExp(r'/+'), '/');
          if (p.startsWith(basePath)) count++;
        }
      }
      return count;
    } catch (_) {
      return 0;
    }
  }

  Widget _buildThumbnail(Map<String, dynamic> f) {
    String? candidate;
    if (f['imagePaths'] is List && (f['imagePaths'] as List).isNotEmpty) {
      candidate = (f['imagePaths'] as List).first as String?;
    } else if (f['filePath'] is String && _isImage(f['filePath'])) {
      candidate = f['filePath'] as String;
    }

    if (candidate != null && _isImage(candidate)) {
      final normalized = _normalizePath(candidate);
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        clipBehavior: Clip.hardEdge,
        child: Image.file(
          File(normalized),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Icon(Icons.description, color: Colors.grey),
        ),
      );
    }

    return const Icon(Icons.description, color: Colors.grey);
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final raw = await StorageService.getAllFilesRaw();
    final recent = await StorageService.getRecentFiles();
    setState(() {
      _filesRaw = raw;
      _recent = recent;
    });
  }

  List<Map<String, dynamic>> get _folderItems {
    final String base = widget.folderPath.endsWith('/') ? widget.folderPath : widget.folderPath + '/';
    final List<Map<String, dynamic>> items = [];

    for (final f in _filesRaw) {
      if (f['type'] == 'file' && f['filePath'] is String) {
        final p = f['filePath'] as String;
        if (p.startsWith(base)) {
          items.add(f);
        }
      } else if (f['type'] == 'folder' && f['folderPath'] is String) {
        final p = f['folderPath'] as String;
        if (p.startsWith(base) && p != widget.folderPath) {
          items.add(f);
        }
      }
    }
    return items;
  }

  void _openFile(String name) async {
    try {
      final recent = _recent;
      final matching = recent.firstWhere((r) => r['title'] == name, orElse: () => {});
      if (matching.isNotEmpty && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DocumentViewer(
              documentTitle: name,
              filePath: matching['filePath'],
              content: matching['content'] ?? 'No content available',
              imagePaths: (matching['imagePaths'] as List?)?.cast<String>(),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File path not found.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening file: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _folderItems;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.folderName,
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final f = items[index];
          final isFolder = f['type'] == 'folder';
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: isFolder
                  ? Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.folder, color: Colors.blue[600], size: 24),
                    )
                  : _buildThumbnail(f),
              title: Text(
                f['name'] ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
              ),
              subtitle: isFolder && f['folderPath'] != null
                  ? Text('${_countFilesUnder(f['folderPath'])} files', style: TextStyle(fontSize: 13, color: Colors.grey[600]))
                  : null,
              onTap: isFolder
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FolderContentsScreen(
                            folderName: f['name'],
                            folderPath: f['folderPath'],
                          ),
                        ),
                      );
                    }
                  : () => _openFile(f['name']),
            ),
          );
        },
      ),
    );
  }
}

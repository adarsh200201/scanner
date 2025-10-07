import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'screens/document_viewer.dart';
import 'services/storage_service.dart';
import 'services/share_actions.dart';
import 'screens/search_screen.dart';
import 'scan_screen.dart';
import 'merge_pdf_screen.dart';
import 'compress_pdf_screen.dart';
import 'move_to_folder_screen.dart';

class RecentFilesPage extends StatefulWidget {
  const RecentFilesPage({Key? key}) : super(key: key);

  @override
  State<RecentFilesPage> createState() => _RecentFilesPageState();
}

class _RecentFilesPageState extends State<RecentFilesPage> {
  // Real dynamic file list - loaded from storage
  List<Map<String, dynamic>> _recentFiles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecentFiles();
    StorageService.changes.addListener(_loadRecentFiles);
  }

  Future<void> _loadRecentFiles() async {
    final files = await StorageService.getRecentFiles();
    setState(() {
      _recentFiles = files;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Recent Files',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black),
            onPressed: () async {
              final files = await StorageService.getAllFiles();
              if (!mounted) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SearchScreen(allFiles: files),
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildFilesList(),
    );
  }

  @override
  void dispose() {
    StorageService.changes.removeListener(_loadRecentFiles);
    super.dispose();
  }

  Widget _buildFilesList() {
    if (_recentFiles.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No recent files',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Your recently scanned documents will appear here',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _recentFiles.length,
      itemBuilder: (context, index) {
        final file = _recentFiles[index];
        return _buildFileItem(file);
      },
    );
  }

  Widget _buildFileItem(Map<String, dynamic> file) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: _buildFileThumbnail(file),
        title: Text(
          file['title'] ?? 'Document',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          file['date'] ?? '',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () => _showShareModal(file),
              icon: const Icon(Icons.share, color: Colors.grey),
            ),
            IconButton(
              onPressed: () => _showFileOptions(file),
              icon: const Icon(Icons.more_vert, color: Colors.grey),
            ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DocumentViewer(
                documentTitle: file['title'] ?? 'Document',
                filePath: file['filePath'],
                content: file['content'],
                imagePaths: (file['imagePaths'] as List?)?.cast<String>(),
              ),
            ),
          );
        },
      ),
    );
  }

  void _openDocument(Map<String, dynamic> file) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DocumentViewer(
                documentTitle: file['title'] ?? 'Document',
                filePath: file['filePath'],
                content: file['content'],
                imagePaths: (file['imagePaths'] as List?)?.cast<String>(),
              ),
      ),
    );
  }

  void _showShareModal(Map<String, dynamic> file) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ShareModal(file: file),
    );
  }

  void _showFileOptions(Map<String, dynamic> file) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => FileOptionsModal(file: file),
    ).then((value) {
      if (value == 'updated') {
        _loadRecentFiles();
      }
    });
  }
  Widget _buildFileThumbnail(Map<String, dynamic> file) {
    final String? preview = file['previewImagePath'] as String?;
    final List<String>? images = (file['imagePaths'] as List?)?.cast<String>();
    final String? pathCandidate = preview ?? ((images != null && images.isNotEmpty)
        ? images.first
        : (file['filePath'] as String?));

    if (pathCandidate != null && _isImage(pathCandidate)) {
      final normalized = _normalizePath(pathCandidate);
      return Container(
        width: 84,
        height: 140,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        clipBehavior: Clip.hardEdge,
        child: Image.file(
          File(normalized),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _pdfPlaceholder(84, 140),
        ),
      );
    }

    return _pdfPlaceholder(84, 140);
  }

  Widget _buildSmallThumbnail(Map<String, dynamic> file) {
    final String? preview = file['previewImagePath'] as String?;
    final List<String>? images = (file['imagePaths'] as List?)?.cast<String>();
    final String? pathCandidate = preview ?? ((images != null && images.isNotEmpty)
        ? images.first
        : (file['filePath'] as String?));

    if (pathCandidate != null && _isImage(pathCandidate)) {
      final normalized = _normalizePath(pathCandidate);
      return Image.file(
        File(normalized),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Center(child: Icon(Icons.description, color: Colors.grey[400])),
      );
    }

    return Center(child: Icon(Icons.description, color: Colors.grey[400]));
  }

  Widget _pdfPlaceholder(double w, double h) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.description, color: Colors.grey[400], size: 32),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'PDF',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isImage(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.jpg') || lower.endsWith('.jpeg') || lower.endsWith('.png');
  }

  String _normalizePath(String path) => path.startsWith('file://')
      ? File.fromUri(Uri.parse(path)).path
      : path;
}

class ShareModal extends StatelessWidget {
  final Map<String, dynamic> file;

  const ShareModal({Key? key, required this.file}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Share',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 20),
          _buildShareOption(
            context: context,
            icon: Icons.link,
            title: 'Share Link',
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Link copied to clipboard!')),
              );
            },
          ),
          _buildShareOption(
            context: context,
            icon: Icons.description,
            title: 'Share PDF',
            subtitle: '(1.2 MB)',
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('PDF exported successfully!')),
              );
            },
          ),
          _buildShareOption(
            context: context,
            icon: Icons.description,
            title: 'Share Word',
            subtitle: '(456 KB)',
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Word document exported!')),
              );
            },
          ),
          _buildShareOption(
            context: context,
            icon: Icons.image,
            title: 'Share JPG',
            subtitle: '(800 KB)',
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('JPG image exported!')),
              );
            },
          ),
          _buildShareOption(
            context: context,
            icon: Icons.image,
            title: 'Share PNG',
            subtitle: '(568 KB)',
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('PNG image exported!')),
              );
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildShareOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[700]),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.black,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            )
          : null,
      onTap: onTap,
    );
  }
}

class FileOptionsModal extends StatelessWidget {
  final Map<String, dynamic> file;

  const FileOptionsModal({Key? key, required this.file}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
          // Document info
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                clipBehavior: Clip.hardEdge,
                child: Builder(
                  builder: (_) {
                    final String? preview = file['previewImagePath'] as String?;
                    final List<String>? images = (file['imagePaths'] as List?)?.cast<String>();
                    final String? candidate = preview ?? ((images != null && images.isNotEmpty)
                        ? images.first
                        : (file['filePath'] as String?));
                    if (candidate != null) {
                      final lower = candidate.toLowerCase();
                      final isImage = lower.endsWith('.jpg') || lower.endsWith('.jpeg') || lower.endsWith('.png');
                      if (isImage) {
                        final normalized = candidate.startsWith('file://')
                            ? File.fromUri(Uri.parse(candidate)).path
                            : candidate;
                        return Image.file(
                          File(normalized),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Center(child: Icon(Icons.description, color: Colors.grey[400])),
                        );
                      }
                    }
                    return Center(child: Icon(Icons.description, color: Colors.grey[400]));
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      file['title'] ?? 'Document',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      file['date'] ?? '',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 10),
          // Options
          _buildOption(
            icon: Icons.share,
            title: 'Share',
            onTap: () {
              final List<String>? images = (file['imagePaths'] as List?)?.cast<String>();
              final String? path = file['filePath'] as String?;
              final title = file['title']?.toString() ?? 'Document';
              final paths = (images != null && images.isNotEmpty)
                  ? images
                  : (path != null ? [path] : <String>[]);
              ShareActions.sharePaths(context, title, paths);
            },
          ),
          _buildOption(
            icon: Icons.save_alt,
            title: 'Save to Gallery',
            onTap: () {
              final List<String>? images = (file['imagePaths'] as List?)?.cast<String>();
              final String? path = file['filePath'] as String?;
              final String? preview = file['previewImagePath'] as String?;
              final title = file['title']?.toString() ?? 'Document';
              List<String> paths = [];
              if (images != null && images.isNotEmpty) {
                paths = images;
              } else if (preview != null && preview.isNotEmpty) {
                paths = [preview];
              } else if (path != null) {
                paths = [path];
              }
              ShareActions.saveImagesToGallery(context, title, paths);
            },
          ),
          if (!((file['filePath'] as String?)?.toLowerCase().endsWith('.pdf') ?? false))
            _buildOption(
              icon: Icons.picture_as_pdf,
              title: 'Convert to PDF',
              onTap: () async {
                final List<String>? images = (file['imagePaths'] as List?)?.cast<String>();
                final String? path = file['filePath'] as String?;
                final baseTitle = file['title']?.toString() ?? 'Document';
                final paths = (images != null && images.isNotEmpty)
                    ? images
                    : (path != null ? [path] : <String>[]);
                if (paths.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Nothing to convert')),
                  );
                  return;
                }
                final saved = await StorageService.saveScannedDocument(
                  title: '${baseTitle}_PDF',
                  content: '',
                  type: 'document',
                  imagePaths: paths,
                  format: 'PDF',
                  quality: 'Regular',
                );
                if (!context.mounted) return;
                if (saved != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Converted to PDF')),
                  );
                  Navigator.pop(context, 'updated');
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Conversion failed')),
                  );
                }
              },
            ),
          _buildOption(
            icon: Icons.edit,
            title: 'Rename',
            onTap: () {
              _showRenameDialog(context);
            },
          ),
          _buildOption(
            icon: Icons.delete,
            title: 'Delete',
            isDestructive: true,
            onTap: () {
              _showDeleteConfirmation(context);
            },
          ),
          const SizedBox(height: 20),
        ],
        ),
      ),
    );
  }

  Widget _buildOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : Colors.grey[700],
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: isDestructive ? Colors.red : Colors.black,
        ),
      ),
      onTap: onTap,
    );
  }


  void _showRenameDialog(BuildContext context) {
    final TextEditingController controller = TextEditingController(text: file['title'] ?? 'Document');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Rename Document',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.black87),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Enter new name',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final oldName = file['title']?.toString() ?? '';
                      final newName = controller.text.trim();
                      if (newName.isNotEmpty && newName != oldName) {
                        await StorageService.renameFile(oldName, newName);
                      }
                      Navigator.pop(context); // close sheet
                      Navigator.pop(context, 'updated'); // close options and refresh
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5B7FFF)),
                    child: const Text('Rename', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Delete Document', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.black87)),
            const SizedBox(height: 12),
            Text('Are you sure you want to delete "${file['title'] ?? 'this document'}"?', style: TextStyle(color: Colors.grey[700])),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final name = file['title']?.toString() ?? '';
                      if (name.isNotEmpty) {
                        await StorageService.deleteFile(name);
                      }
                      Navigator.pop(context); // close sheet
                      Navigator.pop(context, 'updated'); // close options and refresh
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text('Delete', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class RecentFile {
  final String title;
  final String date;
  final String thumbnail;
  final String content;

  RecentFile({
    required this.title,
    required this.date,
    required this.thumbnail,
    required this.content,
  });
}

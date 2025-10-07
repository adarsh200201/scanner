import 'package:flutter/material.dart';
import 'dart:io';
import '../models/file_item.dart';
import '../services/storage_service.dart';
import 'document_viewer.dart';
import 'search_screen.dart';
import 'profile_screen.dart';
import 'login_screen.dart';
import 'folder_contents_screen.dart';
import 'help_center_screen.dart';
import 'privacy_policy_screen.dart';
import '../services/share_actions.dart';

class FilesHomeScreen extends StatefulWidget {
  const FilesHomeScreen({Key? key}) : super(key: key);

  @override
  State<FilesHomeScreen> createState() => _FilesHomeScreenState();
}

class _FilesHomeScreenState extends State<FilesHomeScreen> {
  String _sortBy = 'Date Modified';
  
  // Real dynamic file list - loaded from storage
  List<FileItem> _allFiles = [];
  List<Map<String, dynamic>> _filesRaw = [];
  bool _isLoading = true;
  Map<String, Map<String, dynamic>> _recentIndex = {};
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadFiles();
    StorageService.changes.addListener(_loadFiles);
  }

  Future<void> _loadFiles() async {
    final files = await StorageService.getAllFiles();
    final raw = await StorageService.getAllFilesRaw();
    final recent = await StorageService.getRecentFiles();
    final index = <String, Map<String, dynamic>>{};
    for (final r in recent) {
      final title = r['title']?.toString();
      if (title != null) index[title] = r;
    }
    setState(() {
      _allFiles = files;
      _filesRaw = raw;
      _recentIndex = index;
      _isLoading = false;
    });
  }

  List<FileItem> get _sortedFiles {
    List<FileItem> files = List.from(_allFiles);
    switch (_sortBy) {
      case 'Title (A to Z)':
        files.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'Title (Z to A)':
        files.sort((a, b) => b.name.compareTo(a.name));
        break;
      case 'Date Created':
      case 'Date Modified':
      case 'Date Last Opened':
      case 'Date Added':
        files.sort((a, b) => b.date.compareTo(a.date));
        break;
      case 'Size':
        // Keep default order for now
        break;
    }
    return files;
  }

  @override
  void dispose() {
    StorageService.changes.removeListener(_loadFiles);
    super.dispose();
  }

  List<FileItem> get _visibleFiles {
    final base = _sortedFiles;
    final folderPaths = _filesRaw.where((m) => m['type'] == 'folder' && m['folderPath'] is String)
        .map((m) => (m['folderPath'] as String).replaceAll(RegExp(r'/+'), '/'))
        .toList();

    bool isInAnyFolder(String name) {
      final data = _recentIndex[name];
      String? filePath = data?['filePath'];
      if (filePath == null && data?['imagePaths'] is List && (data!['imagePaths'] as List).isNotEmpty) {
        filePath = (data['imagePaths'] as List).first as String?;
      }
      if (filePath == null) return false;
      final normalized = filePath.replaceAll(RegExp(r'/+'), '/');
      for (final fp in folderPaths) {
        final base = fp.endsWith('/') ? fp : fp + '/';
        if (normalized.startsWith(base)) return true;
      }
      return false;
    }

    final filtered = base.where((f) => f.type == 'folder' || !isInAnyFolder(f.name)).toList();
    if (_searchQuery.isEmpty) return filtered;
    final q = _searchQuery.toLowerCase();
    return filtered.where((f) => f.name.toLowerCase().contains(q)).toList();
  }

  int _getFolderFileCountByName(String folderName) {
    try {
      final folderMap = _filesRaw.firstWhere(
        (m) => m['type'] == 'folder' && m['name'] == folderName && m['folderPath'] is String,
        orElse: () => {},
      );
      if (folderMap.isEmpty) return 0;
      final String basePathRaw = folderMap['folderPath'];
      final String basePath = basePathRaw.endsWith('/') ? basePathRaw : basePathRaw + '/';
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

  int get _totalFileCount {
    return _filesRaw.where((m) => m['type'] == 'file').length;
  }

  void _showSortMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSortOption('Title (A to Z)'),
            _buildSortOption('Title (Z to A)'),
            _buildSortOption('Date Created'),
            _buildSortOption('Date Modified'),
            _buildSortOption('Date Last Opened'),
            _buildSortOption('Date Added'),
            _buildSortOption('Size'),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(String option) {
    return ListTile(
      title: Text(
        option,
        style: TextStyle(
          fontSize: 16,
          color: _sortBy == option ? const Color(0xFF5B7FFF) : Colors.black87,
          fontWeight: _sortBy == option ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      onTap: () {
        setState(() {
          _sortBy = option;
        });
        Navigator.pop(context);
      },
    );
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF5B7FFF)),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                // Handle camera
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFF5B7FFF)),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                // Handle gallery
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showFileOptionsMenu(FileItem file) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // File/Folder Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: file.type == 'folder'
                          ? const Color(0xFF5B7FFF)
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: file.type == 'folder' ? null : Border.all(color: Colors.grey[300]!),
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: file.type == 'folder'
                        ? const Icon(Icons.folder, color: Colors.white, size: 28)
                        : _buildSmallThumbnail(file.name),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          file.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (file.type == 'folder') ...[
                              const Icon(Icons.insert_drive_file, size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                '${_getFolderFileCountByName(file.name)} files',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Text(
                              file.date,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            // Menu Options
            _buildMenuOption(Icons.share_outlined, 'Share', () async {
              Navigator.pop(context);
              await _shareFile(file);
            }),
            _buildMenuOption(Icons.edit_outlined, 'Rename', () {
              Navigator.pop(context);
              _showRenameDialog(file);
            }),
            _buildMenuOption(Icons.folder_outlined, 'Move to Folder', () {
              Navigator.pop(context);
              _showMoveToFolder(file);
            }),
            _buildMenuOption(Icons.delete_outline, 'Delete', () {
              Navigator.pop(context);
              _showDeleteConfirmation(file);
            }, isDestructive: true),
          ],
        ),
      ),
    );
  }

  Future<void> _shareFile(FileItem file) async {
    try {
      final List<String> paths = [];
      Map<String, dynamic>? data = _recentIndex[file.name];
      if (data == null) {
        for (final m in _filesRaw) {
          if (m['name'] == file.name) {
            data = m;
            break;
          }
        }
      }
      if (data != null) {
        if (data['imagePaths'] is List) {
          for (final p in (data['imagePaths'] as List)) {
            if (p is String && p.trim().isNotEmpty) paths.add(p);
          }
        }
        if (paths.isEmpty && data['filePath'] is String) {
          final p = (data['filePath'] as String);
          if (p.trim().isNotEmpty) paths.add(p);
        }
      }
      if (paths.isEmpty) {
        _showSnackBar('No files to share');
        return;
      }
      await ShareActions.sharePaths(context, file.name, paths);
    } catch (e) {
      _showSnackBar('Share failed: $e');
    }
  }

  Widget _buildMenuOption(IconData icon, String title, VoidCallback onTap, {bool showArrow = false, bool isDestructive = false}) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : Colors.black87,
        size: 24,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          color: isDestructive ? Colors.red : Colors.black87,
          fontWeight: FontWeight.w400,
        ),
      ),
      trailing: showArrow ? const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey) : null,
      onTap: onTap,
    );
  }

  void _showNewFolderDialog() {
    final TextEditingController controller = TextEditingController();
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
              'New Folder',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Folder name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
                      if (controller.text.trim().isNotEmpty) {
                        Navigator.pop(context);
                        await StorageService.createFolder(controller.text.trim());
                        await _loadFiles(); // Reload files
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5B7FFF),
                    ),
                    child: const Text(
                      'Create',
                      style: TextStyle(color: Colors.white),
                    ),
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

  void _createNewFolder(String folderName) {
    setState(() {
      _allFiles.insert(
        0,
        FileItem(
          name: folderName,
          type: 'folder',
          fileCount: 0,
          date: DateTime.now().toString().substring(0, 16).replaceAll('-', '/'),
        ),
      );
    });
    _showSnackBar('Folder "$folderName" created');
  }

  void _showMoveToFolder(FileItem item) async {
    final folders = _allFiles.where((f) => f.type == 'folder').toList();
    // Determine current parent folder for the item (if any)
    String? currentParent;
    try {
      final data = _recentIndex[item.name];
      String? filePath = data?['filePath'];
      if (filePath == null && data?['imagePaths'] is List && (data!['imagePaths'] as List).isNotEmpty) {
        filePath = (data['imagePaths'] as List).first as String?;
      }
      if (filePath != null) {
        for (final m in _filesRaw) {
          if (m['type'] == 'folder' && m['folderPath'] is String) {
            final base = (m['folderPath'] as String);
            final b = base.endsWith('/') ? base : base + '/';
            if (filePath.replaceAll(RegExp(r'/+'), '/').startsWith(b)) {
              currentParent = m['name'];
              break;
            }
          }
        }
      }
    } catch (_) {}
    if (folders.isEmpty) {
      _showSnackBar('No folders available');
      return;
    }
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Move to Folder',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
            ...folders.map((folder) {
                  final alreadyIn = currentParent == folder.name || (item.type == 'folder' && item.name == folder.name);
                  return ListTile(
                    leading: const Icon(Icons.folder_outlined, color: Color(0xFF5B7FFF)),
                    title: Text(folder.name),
                    enabled: !alreadyIn,
                    trailing: alreadyIn ? const Icon(Icons.check, color: Colors.grey) : null,
                    onTap: alreadyIn
                        ? null
                        : () async {
                            Navigator.pop(context);
                            await StorageService.moveItemToFolder(
                              itemName: item.name,
                              targetFolderName: folder.name,
                            );
                            await _loadFiles();
                            _showSnackBar('Moved to ${folder.name}');
                          },
                  );
                }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showRenameDialog(FileItem file) {
    final TextEditingController controller = TextEditingController(text: file.name);
    
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
              'Rename',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Enter new name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
                      final newName = controller.text.trim();
                      if (newName.isNotEmpty && newName != file.name) {
                        Navigator.pop(context);
                        await StorageService.renameFile(file.name, newName);
                        await _loadFiles();
                        _showSnackBar('Renamed successfully');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5B7FFF),
                    ),
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

  void _showDeleteConfirmation(FileItem file) {
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
            const Text('Delete', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.black87)),
            const SizedBox(height: 12),
            Text('Are you sure you want to delete "${file.name}"?', style: TextStyle(color: Colors.grey[700])),
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
                      Navigator.pop(context);
                      await StorageService.deleteFile(file.name);
                      await _loadFiles();
                      _showSnackBar('Deleted successfully');
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

  void _showSnackBar(String message) {
    final overlay = Overlay.of(context);
    if (overlay == null) return;
    final entry = OverlayEntry(
      builder: (context) => Positioned(
        left: 16,
        right: 16,
        bottom: 80,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              message,
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 2)).then((_) {
      entry.remove();
    });
  }

  String _formatBytes(int bytes) {
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    double size = bytes.toDouble();
    int i = 0;
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    return '${size.toStringAsFixed(size < 10 && i > 0 ? 1 : 0)} ${suffixes[i]}';
  }

  Future<void> _showStorageInfoSheet() async {
    final info = await StorageService.getStorageInfo();
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final totalFiles = info['totalFiles'] as int? ?? 0;
        final totalSize = info['totalSize'] as int? ?? 0;
        final path = info['storagePath']?.toString() ?? '';
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Storage Info', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: const Color(0xFF5B7FFF).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.folder, color: Color(0xFF5B7FFF)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Files: $totalFiles', style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.black)),
                          const SizedBox(height: 4),
                          Text('Size: ${_formatBytes(totalSize)}', style: TextStyle(color: Colors.grey[700])),
                          const SizedBox(height: 4),
                          Text(path, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey[300]!),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Close'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _showNewFolderDialog();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5B7FFF),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Create Folder', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showMainMenuSheet() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Profile'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.storage_outlined),
              title: const Text('Storage Info'),
              onTap: () async {
                Navigator.pop(context);
                await _showStorageInfoSheet();
              },
            ),
            ListTile(
              leading: const Icon(Icons.create_new_folder_outlined),
              title: const Text('Create New Folder'),
              onTap: () {
                Navigator.pop(context);
                _showNewFolderDialog();
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.help_center_outlined),
              title: const Text('Help Center'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpCenterScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip_outlined),
              title: const Text('Privacy & Terms'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()));
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _assetExists(String path) async {
    try {
      final data = await DefaultAssetBundle.of(context).load(path);
      return data.lengthInBytes > 0;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(12.0),
          child: FutureBuilder<bool>(
            future: _assetExists('assets/app_icon.png'),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox.shrink();
              }
              if (snapshot.data == true) {
                return Image.asset('assets/app_icon.png');
              }
              return const Icon(
                Icons.insert_drive_file,
                color: Color(0xFF5B7FFF),
              );
            },
          ),
        ),
        title: const Text(
          'Files',
          style: TextStyle(
            color: Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black87),
            onPressed: _showMainMenuSheet,
            tooltip: 'Menu',
          )
        ],
      ),
            body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total: $_totalFileCount files',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.sort, color: Colors.black87),
                      onPressed: _showSortMenu,
                    ),
                    IconButton(
                      icon: const Icon(Icons.folder_outlined, color: Colors.black87),
                      onPressed: _showNewFolderDialog,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search files',
                prefixIcon: const Icon(Icons.search, color: Colors.black54),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.black54),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _visibleFiles.length,
              itemBuilder: (context, index) {
                final file = _visibleFiles[index];
                return _buildFileItem(file);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEndDrawer(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.55,
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Color(0xFF5B7FFF)),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  'Menu',
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Profile'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.storage_outlined),
              title: const Text('Storage Info'),
              onTap: () async {
                Navigator.pop(context);
                final info = await StorageService.getStorageInfo();
                if (!mounted) return;
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Storage Info'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total Files: ${info['totalFiles']}'),
                        Text('Total Size: ${info['totalSize']} bytes'),
                        Text('Path: ${info['storagePath']}'),
                      ],
                    ),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
                    ],
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                _showSnackBar('Settings coming soon!');
              },
            ),
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('Help & Support'),
              onTap: () {
                Navigator.pop(context);
                _showSnackBar('Help & Support coming soon!');
              },
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip_outlined),
              title: const Text('Privacy & Terms'),
              onTap: () {
                Navigator.pop(context);
                _showSnackBar('Privacy & Terms coming soon!');
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                await StorageService.logout();
                if (!mounted) return;
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileItem(FileItem file) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
        leading: file.type == 'folder'
            ? Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.folder,
                  color: Colors.blue[600],
                  size: 24,
                ),
              )
            : _buildFileThumbnail(file.name),
        onTap: file.type == 'folder' ? () async {
          // Open folder contents screen
          try {
            final folderMap = _filesRaw.firstWhere(
              (m) => m['type'] == 'folder' && m['name'] == file.name && m['folderPath'] != null,
              orElse: () => {},
            );
            if (folderMap.isNotEmpty) {
              final path = folderMap['folderPath'] as String;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FolderContentsScreen(folderName: file.name, folderPath: path),
                ),
              );
            }
          } catch (_) {}
        } : () {
          // Open document in DocumentEditor for files only
          _openDocument(file);
        },
        title: Text(
          file.name,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            if (file.type == 'folder') ...[
              const Icon(Icons.insert_drive_file, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                '${_getFolderFileCountByName(file.name)} files',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              file.date,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () => _showFileOptionsMenu(file),
        ),
      ),
    );
  }

  Widget _buildFileThumbnail(String fileName) {
    final data = _recentIndex[fileName];
    final String? preview = data?['previewImagePath'] as String?;
    final List<String>? images = (data?['imagePaths'] as List?)?.cast<String>();
    final String? pathCandidate = preview ?? ((images != null && images.isNotEmpty)
        ? images.first
        : (data?['filePath'] as String?));

    if (pathCandidate != null && _isImage(pathCandidate)) {
      final normalized = _normalizePath(pathCandidate);
      return Container(
        width: 72,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        clipBehavior: Clip.hardEdge,
        child: Image.file(
          File(normalized),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _pdfPlaceholder(),
        ),
      );
    }

    return _pdfPlaceholder();
  }

  Widget _buildSmallThumbnail(String fileName) {
    final data = _recentIndex[fileName];
    final String? preview = data?['previewImagePath'] as String?;
    final List<String>? images = (data?['imagePaths'] as List?)?.cast<String>();
    final String? pathCandidate = preview ?? ((images != null && images.isNotEmpty)
        ? images.first
        : (data?['filePath'] as String?));

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

  Widget _pdfPlaceholder() {
    return Container(
      width: 72,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Icon(Icons.description, color: Colors.grey[400]),
    );
  }

  bool _isImage(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.jpg') || lower.endsWith('.jpeg') || lower.endsWith('.png');
  }

  String _normalizePath(String path) => path.startsWith('file://')
      ? File.fromUri(Uri.parse(path)).path
      : path;

  // Open document in DocumentEditor
  void _openDocument(FileItem file) async {
    try {
      // Get recent files to find the file path
      final recentFiles = await StorageService.getRecentFiles();
      final matchingFile = recentFiles.firstWhere(
        (recentFile) => recentFile['title'] == file.name,
        orElse: () => {},
      );
      
      if (matchingFile.isNotEmpty && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DocumentViewer(
              documentTitle: file.name,
              filePath: matchingFile['filePath'],
              content: matchingFile['content'] ?? 'No content available',
              imagePaths: (matchingFile['imagePaths'] as List?)?.cast<String>(),
            ),
          ),
        );
      } else {
        // Fallback for files without matching recent file data
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DocumentViewer(
              documentTitle: file.name,
              filePath: null,
              content: 'Document created on ${file.date}',
            ),
          ),
        );
      }
    } catch (e) {
      _showSnackBar('Error opening document: $e');
    }
  }
}

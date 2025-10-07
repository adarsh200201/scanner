import 'dart:io';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import '../../services/storage_service.dart';
import '../document_viewer.dart';
import 'package:share_plus/share_plus.dart';

enum ViewMode { grid, list }
enum SortBy { name, date, size }

class BrowsePdfTool extends StatefulWidget {
  const BrowsePdfTool({Key? key}) : super(key: key);

  @override
  State<BrowsePdfTool> createState() => _BrowsePdfToolState();
}

class _BrowsePdfToolState extends State<BrowsePdfTool> {
  List<Map<String, dynamic>> _allFiles = [];
  List<Map<String, dynamic>> _filteredFiles = [];
  ViewMode _viewMode = ViewMode.grid;
  SortBy _sortBy = SortBy.date;
  bool _isLoading = true;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  
  // Statistics
  int _totalFiles = 0;
  int _totalSize = 0;
  
  // Selection mode
  bool _isSelectionMode = false;
  Set<int> _selectedIndices = {};

  @override
  void initState() {
    super.initState();
    _loadDocuments();
    StorageService.changes.addListener(_loadDocuments);
  }

  @override
  void dispose() {
    StorageService.changes.removeListener(_loadDocuments);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDocuments() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final files = await StorageService.getAllFilesRaw();

      int totalSize = 0;
      for (var file in files) {
        final sz = file['fileSize'];
        if (sz is int) totalSize += sz;
      }

      setState(() {
        _allFiles = files;
        _filteredFiles = files;
        _totalFiles = files.length;
        _totalSize = totalSize;
        _isLoading = false;
      });
      
      _applySort();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError('Error loading documents: $e');
    }
  }

  void _applySort() {
    setState(() {
      switch (_sortBy) {
        case SortBy.name:
          _filteredFiles.sort((a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''));
          break;
        case SortBy.date:
          _filteredFiles.sort((a, b) => (b['date'] ?? '').compareTo(a['date'] ?? ''));
          break;
        case SortBy.size:
          _filteredFiles.sort((a, b) => (b['fileSize'] ?? 0).compareTo(a['fileSize'] ?? 0));
          break;
      }
    });
  }

  void _searchFiles(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredFiles = _allFiles;
      } else {
        _filteredFiles = _allFiles.where((file) {
          final name = (file['name'] ?? '').toString().toLowerCase();
          return name.contains(query.toLowerCase());
        }).toList();
      }
    });
    _applySort();
  }

  void _openDocument(Map<String, dynamic> file) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DocumentViewer(
          documentTitle: file['name'] ?? 'Document',
          filePath: file['filePath'],
          content: file['content'] ?? '',
          imagePaths: (file['imagePaths'] as List?)?.cast<String>(),
        ),
      ),
    );
  }

  void _shareDocument(Map<String, dynamic> file) async {
    final filePath = file['filePath'] as String?;
    if (filePath != null && await File(filePath).exists()) {
      await Share.shareXFiles([XFile(filePath)]);
    } else {
      _showError('File not found');
    }
  }

  void _deleteDocument(int index) async {
    final file = _filteredFiles[index];
    
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
            Text('Are you sure you want to delete "${file['name']}"?', style: TextStyle(color: Colors.grey[700])),
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
                      // Delete via StorageService to update metadata and emit change
                      final String name = (file['name'] ?? '').toString();
                      if (name.isNotEmpty) {
                        await StorageService.deleteFile(name);
                      }
                      // _loadDocuments will be triggered by StorageService.changes listener
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Document deleted')),
                      );
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

  void _toggleSelection(int index) {
    setState(() {
      if (_selectedIndices.contains(index)) {
        _selectedIndices.remove(index);
        if (_selectedIndices.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedIndices.add(index);
        _isSelectionMode = true;
      }
    });
  }

  void _deleteSelected() {
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
            const Text('Delete Documents', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.black87)),
            const SizedBox(height: 12),
            Text('Are you sure you want to delete ${_selectedIndices.length} document(s)?', style: TextStyle(color: Colors.grey[700])),
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
                      for (var index in _selectedIndices) {
                        final file = _filteredFiles[index];
                        final String name = (file['name'] ?? '').toString();
                        if (name.isNotEmpty) {
                          await StorageService.deleteFile(name);
                        }
                      }
                      setState(() {
                        _selectedIndices.clear();
                        _isSelectionMode = false;
                      });
                      // Refresh will happen via StorageService.changes listener
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Documents deleted')),
                      );
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

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _isSelectionMode ? _buildSelectionAppBar() : _buildNormalAppBar(),
      body: _isLoading ? _buildLoadingState() : _buildContent(),
    );
  }

  PreferredSizeWidget _buildNormalAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () => Navigator.pop(context),
      ),
      title: _isSearching
          ? TextField(
              controller: _searchController,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Search documents...',
                border: InputBorder.none,
              ),
              onChanged: _searchFiles,
            )
          : const Text(
              'My Documents',
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
            ),
      actions: [
        IconButton(
          icon: Icon(_isSearching ? Icons.close : Icons.search, color: Colors.black),
          onPressed: () {
            setState(() {
              _isSearching = !_isSearching;
              if (!_isSearching) {
                _searchController.clear();
                _searchFiles('');
              }
            });
          },
        ),
        IconButton(
          icon: Icon(_viewMode == ViewMode.grid ? Icons.list : Icons.grid_view, color: Colors.black),
          onPressed: () {
            setState(() {
              _viewMode = _viewMode == ViewMode.grid ? ViewMode.list : ViewMode.grid;
            });
          },
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.black),
          onSelected: (value) {
            if (value == 'sort_name') {
              setState(() => _sortBy = SortBy.name);
              _applySort();
            } else if (value == 'sort_date') {
              setState(() => _sortBy = SortBy.date);
              _applySort();
            } else if (value == 'sort_size') {
              setState(() => _sortBy = SortBy.size);
              _applySort();
            } else if (value == 'refresh') {
              _loadDocuments();
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'sort_name', child: Text('Sort by Name')),
            const PopupMenuItem(value: 'sort_date', child: Text('Sort by Date')),
            const PopupMenuItem(value: 'sort_size', child: Text('Sort by Size')),
            const PopupMenuDivider(),
            const PopupMenuItem(value: 'refresh', child: Text('Refresh')),
          ],
        ),
      ],
    );
  }

  PreferredSizeWidget _buildSelectionAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF5B7FFF),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.close, color: Colors.white),
        onPressed: () {
          setState(() {
            _isSelectionMode = false;
            _selectedIndices.clear();
          });
        },
      ),
      title: Text(
        '${_selectedIndices.length} selected',
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.delete, color: Colors.white),
          onPressed: _deleteSelected,
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5B7FFF)),
      ),
    );
  }

  Widget _buildContent() {
    if (_filteredFiles.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        _buildStorageInfo(),
        Expanded(
          child: _viewMode == ViewMode.grid ? _buildGridView() : _buildListView(),
        ),
      ],
    );
  }

  Widget _buildStorageInfo() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5B7FFF), Color(0xFF8B9FFF)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5B7FFF).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStorageStat('Total\nDocuments', _totalFiles.toString(), Icons.folder),
          _buildStorageStat('Total\nSize', _formatFileSize(_totalSize), Icons.storage),
          _buildStorageStat('Scanned\nToday', '0', Icons.today),
        ],
      ),
    );
  }

  Widget _buildStorageStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.white70,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: _filteredFiles.length,
      itemBuilder: (context, index) {
        final file = _filteredFiles[index];
        final isSelected = _selectedIndices.contains(index);
        
        return GestureDetector(
          onTap: () {
            if (_isSelectionMode) {
              _toggleSelection(index);
            } else {
              _openDocument(file);
            }
          },
          onLongPress: () => _toggleSelection(index),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF5B7FFF).withOpacity(0.1) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? const Color(0xFF5B7FFF) : Colors.grey[200]!,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFCE4EC).withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Stack(
                      children: [
                        const Center(
                          child: Icon(Icons.picture_as_pdf, color: Colors.red, size: 48),
                        ),
                        if (isSelected)
                          const Positioned(
                            top: 8,
                            right: 8,
                            child: Icon(Icons.check_circle, color: Color(0xFF5B7FFF), size: 24),
                          ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        file['name'] ?? 'Document',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        file['date'] ?? '',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredFiles.length,
      itemBuilder: (context, index) {
        final file = _filteredFiles[index];
        final isSelected = _selectedIndices.contains(index);
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF5B7FFF).withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? const Color(0xFF5B7FFF) : Colors.grey[200]!,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: ListTile(
            onTap: () {
              if (_isSelectionMode) {
                _toggleSelection(index);
              } else {
                _openDocument(file);
              }
            },
            onLongPress: () => _toggleSelection(index),
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFFFCE4EC).withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.picture_as_pdf, color: Colors.red),
            ),
            title: Text(
              file['name'] ?? 'Document',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              file['date'] ?? '',
              style: const TextStyle(fontSize: 12),
            ),
            trailing: _isSelectionMode
                ? Icon(
                    isSelected ? Icons.check_circle : Icons.circle_outlined,
                    color: isSelected ? const Color(0xFF5B7FFF) : Colors.grey,
                  )
                : PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'open') {
                        _openDocument(file);
                      } else if (value == 'share') {
                        _shareDocument(file);
                      } else if (value == 'delete') {
                        _deleteDocument(index);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'open', child: Text('Open')),
                      const PopupMenuItem(value: 'share', child: Text('Share')),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFFFCE4EC),
              borderRadius: BorderRadius.circular(60),
            ),
            child: const Icon(
              Icons.folder_open,
              size: 60,
              color: Color(0xFFE91E63),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Documents Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start scanning documents to build your library',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Go Back to Home'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE91E63),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

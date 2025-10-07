import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_doc_scanner/flutter_doc_scanner.dart';
import '../recent_files_page.dart';
import 'document_viewer.dart';
import 'save_success_screen.dart';
import 'save_as_dialog.dart';
import '../services/storage_service.dart';
import '../services/share_actions.dart';
import '../services/rate_app.dart';
import 'profile_screen.dart';
import 'search_screen.dart';
import 'login_screen.dart';
import 'package:share_plus/share_plus.dart';
import 'privacy_policy_screen.dart';
import 'dart:io';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<ToolItem> _tools = [
    ToolItem(
      icon: Icons.qr_code_scanner,
      title: 'Scan Code',
      color: Colors.orange,
    ),
    ToolItem(
      icon: Icons.credit_card,
      title: 'ID Card',
      color: Colors.green,
    ),
    ToolItem(
      icon: Icons.menu_book,
      title: 'Book',
      color: Colors.orange,
    ),
    ToolItem(
      icon: Icons.person,
      title: 'ID Photo',
      color: Colors.cyan,
    ),
    ToolItem(
      icon: Icons.image,
      title: 'Image to PDF',
      color: Colors.deepOrange,
    ),
    ToolItem(
      icon: Icons.lock_outline,
      title: 'Protect PDF',
      color: Colors.teal,
    ),
    ToolItem(
      icon: Icons.compress,
      title: 'Compress PDF',
      color: Colors.amber,
    ),
    ToolItem(
      icon: Icons.apps,
      title: 'All Tools',
      color: Colors.blue,
    ),
  ];

  // Real data from storage - loaded dynamically
  List<Map<String, dynamic>> _recentFiles = [];
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _loadData();
    StorageService.changes.addListener(_onStorageChanged);
  }

  Future<void> _loadData() async {
    final recentFiles = await StorageService.getRecentFiles();
    final userData = await StorageService.getUserData();
    setState(() {
      _recentFiles = recentFiles;
      _userData = userData;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'PDF Scanner',
          style: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () async {
              final files = await StorageService.getAllFiles();
              if (!mounted) return;
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SearchScreen(allFiles: files)),
              );
            },
            icon: const Icon(Icons.search, color: Colors.black),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onPressed: _showMoreOptionsSheet,
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tools Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                childAspectRatio: 0.85,
              ),
              itemCount: _tools.length > 4 ? 4 : _tools.length,
              itemBuilder: (context, index) {
                return _buildToolItem(_tools[index]);
              },
            ),
            const SizedBox(height: 12),
            
            // Recent Files Section
            if (_recentFiles.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Files',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_forward,
                      color: Color(0xFF5B7FFF),
                      size: 24,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RecentFilesPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Show 4 documents vertically
              Column(
                children: List.generate(4, (index) {
                  if (index < _recentFiles.length) {
                    // Show actual file
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _buildRecentFileItem(_recentFiles[index]),
                    );
                  } else {
                    // Show placeholder for empty slots
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!, width: 1),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 60,
                            height: 80,
                            margin: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.insert_drive_file,
                              color: Colors.grey[400],
                              size: 24,
                            ),
                          ),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'No document',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[400],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Scan a document to see it here',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[400],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                }),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showMoreOptionsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSheetItem(Icons.star_border, 'Rate App', () {
                  Navigator.pop(context);
                  RateApp.promptAndRequest(context);
                }),
                _buildSheetItem(Icons.feedback_outlined, 'Send Feedback', () {
                  Navigator.pop(context);
                  RateApp.sendGeneralFeedback(context);
                }),
                _buildSheetItem(Icons.share_outlined, 'Share this App', () {
                  Navigator.pop(context);
                  Share.share('Check out ProScan - PDF Scanner');
                }),
                _buildSheetItem(Icons.policy_outlined, 'Privacy Policy', () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()));
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSheetItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Colors.black87),
      title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87)),
      onTap: onTap,
    );
  }


  Widget _buildEndDrawer(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.55,
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(_userData?['name'] ?? 'User'),
              accountEmail: Text(_userData?['email'] ?? ''),
              currentAccountPicture: CircleAvatar(
                backgroundColor: const Color(0xFF5B7FFF),
                child: Text(
                  (_userData?['name'] ?? 'U').toString().substring(0, 1).toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Settings coming soon!')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('Help & Support'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Help & Support coming soon!')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip_outlined),
              title: const Text('Privacy & Terms'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Privacy & Terms coming soon!')),
                );
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

  Widget _buildToolItem(ToolItem tool) {
    return GestureDetector(
      onTap: () {
        _navigateToTool(tool.title);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: tool.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              tool.icon,
              color: tool.color,
              size: 28,
            ),
          ),
          const SizedBox(height: 4),
          Flexible(
            child: Text(
              tool.title,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Navigate to appropriate tool screen
  void _navigateToTool(String toolTitle) {
    Widget? targetScreen;
    
    switch (toolTitle) {
      case 'Scan Code':
        _startScanning(1, scanType: 'qr_code');
        return;
      case 'ID Card':
        _startScanning(1, scanType: 'id_card');
        return;
      case 'Book':
        _startScanning(2, scanType: 'book');
        return;
      case 'ID Photo':
        _startScanning(1, scanType: 'id_photo');
        return;
      case 'Image to PDF':
        _showSnackBar('Choose images to convert to PDF');
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const RecentFilesPage()),
        );
        return;
      case 'Protect PDF':
        _showSnackBar('Please select a document first to protect');
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const RecentFilesPage()),
        );
        return;
      case 'Compress PDF':
        _showSnackBar('Please select a document first to compress');
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const RecentFilesPage()),
        );
        return;
      case 'All Tools':
        targetScreen = const RecentFilesPage();
        break;
    }
    
    if (targetScreen != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => targetScreen!),
      );
    }
  }

  // Scan with camera - directly start document scan
  Future<void> _scanWithCamera() async {
    await _startScanning(1, scanType: 'document');
  }

  // Show scan type selection dialog
  void _showScanTypeDialog() {
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
            const Text(
              'Select Scan Type',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),
            _buildScanTypeOption(
              icon: Icons.description,
              title: 'Document',
              subtitle: 'Scan documents, letters, reports',
              onTap: () {
                Navigator.pop(context);
                _startScanning(1, scanType: 'document');
              },
            ),
            _buildScanTypeOption(
              icon: Icons.credit_card,
              title: 'ID Card',
              subtitle: 'Scan ID cards, licenses, certificates',
              onTap: () {
                Navigator.pop(context);
                _startScanning(1, scanType: 'id_card');
              },
            ),
            _buildScanTypeOption(
              icon: Icons.book,
              title: 'Book',
              subtitle: 'Scan book pages',
              onTap: () {
                Navigator.pop(context);
                _startScanning(2, scanType: 'book');
              },
            ),
            _buildScanTypeOption(
              icon: Icons.business_center,
              title: 'Business Card',
              subtitle: 'Scan business cards',
              onTap: () {
                Navigator.pop(context);
                _startScanning(1, scanType: 'business_card');
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildScanTypeOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFF5B7FFF).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: const Color(0xFF5B7FFF)),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey[600],
        ),
      ),
      onTap: onTap,
    );
  }

  // Start scanning with selected type
  Future<void> _startScanning(int pageCount, {String scanType = 'document'}) async {
    try {
      // Use getScannedDocumentAsImages to get actual image data
      final result = await FlutterDocScanner().getScannedDocumentAsImages(page: pageCount);
      
      if (result != null && mounted) {
        print('Scan result: $result'); // Debug log
        print('Result type: ${result.runtimeType}'); // Debug log
        
        // Generate document title based on scan type and timestamp
        final now = DateTime.now();
        final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
        final dateStr = '${now.day}/${now.month}/${now.year}';
        
        String title;
        switch (scanType) {
          case 'id_card':
            title = 'ID Card $dateStr $timeStr';
            break;
          case 'id_photo':
            title = 'ID Photo $dateStr $timeStr';
            break;
          case 'business_card':
            title = 'Business Card $dateStr $timeStr';
            break;
          case 'book':
            title = 'Book Scan $dateStr $timeStr';
            break;
          case 'qr_code':
            title = 'QR Code $dateStr $timeStr';
            break;
          default:
            title = 'Document $dateStr $timeStr';
        }
        
        // Handle different result types from Flutter Document Scanner
        List<String> imagePaths = [];
        String? primaryImagePath;

        print('Raw scan result type: ${result.runtimeType}');
        print('Raw scan result: $result');

        List<String> _extractPaths(dynamic raw) {
          final out = <String>[];

          void addFrom(dynamic x) {
            if (x == null) return;

            // Handle iterables (flatten nested lists)
            if (x is Iterable) {
              for (final item in x) {
                addFrom(item);
              }
              return;
            }

            // Handle map objects like {imageUri: ..., uri: ..., path: ...}
            if (x is Map) {
              final v = x['imageUri'] ?? x['uri'] ?? x['path'] ?? x['filePath'];
              if (v != null) {
                addFrom(v);
              }
              return;
            }

            // Handle plain string or Page{imageUri=...}
            String s = x.toString();
            // Collect ALL imageUri= occurrences, not just the first
            final matches = RegExp(r'imageUri=([^},\s]+)').allMatches(s).toList();
            if (matches.isNotEmpty) {
              for (final m in matches) {
                out.add(m.group(1)!.trim());
              }
              return;
            }

            // Fallback: push the string as-is
            out.add(s.trim());
          }

          addFrom(raw);

          // Normalize and dedupe
          final paths = out
              .where((s) => s.isNotEmpty)
              .map((p) => p.trim())
              .toSet() // remove duplicates
              .toList();
          return paths;
        }

        // Check if result is a Map (common for document scanners)
        if (result is Map) {
          print('Result is a Map with keys: ${result.keys}');
          final raw = result['Uri'] ?? result['uris'] ?? result['images'] ?? result['paths'] ?? result.values.toList();
          imagePaths = _extractPaths(raw);
        } else if (result is List && result.isNotEmpty) {
          // If result is a list of file paths (multiple images)
          imagePaths = _extractPaths(result);
          print('Multiple images from list: $imagePaths');
        } else if (result is String) {
          // If result is a single file path
          imagePaths = _extractPaths(result);
          print('Single image from string: $result');
        }

        primaryImagePath = imagePaths.isNotEmpty ? imagePaths.first : null;
        print('Final image paths count: ${imagePaths.length}');
        print('Final image paths: $imagePaths');
        print('Primary image path: $primaryImagePath');
        
        // Show Save As dialog before saving
        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => SaveAsDialog(
            defaultFileName: title,
            imagePaths: imagePaths,
            onSave: (fileName, format, quality) async {
              // Save scanned document with user's settings
              final saved = await StorageService.saveScannedDocument(
                title: fileName,
                content: 'Scanned ${scanType.replaceAll('_', ' ')} - $fileName\n\nTotal pages: ${imagePaths.length}\nFormat: $format\nQuality: $quality',
                type: scanType,
                imagePaths: imagePaths,
                format: format,
                quality: quality,
              );

              if (saved != null) {
                // Reload data to show new document in both Recent Files and Files tab
                await _loadData();

                if (!mounted) return;
                // Show confirmation screen with Share, Open, Save to Gallery
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SaveSuccessScreen(
                      title: fileName,
                      filePath: saved['filePath'] as String?,
                      imagePaths: (saved['imagePaths'] as List?)?.cast<String>(),
                      successMessage: format == 'PDF' ? 'Converted to PDF Successfully!' : 'Converted to JPEG Successfully!',
                    ),
                  ),
                );
              } else {
                _showSnackBar('Failed to save document');
              }
            },
          ),
        );
      }
    } catch (e) {
      print('Scan error: $e'); // Debug log
      _showSnackBar('Scan failed: $e');
    }
  }

  // Show scan success dialog
  void _showScanSuccessDialog(String title, String filePath) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('✅ Document Saved'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Document: $title',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Saved to device storage',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'You can find it in Recent Files and Files tab',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Switch to Files tab to show the saved document
              DefaultTabController.of(context)?.animateTo(1);
            },
            child: const Text('View Files'),
          ),
        ],
      ),
    );
  }

  // Build recent file item in list format
  Widget _buildRecentFileItem(Map<String, dynamic> file) {
    return Container(
      margin: EdgeInsets.zero,
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
            // Share button
            IconButton(
              icon: const Icon(Icons.share_outlined, color: Colors.black87),
              onPressed: () {
                _showShareOptions(file);
              },
            ),
            IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.black87),
              onPressed: () => _showFileOptions(file),
            ),
          ],
        ),
        onTap: () {
          // Open document in DocumentViewer
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

  Widget _buildFileThumbnail(Map<String, dynamic> file) {
    final String? preview = file['previewImagePath'] as String?;
    final List<String>? images = (file['imagePaths'] as List?)?.cast<String>();
    final String? pathCandidate = preview ?? ((images != null && images.isNotEmpty)
        ? images.first
        : (file['filePath'] as String?));

    final container = Container(
      width: 60,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
    );

    if (pathCandidate != null && _isImage(pathCandidate)) {
      final normalized = _normalizePath(pathCandidate);
      return Container(
        width: 90,
        height: 160,
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

  Widget _pdfPlaceholder() {
    return Container(
      width: 90,
      height: 160,
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

  // Show share options
  void _showShareOptions(Map<String, dynamic> file) {
    final title = file['title']?.toString() ?? 'Document';
    final filePath = file['filePath'] as String?;
    final imagePaths = (file['imagePaths'] as List?)?.cast<String>();

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
            const Text(
              'Share Document',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.share, color: Color(0xFF5B7FFF)),
              title: const Text('Share'),
              onTap: () {
                Navigator.pop(context);
                final paths = (imagePaths != null && imagePaths.isNotEmpty)
                    ? imagePaths
                    : (filePath != null ? [filePath] : <String>[]);
                ShareActions.sharePaths(context, title, paths);
              },
            ),
            ListTile(
              leading: const Icon(Icons.open_in_new, color: Color(0xFF5B7FFF)),
              title: const Text('Open'),
              onTap: () {
                Navigator.pop(context);
                ShareActions.openViewer(
                  context,
                  title,
                  filePath: filePath,
                  imagePaths: imagePaths,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.save_alt, color: Color(0xFF5B7FFF)),
              title: const Text('Save to Gallery'),
              onTap: () {
                Navigator.pop(context);
                final paths = (imagePaths != null && imagePaths.isNotEmpty)
                    ? imagePaths
                    : (filePath != null ? [filePath] : <String>[]);
                ShareActions.saveImagesToGallery(context, title, paths);
              },
            ),
          ],
        ),
      ),
    );
  }

  // Show file options (reuse Recent Files options)
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
        _loadData();
      }
    });
  }

  void _onStorageChanged() {
    if (mounted) {
      _loadData();
    }
  }

  @override
  void dispose() {
    StorageService.changes.removeListener(_onStorageChanged);
    super.dispose();
  }
}

class ToolItem {
  final IconData icon;
  final String title;
  final Color color;

  ToolItem({
    required this.icon,
    required this.title,
    required this.color,
  });
}

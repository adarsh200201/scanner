import 'package:flutter/material.dart';
import 'package:flutter_doc_scanner/flutter_doc_scanner.dart';
import 'tools/merge_pdf_tool.dart';
import 'tools/split_pdf_tool.dart';
import 'tools/image_to_pdf_tool.dart';
import 'tools/browse_pdf_tool.dart';
import '../compress_pdf_screen.dart';
import '../digital_signature_screen.dart';
import '../protect_pdf_screen.dart';
import '../services/storage_service.dart';
import '../services/rate_app.dart';
import 'privacy_policy_screen.dart';
import 'search_screen.dart';
import 'save_as_dialog.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

class AllToolsScreen extends StatefulWidget {
  const AllToolsScreen({Key? key}) : super(key: key);

  @override
  State<AllToolsScreen> createState() => _AllToolsScreenState();
}

class _AllToolsScreenState extends State<AllToolsScreen> {

  Future<void> _startScanning(int pageCount, {String scanType = 'document'}) async {
    try {
      final result = await FlutterDocScanner().getScannedDocumentAsImages(page: pageCount);
      print('Scan result: $result');
      
      List<String> imagePaths = [];
      
      List<String> _extractPaths(dynamic raw) {
        final List list = raw is List ? raw : [raw];
        return list.map((e) {
          String s = e?.toString() ?? '';
          final match = RegExp(r'imageUri=([^}\s]+)').firstMatch(s);
          if (match != null) {
            s = match.group(1)!;
          }
          if (s.startsWith('Page{') && s.contains('imageUri=')) {
            s = s.replaceFirst(RegExp(r'^Page\{.*imageUri='), '').replaceAll('}', '');
          }
          return s.trim();
        }).where((s) => s.isNotEmpty).toList();
      }
      
      if (result is Map) {
        final raw = result['Uri'] ?? result['uris'] ?? result['images'] ?? result['paths'] ?? result.values.toList();
        imagePaths = _extractPaths(raw);
      } else if (result is List && result.isNotEmpty) {
        imagePaths = _extractPaths(result);
      } else if (result is String) {
        imagePaths = _extractPaths(result);
      }
      
      if (imagePaths.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No images captured')),
        );
        return;
      }
      
      // Generate title
      final now = DateTime.now();
      final dateStr = DateFormat('MMM dd').format(now);
      final timeStr = DateFormat('HH:mm').format(now);
      String title;

      switch (scanType) {
        case 'document':
          title = 'Document $dateStr $timeStr';
          break;
        case 'qr_code':
          title = 'QR Code $dateStr $timeStr';
          break;
        case 'id_card':
          title = 'ID Card $dateStr $timeStr';
          break;
        case 'id_photo':
          title = 'ID Photo $dateStr $timeStr';
          break;
        case 'book':
          title = 'Book $dateStr $timeStr';
          break;
        default:
          title = 'Scan $dateStr $timeStr';
      }

      // Show save dialog and handle saving
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => SaveAsDialog(
          defaultFileName: title,
          imagePaths: imagePaths,
          onSave: (fileName, format, quality) async {
            final saved = await StorageService.saveScannedDocument(
              title: fileName,
              content: 'Scanned ${scanType.replaceAll('_', ' ')} - $fileName\n\nTotal pages: ${imagePaths.length}\nFormat: $format\nQuality: $quality',
              type: scanType,
              imagePaths: imagePaths,
              format: format,
              quality: quality,
            );

            if (saved != null && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Saved as $format successfully!')),
              );
            } else if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Failed to save document')),
              );
            }
          },
        ),
      );
    } catch (e) {
      print('Scanning error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Scanning failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
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
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick Access Tools (same design as home screen)
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 4,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              childAspectRatio: 0.85,
              children: [
                _buildQuickToolItem(
                  icon: Icons.description,
                  label: 'Docs',
                  color: Colors.blue,
                  onTap: () => _startScanning(1, scanType: 'document'),
                ),
                _buildQuickToolItem(
                  icon: Icons.credit_card,
                  label: 'ID Card',
                  color: Colors.green,
                  onTap: () => _startScanning(1, scanType: 'id_card'),
                ),
                _buildQuickToolItem(
                  icon: Icons.menu_book,
                  label: 'Book',
                  color: Colors.orange,
                  onTap: () => _startScanning(2, scanType: 'book'),
                ),
                _buildQuickToolItem(
                  icon: Icons.person,
                  label: 'ID Photo',
                  color: Colors.cyan,
                  onTap: () => _startScanning(1, scanType: 'id_photo'),
                ),
              ],
            ),
            const SizedBox(height: 32),
            
            // PDF Tools Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.9,
              children: [
                _buildToolCard(
                  context,
                  icon: Icons.merge_type,
                  label: 'Merge PDF',
                  color: const Color(0xFFE3F2FD),
                  iconColor: Colors.blue,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const MergePdfTool()),
                    );
                  },
                ),
                _buildToolCard(
                  context,
                  icon: Icons.content_cut,
                  label: 'Split PDF',
                  color: const Color(0xFFE8F5E9),
                  iconColor: Colors.green,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SplitPdfTool()),
                    );
                  },
                ),
                _buildToolCard(
                  context,
                  icon: Icons.image,
                  label: 'Image to PDF',
                  color: const Color(0xFFFFE0CC),
                  iconColor: Colors.deepOrange,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ImageToPdfTool()),
                    );
                  },
                ),
                _buildToolCard(
                  context,
                  icon: Icons.folder_open,
                  label: 'My Documents',
                  color: const Color(0xFFFCE4EC),
                  iconColor: Colors.pink,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const BrowsePdfTool()),
                    );
                  },
                ),
                _buildToolCard(
                  context,
                  icon: Icons.compress,
                  label: 'Compress PDF',
                  color: const Color(0xFFE0F2F1),
                  iconColor: Colors.teal,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CompressPdfScreen(
                          documentTitle: 'New Document',
                          documentContent: '',
                        ),
                      ),
                    );
                  },
                ),
                _buildToolCard(
                  context,
                  icon: Icons.edit,
                  label: 'Digital Signature',
                  color: const Color(0xFFFFF9C4),
                  iconColor: Colors.amber,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DigitalSignatureScreen(
                          documentTitle: 'New Document',
                          documentContent: '',
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
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

  Widget _buildQuickToolItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(height: 4),
          Flexible(
            child: Text(
              label,
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

  Widget _buildToolCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: iconColor),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

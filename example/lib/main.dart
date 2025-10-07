import 'package:flutter/material.dart';
import 'package:flutter_doc_scanner/flutter_doc_scanner.dart';
import 'screens/files_home_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/all_tools_screen.dart';
import 'screens/profile_screen.dart';
import 'services/storage_service.dart';
import 'screens/save_success_screen.dart';
import 'screens/save_as_dialog.dart';
import 'package:flutter/services.dart';

import 'services/firebase.dart';
import 'services/storage_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageRepository.instance.init();
  await AppFirebase.init();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));
  runApp(const FileManagementApp());
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool? isLoggedIn;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final loggedIn = await StorageService.isLoggedIn();
    setState(() {
      isLoggedIn = loggedIn;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoggedIn == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return isLoggedIn! ? const MainScreen() : const LoginScreen();
  }
}

class FileManagementApp extends StatelessWidget {
  const FileManagementApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Doc Scanner',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF5B7FFF)),
        useMaterial3: true,
        snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
      ),
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const FilesHomeScreen(),
    const AllToolsScreen(),
    const ProfileScreen(),
  ];

  void _showScanOptions() {
    // Directly start scanning without showing type selection
    _startScanning(1, 'document');
  }

  Widget _buildScanOption({
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

  Future<void> _startScanning(int pageCount, String scanType) async {
    try {
      final result = await FlutterDocScanner().getScannedDocumentAsImages(page: pageCount);

      if (result != null && mounted) {
        print('Main Scan result: $result'); // Debug log

        // Generate document title based on scan type and timestamp
        final now = DateTime.now();
        final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
        final dateStr = '${now.day}/${now.month}/${now.year}';

        String title;
        switch (scanType) {
          case 'id_card':
            title = 'ID Card $dateStr $timeStr';
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

        List<String> _extractPaths(dynamic raw) {
          final out = <String>[];

          void addFrom(dynamic x) {
            if (x == null) return;
            if (x is Iterable) {
              for (final item in x) addFrom(item);
              return;
            }
            if (x is Map) {
              final v = x['imageUri'] ?? x['uri'] ?? x['path'] ?? x['filePath'] ?? x.values.toList();
              addFrom(v);
              return;
            }
            String s = x.toString();
            final matches = RegExp(r'imageUri=([^},\s]+)').allMatches(s).toList();
            if (matches.isNotEmpty) {
              for (final m in matches) out.add(m.group(1)!.trim());
              return;
            }
            out.add(s.trim());
          }

          addFrom(raw);
          return out.where((s) => s.isNotEmpty).map((p) => p.trim()).toSet().toList();
        }

        if (result is Map) {
          final raw = result['Uri'] ?? result['uris'] ?? result['images'] ?? result['paths'] ?? result.values.toList();
          imagePaths = _extractPaths(raw);
        } else if (result is List && result.isNotEmpty) {
          imagePaths = _extractPaths(result);
        } else if (result is String) {
          imagePaths = _extractPaths(result);
        }

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
                if (!mounted) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SaveSuccessScreen(
                      title: fileName,
                      filePath: saved['filePath'] as String?,
                      imagePaths: (saved['imagePaths'] as List?)?.cast<String>() ??
                          (saved['previewImagePath'] != null ? [saved['previewImagePath'] as String] : null),
                      successMessage: format == 'PDF' ? 'Converted to PDF Successfully!' : 'Converted to JPEG Successfully!',
                    ),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Failed to save document')),
                );
              }
            },
          ),
        );
      }
    } catch (e) {
      print('Main Scan error: $e'); // Debug log
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Scan failed: $e')),
      );
    }
  }

  Widget _buildNavItem(int index, IconData filledIcon, IconData outlinedIcon, String label) {
    final bool active = _currentIndex == index;
    return Expanded(
      child: Semantics(
        selected: active,
        button: true,
        label: label,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => setState(() => _currentIndex = index),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Icon only (no background circle)
                Icon(
                  active ? filledIcon : outlinedIcon,
                  color: active ? const Color(0xFF5B7FFF) : Colors.grey[600],
                  size: 20,
                ),
                const SizedBox(height: 2),
                // Compact text
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                    color: active ? const Color(0xFF5B7FFF) : Colors.grey[600],
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: _screens[_currentIndex],
        floatingActionButton: Transform.translate(
          offset: const Offset(0, 8),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF5B7FFF).withOpacity(0.35),
                  blurRadius: 22,
                  spreadRadius: 2,
                  offset: const Offset(0, 6),
                ),
              ],
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF5B7FFF).withOpacity(0.35),
                  const Color(0xFF5B7FFF).withOpacity(0.15),
                ],
              ),
            ),
            padding: const EdgeInsets.all(2),
            child: FloatingActionButton(
              onPressed: () => _startScanning(1, 'document'),
              backgroundColor: const Color(0xFF5B7FFF),
              elevation: 8,
              shape: const CircleBorder(),
              child: const Icon(Icons.camera_alt, size: 28, color: Colors.white),
            ),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: BottomAppBar(
            color: Colors.white,
            elevation: 14,
            shape: const CircularNotchedRectangle(),
            notchMargin: 8,
            child: SafeArea(
              top: false,
              child: Container(
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.grey[200]!)),
                ),
                child: SizedBox(
                  height: 104,
                  child: Row(
                    children: [
                      _buildNavItem(0, Icons.home, Icons.home_outlined, 'Home'),
                      _buildNavItem(1, Icons.folder, Icons.folder_outlined, 'Files'),
                      const SizedBox(width: 76),
                      _buildNavItem(2, Icons.apps, Icons.apps_outlined, 'Tools'),
                      _buildNavItem(3, Icons.person, Icons.person_outline, 'Profile'),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> _onWillPop() async {
    // If not on the first tab, go back to Home instead of exiting
    if (_currentIndex != 0) {
      setState(() => _currentIndex = 0);
      return false;
    }

    final shouldExit = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF5B7FFF).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.exit_to_app, color: Color(0xFF5B7FFF)),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Exit app?',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Are you sure you want to exit?',
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey[300]!),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Cancel', style: TextStyle(color: Colors.black)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5B7FFF),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Exit', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    ) ?? false;

    if (shouldExit) {
      SystemNavigator.pop();
    }
    // Always consume the back event so dialog can show every time
    return false;
  }
}

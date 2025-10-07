import 'package:firebase_core/firebase_core.dart';

class AppFirebase {
  static bool _inited = false;

  static Future<void> init() async {
    if (_inited) return;
    try {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: 'AIzaSyBhgmkaH7d52EA38Oi5wNBx_ce03feCOmk',
          appId: '1:323763831909:android:772d667aa1a0a0b0a9b28c',
          messagingSenderId: '323763831909',
          projectId: 'sccanner-f6fa0',
          storageBucket: 'sccanner-f6fa0.firebasestorage.app',
        ),
      );
      _inited = true;
    } catch (_) {
      // Ignore if already initialized by other means
      _inited = true;
    }
  }
}

import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import 'login_screen.dart';
import 'package:share_plus/share_plus.dart';
import '../services/rate_app.dart';
import 'privacy_policy_screen.dart';
import 'about_screen.dart';
import 'help_center_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _user;
  bool _loading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final logged = await StorageService.isLoggedIn();
    final user = logged ? await StorageService.getUserData() : null;
    setState(() {
      _isLoggedIn = logged;
      _user = user;
      _loading = false;
    });
  }

  Future<void> _logout() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
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
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text('Logout', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.red)),
              const SizedBox(height: 4),
              Text('Are you sure you want to log out?', style: TextStyle(color: Colors.grey[700])),
              const SizedBox(height: 8),
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
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        try { await FirebaseAuth.instance.signOut(); } catch (_) {}
                        await StorageService.logout();
                        if (!mounted) return;
                        Navigator.pop(context);
                        setState(() {
                          _isLoggedIn = false;
                          _user = null;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Logged out')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5B7FFF),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Yes, Logout', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
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

  void _editName() {
    final controller = TextEditingController(text: _user?['name'] ?? '');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        final bottom = MediaQuery.of(context).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Edit name', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: 'Your name',
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final name = controller.text.trim();
                    if (name.isEmpty) return;
                    final email = _user?['email'] ?? '';
                    final method = _user?['login_method'] ?? 'email';
                    await StorageService.saveUserData(email: email, name: name, loginMethod: method);
                    if (!mounted) return;
                    Navigator.pop(context);
                    _load();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5B7FFF),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        title: const Text('Profile', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!_isLoggedIn) _buildSignInCard() else _buildProfileHeader(),
            const SizedBox(height: 8),

            const Text('General', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.black)),
            const SizedBox(height: 8),
            _settingCard(
              icon: Icons.star_border,
              title: 'Rate App',
              onTap: () => RateApp.promptAndRequest(context),
            ),
            const SizedBox(height: 4),
            _settingCard(
              icon: Icons.feedback_outlined,
              title: 'Send Feedback',
              onTap: () => RateApp.sendGeneralFeedback(context),
            ),
            const SizedBox(height: 4),
            _settingCard(
              icon: Icons.share_outlined,
              title: 'Share this App',
              onTap: () => Share.share('Check out ProScan - PDF Scanner'),
            ),
            const SizedBox(height: 4),
            _settingCard(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy Policy',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen())),
            ),
            const SizedBox(height: 4),
            _settingCard(
              icon: Icons.help_center_outlined,
              title: 'Help Center',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpCenterScreen())),
            ),
            const SizedBox(height: 4),
            _settingCard(
              icon: Icons.info_outline,
              title: 'About',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen())),
            ),


            const SizedBox(height: 16),
            if (_isLoggedIn)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _logout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.logout, color: Colors.white),
                  label: const Text('Logout', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignInCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF5B7FFF), const Color(0xFF8A7DFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: const Color(0xFF5B7FFF).withOpacity(0.25), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Colors.white.withOpacity(0.18), Colors.white.withOpacity(0.08)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person_outline, color: Color(0xFF5B7FFF), size: 28),
                ),
              ),
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)],
                  ),
                  child: const Icon(Icons.login_rounded, color: Color(0xFF5B7FFF), size: 14),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text('Sign in to sync', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                SizedBox(height: 4),
                Text('Access all your notes everywhere', style: TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
            icon: const Icon(Icons.arrow_outward_rounded, size: 18),
            label: const Text('Sign In'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF5B7FFF),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF5B7FFF), const Color(0xFF5B7FFF).withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: CircleAvatar(
              radius: 30,
              backgroundColor: Colors.white,
              child: Text(
                _user?['name']?.substring(0, 1).toUpperCase() ?? 'U',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF5B7FFF)),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_user?['name'] ?? 'User', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(_user?['email'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(12)),
                  child: Text(_user?['login_method'] == 'google' ? 'Google Account' : 'Email Account', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          const SizedBox.shrink(),
        ],
      ),
    );
  }

  Widget _buildAuthButtonsRow() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ElevatedButton.icon(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
          icon: Container(
            width: 18,
            height: 18,
            decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: const Text('G', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
          ),
          label: const Text('Sign in with Google'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF5B7FFF),
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
        ),
        ElevatedButton.icon(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
          icon: const Icon(Icons.mail_outline),
          label: const Text('Sign in with Email'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF5B7FFF),
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
        ),
      ],
    );
  }

  Widget _quickAction(String label, IconData icon, Color color, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 6)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(color: color.withOpacity(0.18), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87)),
            ),
            const Icon(Icons.chevron_right, color: Colors.black45),
          ],
        ),
      ),
    );
  }

  Widget _settingCard({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 6)),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: const Color(0xFF5B7FFF).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: const Color(0xFF5B7FFF)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                  ],
                ],
              ),
            ),
            trailing ?? const Icon(Icons.chevron_right, color: Colors.black45),
          ],
        ),
      ),
    );
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}

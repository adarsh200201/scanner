import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/rate_app.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  String _today() => DateFormat('MMMM d, y').format(DateTime.now());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        title: const Text('Privacy Policy', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _heroHeader(),
              const SizedBox(height: 16),
              _sectionCard(
                title: '1. Information We Collect',
                bullets: const [
                  'Device Information: We may collect basic technical details such as device type, operating system, and app usage statistics for improving performance.',
                  'Scanned Documents: All documents you scan using this app remain on your device by default. We do not automatically upload, share, or store your scanned files on our servers.',
                  'Optional Data: If you choose to use cloud backup, sharing, or third-party integrations, those services may collect and process your data according to their own privacy policies.',
                ],
              ),
              const SizedBox(height: 12),
              _sectionCard(
                title: '2. How We Use Your Information',
                bullets: const [
                  'To provide and improve app functionality.',
                  'To enhance user experience and app performance.',
                  'To fix bugs and troubleshoot issues.',
                  'To enable optional features like sharing or exporting scanned files.',
                ],
              ),
              const SizedBox(height: 12),
              _sectionCard(
                title: '3. Data Security',
                body:
                    'We take reasonable measures to protect your data. Since scanned documents are stored locally on your device (unless you choose to share them), you have full control over your files.',
              ),
              const SizedBox(height: 12),
              _sectionCard(
                title: '4. Sharing of Information',
                body: 'We do not sell, rent, or trade your personal data. Information may only be shared if:',
                bullets: const [
                  'You choose to share/export your documents.',
                  'It is required by law or legal process.',
                  'You opt in to use third-party services (like cloud storage).',
                ],
              ),
              const SizedBox(height: 12),
              _sectionCard(
                title: '5. Third-Party Services',
                body:
                    'Our app may integrate with third-party services (e.g., Google Drive, Dropbox). These services have their own privacy policies, and we recommend reviewing them before use.',
              ),
              const SizedBox(height: 12),
              _sectionCard(
                title: '6. Children’s Privacy',
                body:
                    'Our app is not directed toward children under 13. We do not knowingly collect personal data from children.',
              ),
              const SizedBox(height: 12),
              _sectionCard(
                title: '7. Changes to This Policy',
                body:
                    'We may update this Privacy Policy from time to time. Any changes will be reflected within the app or on our official website.',
              ),
              const SizedBox(height: 12),
              _sectionCard(
                title: '8. Contact Us',
                body:
                    'If you have any questions about this Privacy Policy or our practices, please contact us at: \n\n📧 work.devoff@gmail.com',
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => RateApp.sendGeneralFeedback(context),
                  icon: const Icon(Icons.mail_outline),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('Email Us', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5B7FFF),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _effectiveDate(_today()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _heroHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF5B7FFF), const Color(0xFF8A7DFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
            alignment: Alignment.center,
            child: const Icon(Icons.privacy_tip_outlined, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Privacy Policy', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                SizedBox(height: 4),
                Text(
                  'Scanner ("we", "our", or "us") values your privacy. This Privacy Policy explains how we collect, use, and protect your information when you use our Doc Scanner application.',
                  style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _section({required String title, String? body, List<String>? bullets}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black)),
        if (body != null) ...[
          const SizedBox(height: 8),
          Text(body, style: TextStyle(fontSize: 14, color: Colors.grey[800], height: 1.5)),
        ],
        if (bullets != null && bullets.isNotEmpty) ...[
          const SizedBox(height: 8),
          ...bullets.map((b) => _bullet(b)).toList(),
        ],
      ],
    );
  }

  Widget _sectionCard({required String title, String? body, List<String>? bullets}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: _section(title: title, body: body, bullets: bullets),
    );
  }

  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('•  ', style: TextStyle(fontSize: 16, height: 1.4)),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14, height: 1.5))),
        ],
      ),
    );
  }

  Widget _effectiveDate(String date) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF5B7FFF).withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text('Effective Date: $date', style: const TextStyle(color: Color(0xFF5B7FFF), fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/app_info.dart';
import '../data/faqs.dart';
import 'help_center_screen.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        title: const Text('About', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeaderCard(),
            const SizedBox(height: 16),
            _SectionTitle('About'),
            const SizedBox(height: 8),
            _SectionContainer(children: [
              _kvTile(context, Icons.apps_outlined, 'App name', AppInfo.appName),
              const Divider(height: 1),
              _kvTile(context, Icons.tag_outlined, 'Version', AppInfo.appVersion),
              const Divider(height: 1),
              _descriptionTile(AppInfo.description),
            ]),
            const SizedBox(height: 16),
            _SectionTitle('Support'),
            const SizedBox(height: 8),
            _SectionContainer(children: [
              _linkTile(context, Icons.email_outlined, 'Email', 'mailto:${AppInfo.supportEmail}'),
              const Divider(height: 1),
              _linkTile(context, Icons.public_outlined, 'Website', AppInfo.websiteUrl),
            ]),
            const SizedBox(height: 16),
            _SectionTitle('Help Center'),
            const SizedBox(height: 8),
            _SectionContainer(children: [
              ..._faqPreview(context),
              const Divider(height: 1),
              ListTile(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpCenterScreen())),
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                leading: const Icon(Icons.open_in_new, color: Color(0xFF5B7FFF)),
                title: const Text('Open Help Center', style: TextStyle(fontSize: 14, color: Colors.black87)),
                trailing: const Icon(Icons.chevron_right, color: Colors.black45),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(width: 110, child: Text(k, style: const TextStyle(fontSize: 14, color: Colors.black54))),
          Expanded(child: Text(v, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  Widget _linkRow(String label, String url) {
    return InkWell(
      onTap: () => _openUrl(url),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            SizedBox(width: 110, child: Text(label, style: const TextStyle(fontSize: 14, color: Colors.black54))),
            Expanded(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.open_in_new, size: 16, color: Color(0xFF5B7FFF)),
                  SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Open',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 14, color: Color(0xFF5B7FFF), fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Future<void> _openUrl(String raw) async {
    final uri = Uri.parse(raw);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  List<Widget> _faqPreview(BuildContext context) {
    final preview = faqs.take(3).toList();
    return [
      for (final f in preview) _faqTile(f),
    ];
  }

  Widget _faqTile(FaqItem f) {
    return Theme(
      data: ThemeData().copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
        title: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(color: const Color(0xFF5B7FFF).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.help_outline, color: Color(0xFF5B7FFF), size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(f.question, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black))),
          ],
        ),
        iconColor: const Color(0xFF5B7FFF),
        collapsedIconColor: const Color(0xFF5B7FFF),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(f.answer, style: TextStyle(fontSize: 13, color: Colors.grey[700], height: 1.4)),
            ),
          )
        ],
      ),
    );
  }

  Widget _SectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.black));
  }

  Widget _SectionContainer({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _kvTile(BuildContext context, IconData icon, String label, String value) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      leading: Icon(icon, color: const Color(0xFF5B7FFF)),
      title: Text(label, style: const TextStyle(fontSize: 14, color: Colors.black87)),
      trailing: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black)),
    );
  }

  Widget _descriptionTile(String text) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      leading: const Icon(Icons.info_outline, color: Color(0xFF5B7FFF)),
      title: const Text('Description', style: TextStyle(fontSize: 14, color: Colors.black87)),
      subtitle: Text(text, style: TextStyle(fontSize: 13, color: Colors.grey[800], height: 1.4)),
    );
  }

  Widget _linkTile(BuildContext context, IconData icon, String label, String url) {
    return ListTile(
      onTap: () => _openUrl(url),
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      leading: Icon(icon, color: const Color(0xFF5B7FFF)),
      title: Text(label, style: const TextStyle(fontSize: 14, color: Colors.black87)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.open_in_new, size: 16, color: Color(0xFF5B7FFF)),
          SizedBox(width: 6),
          Text('Open', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF5B7FFF))),
        ],
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF5B7FFF), const Color(0xFF5B7FFF).withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: const Color(0xFF5B7FFF).withOpacity(0.25), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.document_scanner_outlined, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(AppInfo.appName, style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('Version ${AppInfo.appVersion}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;

  const _InfoSection({required this.icon, required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: const Color(0xFF5B7FFF).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: const Color(0xFF5B7FFF)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _ChipBadge extends StatelessWidget {
  final String label;
  final String? tooltip;

  const _ChipBadge({required this.label, this.tooltip});

  @override
  Widget build(BuildContext context) {
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF5B7FFF).withOpacity(0.06),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF5B7FFF).withOpacity(0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_outline, size: 16, color: Color(0xFF5B7FFF)),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF5B7FFF))),
        ],
      ),
    );

    if (tooltip == null || tooltip!.isEmpty) return chip;
    return Tooltip(message: tooltip!, child: chip);
  }
}

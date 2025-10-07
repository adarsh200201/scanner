import 'package:flutter/material.dart';
import '../data/faqs.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({Key? key}) : super(key: key);

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchCtrl = TextEditingController();
  String _category = 'General';

  final List<String> _categories = const ['General', 'Account', 'Service', 'Scan'];

  final List<FaqItem> _allFaqs = faqs;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  List<FaqItem> get _filteredFaqs {
    final q = _searchCtrl.text.trim().toLowerCase();
    return _allFaqs.where((f) {
      final cat = _category == 'All' ? true : f.category == _category;
      final matches = q.isEmpty || f.question.toLowerCase().contains(q) || f.answer.toLowerCase().contains(q);
      return cat && matches;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Help Center', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF5B7FFF),
          unselectedLabelColor: Colors.black45,
          indicatorColor: const Color(0xFF5B7FFF),
          tabs: const [
            Tab(text: 'FAQ'),
            Tab(text: 'Contact us'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFaqTab(),
          _buildContactTab(),
        ],
      ),
    );
  }

  Widget _buildFaqTab() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _categories.map((c) {
                final selected = _category == c;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(c),
                    selected: selected,
                    onSelected: (_) => setState(() => _category = c),
                    selectedColor: const Color(0xFF5B7FFF).withOpacity(0.12),
                    labelStyle: TextStyle(
                      color: selected ? const Color(0xFF5B7FFF) : Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                    side: BorderSide(color: selected ? const Color(0xFF5B7FFF) : Colors.grey[300]!),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'Search',
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFF5B7FFF)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredFaqs.length,
              itemBuilder: (context, i) {
                final f = _filteredFaqs[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))],
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      title: Text(f.question, style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.black)),
                      iconColor: const Color(0xFF5B7FFF),
                      collapsedIconColor: const Color(0xFF5B7FFF),
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Text(
                            f.answer,
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactTab() {
    Widget item(IconData icon, String title, VoidCallback onTap) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: ListTile(
          leading: Icon(icon, color: const Color(0xFF5B7FFF)),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.black)),
          trailing: const Icon(Icons.chevron_right, color: Colors.black45),
          onTap: onTap,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: ListView(
        children: [
          item(Icons.headset_mic_outlined, 'Contact us', () => _toast('Contact us')),
          item(Icons.chat_bubble_outline, 'WhatsApp', () => _toast('WhatsApp')),
          item(Icons.camera_alt_outlined, 'Instagram', () => _toast('Instagram')),
          item(Icons.facebook, 'Facebook', () => _toast('Facebook')),
          item(Icons.alternate_email, 'Twitter', () => _toast('Twitter')),
          item(Icons.public, 'Website', () => _toast('Website')),
        ],
      ),
    );
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}

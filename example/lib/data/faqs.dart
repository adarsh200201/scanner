class FaqItem {
  final String category;
  final String question;
  final String answer;
  const FaqItem({required this.category, required this.question, required this.answer});
}

const List<FaqItem> faqs = [
  FaqItem(category: 'General', question: 'What is ProScan?', answer: 'ProScan is a document scanning app that helps you scan, organize and share files quickly.'),
  FaqItem(category: 'General', question: 'Is the ProScan App free?', answer: 'Yes, ProScan offers core features for free. Some advanced features may be premium.'),
  FaqItem(category: 'Account', question: 'How can I log out from ProScan?', answer: 'Open Profile and tap Logout. Your local files remain on device.'),
  FaqItem(category: 'Scan', question: 'How do I export to PDF?', answer: 'After scanning, choose Save As > PDF to export a single PDF.'),
  FaqItem(category: 'Service', question: 'Why can\'t I scan documents?', answer: 'Ensure camera permission is granted and try again in a well‑lit area.'),
];

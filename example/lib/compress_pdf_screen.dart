import 'package:flutter/material.dart';

class CompressPdfScreen extends StatefulWidget {
  final String documentTitle;
  final String documentContent;

  const CompressPdfScreen({
    Key? key,
    required this.documentTitle,
    required this.documentContent,
  }) : super(key: key);

  @override
  State<CompressPdfScreen> createState() => _CompressPdfScreenState();
}

class _CompressPdfScreenState extends State<CompressPdfScreen> {
  String _selectedCompression = 'Medium Compression';

  final List<CompressionOption> _compressionOptions = [
    CompressionOption(
      title: 'High Compression',
      subtitle: 'Smallest size, lower quality',
      isSelected: false,
    ),
    CompressionOption(
      title: 'Medium Compression',
      subtitle: 'Medium size, medium quality',
      isSelected: true,
    ),
    CompressionOption(
      title: 'Low Compression',
      subtitle: 'Largest size, better quality',
      isSelected: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _buildContent(),
            ),
            _buildCompressButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.black),
          ),
          const Expanded(
            child: Text(
              'Compress PDF',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Reduce the size of your PDF file.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          _buildDocumentPreview(),
          const SizedBox(height: 24),
          _buildCompressionOptions(),
        ],
      ),
    );
  }

  Widget _buildDocumentPreview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Icon(Icons.description, color: Colors.grey, size: 24),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.documentTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '12/30/2023 09:41',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompressionOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select compression level:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        ..._compressionOptions.map((option) => _buildCompressionOption(option)),
      ],
    );
  }

  Widget _buildCompressionOption(CompressionOption option) {
    final isSelected = _selectedCompression == option.title;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Radio<String>(
            value: option.title,
            groupValue: _selectedCompression,
            onChanged: (value) {
              setState(() {
                _selectedCompression = value!;
              });
            },
            activeColor: Colors.blue,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  option.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.blue : Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  option.subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompressButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: _compressPdf,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            'Compress',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  void _compressPdf() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('PDF compressed successfully using $_selectedCompression!'),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.pop(context);
  }
}

class CompressionOption {
  final String title;
  final String subtitle;
  final bool isSelected;

  CompressionOption({
    required this.title,
    required this.subtitle,
    required this.isSelected,
  });
}

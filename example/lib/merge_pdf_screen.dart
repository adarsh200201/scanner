import 'package:flutter/material.dart';

class MergePdfScreen extends StatefulWidget {
  const MergePdfScreen({Key? key}) : super(key: key);

  @override
  State<MergePdfScreen> createState() => _MergePdfScreenState();
}

class _MergePdfScreenState extends State<MergePdfScreen> {
  final TextEditingController _fileNameController = TextEditingController(text: 'Andrew Ainsley - Merged');
  final List<SelectedFile> _selectedFiles = [
    SelectedFile(
      title: 'Job Application Letter',
      date: '12/30/2023 09:41',
      thumbnail: '📄',
    ),
    SelectedFile(
      title: 'Recommendation Letter',
      date: '12/28/2023 09:37',
      thumbnail: '📝',
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
            _buildMergeButton(),
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
              'Merge PDF',
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
          Text(
            '${_selectedFiles.length} selected files to be merged',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          _buildFileNameSection(),
          const SizedBox(height: 24),
          _buildSelectedFilesSection(),
          const SizedBox(height: 24),
          _buildAddMoreButton(),
        ],
      ),
    );
  }

  Widget _buildFileNameSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'File Name',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _fileNameController,
          decoration: const InputDecoration(
            border: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.blue),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.blue, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedFilesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Selected Files',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        ..._selectedFiles.map((file) => _buildSelectedFileCard(file)),
      ],
    );
  }

  Widget _buildSelectedFileCard(SelectedFile file) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                file.thumbnail,
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  file.date,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _removeFile(file),
            icon: const Icon(Icons.close, color: Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildAddMoreButton() {
    return Container(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: _addMoreFiles,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.withOpacity(0.1),
          foregroundColor: Colors.blue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        icon: const Icon(Icons.add),
        label: const Text(
          'Add More Files',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildMergeButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: _selectedFiles.isNotEmpty ? _mergeFiles : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: _selectedFiles.isNotEmpty ? Colors.blue : Colors.grey,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            'Merge',
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

  void _removeFile(SelectedFile file) {
    setState(() {
      _selectedFiles.remove(file);
    });
  }

  void _addMoreFiles() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add More Files'),
        content: const Text('Select additional files to merge:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _selectedFiles.add(SelectedFile(
                  title: 'Requirements Document',
                  date: '12/29/2023 10:20',
                  thumbnail: '📋',
                ));
              });
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _mergeFiles() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_selectedFiles.length} files merged successfully as "${_fileNameController.text}"!'),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.pop(context);
  }
}

class SelectedFile {
  final String title;
  final String date;
  final String thumbnail;

  SelectedFile({
    required this.title,
    required this.date,
    required this.thumbnail,
  });
}

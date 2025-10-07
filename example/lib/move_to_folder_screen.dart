import 'package:flutter/material.dart';

class MoveToFolderScreen extends StatefulWidget {
  final String documentTitle;
  final String documentContent;

  const MoveToFolderScreen({
    Key? key,
    required this.documentTitle,
    required this.documentContent,
  }) : super(key: key);

  @override
  State<MoveToFolderScreen> createState() => _MoveToFolderScreenState();
}

class _MoveToFolderScreenState extends State<MoveToFolderScreen> {
  final List<FolderItem> _folders = [
    FolderItem(
      name: 'My Certificate Files',
      fileCount: 12,
      date: '12/26/2023 17:29',
      isFolder: true,
    ),
    FolderItem(
      name: 'My Home Files',
      fileCount: 8,
      date: '12/24/2023 20:08',
      isFolder: true,
    ),
  ];

  final List<FolderItem> _files = [
    FolderItem(
      name: 'Job Application Letter',
      date: '12/30/2023 09:41',
      isFolder: false,
    ),
    FolderItem(
      name: 'Requirements Document',
      date: '12/29/2023 10:20',
      isFolder: false,
    ),
    FolderItem(
      name: 'Recommendation Letter',
      date: '12/28/2023 09:37',
      isFolder: false,
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
            _buildActionButtons(),
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
              'Move to Folder',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Row(
            children: [
              const Text(
                'Total: 125 files',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.sort, color: Colors.grey),
              ),
              IconButton(
                onPressed: _createNewFolder,
                icon: const Icon(Icons.create_new_folder, color: Colors.blue),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ..._folders.map((folder) => _buildFolderItem(folder)),
        const SizedBox(height: 16),
        ..._files.map((file) => _buildFileItem(file)),
      ],
    );
  }

  Widget _buildFolderItem(FolderItem folder) {
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
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Icon(Icons.folder, color: Colors.white, size: 24),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  folder.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${folder.fileCount} files',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  folder.date,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_vert, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildFileItem(FolderItem file) {
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
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey[100],
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
                  file.name,
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
          Row(
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.share, color: Colors.grey),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.more_vert, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[200],
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _moveToFolder,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Move Here',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _createNewFolder() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Folder'),
        content: const TextField(
          decoration: InputDecoration(
            hintText: 'Enter folder name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('New folder created!')),
              );
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _moveToFolder() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Document moved to folder successfully!'),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.pop(context);
  }
}

class FolderItem {
  final String name;
  final String date;
  final int? fileCount;
  final bool isFolder;

  FolderItem({
    required this.name,
    required this.date,
    this.fileCount,
    required this.isFolder,
  });
}

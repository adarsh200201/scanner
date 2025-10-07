import 'package:flutter/material.dart';
import '../models/file_item.dart';

class SearchScreen extends StatefulWidget {
  final List<FileItem> allFiles;

  const SearchScreen({Key? key, required this.allFiles}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<FileItem> _searchResults = [];
  bool _isSearching = false;
  bool _hasSearched = false;

  final List<String> _searchHistory = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _hasSearched = false;
        _searchResults.clear();
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _hasSearched = true;
      _searchResults = widget.allFiles
          .where((file) => file.name.toLowerCase().contains(query))
          .toList();
    });
  }

  void _removeSearchHistoryItem(String item) {
    setState(() {
      _searchHistory.remove(item);
    });
  }

  void _selectSearchHistory(String query) {
    _searchController.text = query;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Container(
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F6FA),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _searchController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Search',
              hintStyle: TextStyle(color: Colors.grey[400]),
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: () {
                        _searchController.clear();
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (!_hasSearched || _searchController.text.isEmpty) {
      return _buildSearchHistory();
    } else if (_searchResults.isEmpty) {
      return _buildEmptyState();
    } else {
      return _buildSearchResults();
    }
  }

  Widget _buildSearchHistory() {
    if (_searchHistory.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Previous Search',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.clear, color: Colors.grey),
                onPressed: () {
                  setState(() {
                    _searchHistory.clear();
                  });
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _searchHistory.length,
            itemBuilder: (context, index) {
              final historyItem = _searchHistory[index];
              return ListTile(
                title: Text(
                  historyItem,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey, size: 20),
                  onPressed: () => _removeSearchHistoryItem(historyItem),
                ),
                onTap: () => _selectSearchHistory(historyItem),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Empty state illustration
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: const Color(0xFFE8ECFF),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Sad face
                Container(
                  width: 140,
                  height: 140,
                  decoration: const BoxDecoration(
                    color: Color(0xFF5B7FFF),
                    shape: BoxShape.circle,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Eyes
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 30,
                            height: 8,
                            decoration: BoxDecoration(
                              color: const Color(0xFF2D3748),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: 24),
                          Container(
                            width: 30,
                            height: 8,
                            decoration: BoxDecoration(
                              color: const Color(0xFF2D3748),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Sad mouth
                      Container(
                        width: 60,
                        height: 30,
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: const Color(0xFF2D3748),
                              width: 8,
                            ),
                          ),
                          borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(30),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Person illustration
                Positioned(
                  right: 20,
                  bottom: 40,
                  child: Container(
                    width: 40,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2D3748),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Not Found',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'We\'re sorry, the keyword you were looking for could not be found. Please search with another keywords.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final file = _searchResults[index];
        return _buildFileItem(file);
      },
    );
  }

  Widget _buildFileItem(FileItem file) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // Icon/Thumbnail
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: file.type == 'folder' 
                  ? const Color(0xFF5B7FFF) 
                  : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: file.type == 'folder'
                ? const Icon(Icons.folder, color: Colors.white, size: 28)
                : const Icon(Icons.description, color: Colors.grey, size: 28),
          ),
          const SizedBox(width: 16),
          // File Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  file.date,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          // Share & More buttons
          if (file.type == 'file') ...[
            IconButton(
              icon: const Icon(Icons.share_outlined, color: Colors.black87),
              onPressed: () {},
            ),
          ],
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black87),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

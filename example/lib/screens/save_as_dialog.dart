import 'package:flutter/material.dart';

import 'package:flutter/material.dart';

class SaveAsDialog extends StatefulWidget {
  final String defaultFileName;
  final List<String> imagePaths;
  final Future<void> Function(String fileName, String format, String quality) onSave;

  const SaveAsDialog({
    Key? key,
    required this.defaultFileName,
    required this.imagePaths,
    required this.onSave,
  }) : super(key: key);

  @override
  State<SaveAsDialog> createState() => _SaveAsDialogState();
}

class _SaveAsDialogState extends State<SaveAsDialog> {
  late TextEditingController _fileNameController;
  String _selectedFormat = 'JPEG';
  String _selectedQuality = 'Regular';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _fileNameController = TextEditingController(text: widget.defaultFileName);
  }

  @override
  void dispose() {
    _fileNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;
    final maxHeight = MediaQuery.of(context).size.height * 0.9;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Save As',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 24),

              // File name input
              TextField(
                controller: _fileNameController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => _fileNameController.clear(),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Format selection
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Select format:',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildCircularFormatButton('PDF', Icons.picture_as_pdf),
                  const SizedBox(width: 40),
                  _buildCircularFormatButton('JPEG', Icons.image),
                ],
              ),
              const SizedBox(height: 24),

              const SizedBox(height: 8),

              // Quality selection
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Quality:',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildQualityChip('Low'),
                  const SizedBox(width: 8),
                  _buildQualityChip('Regular'),
                  const SizedBox(width: 8),
                  _buildQualityChip('High'),
                ],
              ),
              const SizedBox(height: 24),

              // Action buttons
              if (_saving)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: CircularProgressIndicator(),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    width: 56,
                    height: 56,
                    child: OutlinedButton(
                      onPressed: _saving ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        shape: const CircleBorder(),
                        side: BorderSide(color: Colors.grey[300] ?? Colors.grey),
                        padding: EdgeInsets.zero,
                        backgroundColor: Colors.grey[100],
                      ),
                      child: const Icon(Icons.close, color: Colors.grey),
                    ),
                  ),
                  SizedBox(
                    width: 56,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _saving
                          ? null
                          : () {
                              final fileName = _fileNameController.text.trim();
                              if (fileName.isEmpty) return;
                              Navigator.of(context).pop();
                              Future.microtask(() => widget.onSave(fileName, _selectedFormat, _selectedQuality));
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5B7FFF),
                        shape: const CircleBorder(),
                        padding: EdgeInsets.zero,
                        elevation: 0,
                      ),
                      child: const Icon(Icons.check, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCircularFormatButton(String format, IconData icon) {
    final isSelected = _selectedFormat == format;
    return Column(
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _selectedFormat = format;
            });
          },
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? const Color(0xFF5B7FFF) : Colors.grey[100],
              border: Border.all(
                color: isSelected ? const Color(0xFF5B7FFF) : Colors.grey[300]!,
                width: 3,
              ),
            ),
            child: Icon(
              icon,
              size: 36,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          format,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? const Color(0xFF5B7FFF) : Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildQualityChip(String value) {
    final selected = _selectedQuality == value;
    return ChoiceChip(
      label: Text(value),
      selected: selected,
      onSelected: (v) {
        if (v) setState(() => _selectedQuality = value);
      },
      selectedColor: const Color(0xFF5B7FFF).withOpacity(0.15),
      labelStyle: TextStyle(
        color: selected ? const Color(0xFF5B7FFF) : Colors.black87,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: selected ? const Color(0xFF5B7FFF) : Colors.grey[300]!)),
      backgroundColor: Colors.grey[100],
    );
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import '../models/document_models.dart';

class DocumentSetupPage extends StatefulWidget {
  final String initialFileName;
  final List<ScannedPage> pages;
  final DocumentFormat defaultFormat;
  final bool allowMultiPageMerge;
  final Future<SaveSuccessData> Function(DocumentSetupResult result) onConfirm;

  const DocumentSetupPage({
    super.key,
    required this.initialFileName,
    required this.pages,
    required this.onConfirm,
    this.defaultFormat = DocumentFormat.pdf,
    this.allowMultiPageMerge = true,
  });

  @override
  State<DocumentSetupPage> createState() => _DocumentSetupPageState();
}

class _DocumentSetupPageState extends State<DocumentSetupPage> {
  late TextEditingController _nameCtrl;
  late DocumentFormat _format;
  late Set<String> _selectedIds;
  bool _mergePdf = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialFileName);
    _format = widget.defaultFormat;
    _selectedIds = widget.pages.map((e) => e.id).toSet();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final result = DocumentSetupResult(
        fileName: _nameCtrl.text.trim().isEmpty ? widget.initialFileName : _nameCtrl.text.trim(),
        format: _format,
        selectedPageIds: _selectedIds.toList(growable: false),
        mergeIntoSinglePdf: _format == DocumentFormat.pdf && widget.allowMultiPageMerge && _mergePdf,
      );
      await widget.onConfirm(result);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSelectMany = _format == DocumentFormat.pdf && widget.allowMultiPageMerge;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Document Setup'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Rename document'),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameCtrl,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'e.g. Invoice_01',
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Select format'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _FormatChip(
                      label: 'PDF',
                      selected: _format == DocumentFormat.pdf,
                      onTap: () => setState(() => _format = DocumentFormat.pdf),
                    ),
                    const SizedBox(width: 8),
                    _FormatChip(
                      label: 'JPEG',
                      selected: _format == DocumentFormat.jpeg,
                      onTap: () => setState(() => _format = DocumentFormat.jpeg),
                    ),
                  ],
                ),
                if (canSelectMany) ...[
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Merge selected pages into a single PDF'),
                      Switch(
                        value: _mergePdf,
                        onChanged: (v) => setState(() => _mergePdf = v),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                const Text('Pages'),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: widget.pages.length,
              itemBuilder: (_, i) {
                final page = widget.pages[i];
                final selected = _selectedIds.contains(page.id);
                return _PageThumb(
                  page: page,
                  selected: selected,
                  onTap: () {
                    if (!canSelectMany) {
                      setState(() {
                        _selectedIds = {page.id};
                      });
                      return;
                    }
                    setState(() {
                      if (selected) {
                        _selectedIds.remove(page.id);
                      } else {
                        _selectedIds.add(page.id);
                      }
                    });
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedIds.isEmpty || _saving ? null : _handleSave,
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Confirm and Save'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FormatChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FormatChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      shape: const StadiumBorder(),
    );
  }
}

class _PageThumb extends StatelessWidget {
  final ScannedPage page;
  final bool selected;
  final VoidCallback onTap;
  const _PageThumb({required this.page, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    Widget image;
    if (page.imageBytes != null) {
      image = Image.memory(page.imageBytes!, fit: BoxFit.cover);
    } else if (page.imagePath != null && File(page.imagePath!).existsSync()) {
      image = Image.file(File(page.imagePath!), fit: BoxFit.cover);
    } else {
      image = const ColoredBox(color: Colors.black12);
    }

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Positioned.fill(child: ClipRRect(borderRadius: BorderRadius.circular(8), child: image)),
          Positioned(
            top: 6,
            right: 6,
            child: AnimatedScale(
              scale: selected ? 1 : 0,
              duration: const Duration(milliseconds: 150),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.check, size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

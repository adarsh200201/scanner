import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import '../models/document_models.dart';

class SaveSuccessPage extends StatelessWidget {
  final SaveSuccessData data;
  final Future<void> Function() onShare;
  final Future<void> Function() onOpen;
  final Future<void> Function() onSaveToGallery;
  final VoidCallback onBackToHome;

  const SaveSuccessPage({
    super.key,
    required this.data,
    required this.onShare,
    required this.onOpen,
    required this.onSaveToGallery,
    required this.onBackToHome,
  });

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        onBackToHome();
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: onBackToHome,
          ),
          title: const Text('Saved'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 24),
              const CircleAvatar(
                radius: 32,
                backgroundColor: Colors.blue,
                child: Icon(Icons.check, color: Colors.white, size: 32),
              ),
              const SizedBox(height: 16),
              Text(
                data.format == DocumentFormat.pdf ? 'PDF Saved' : 'Image Saved',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                data.primaryPath,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const Spacer(),
              _ActionButton(
                icon: Icons.share,
                label: 'Share',
                onPressed: onShare,
              ),
              const SizedBox(height: 12),
              _ActionButton(
                icon: Icons.open_in_new,
                label: 'Open',
                onPressed: onOpen,
              ),
              const SizedBox(height: 12),
              if (data.format == DocumentFormat.jpeg)
                _ActionButton(
                  icon: Icons.photo_library,
                  label: 'Save to Gallery',
                  onPressed: onSaveToGallery,
                )
              else
                _ActionButton(
                  icon: Icons.download,
                  label: 'Download PDF',
                  onPressed: onOpen,
                ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Future<void> Function() onPressed;
  const _ActionButton({required this.icon, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(icon),
        label: Text(label),
        onPressed: () => onPressed(),
        style: ElevatedButton.styleFrom(
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}

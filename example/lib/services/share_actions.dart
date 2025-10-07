import 'dart:io';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../screens/document_viewer.dart';

class ShareActions {
  static const MethodChannel _gallery = MethodChannel('proscan.gallery');

  static String normalizePath(String path) => path.startsWith('file://')
      ? File.fromUri(Uri.parse(path)).path
      : path;

  static Future<void> sharePaths(BuildContext context, String title, List<String> paths) async {
    try {
      if (paths.isEmpty) return;
      final xfiles = paths.map((p) => XFile(normalizePath(p))).toList();
      await Share.shareXFiles(xfiles, text: title);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to share: $e')),
      );
    }
  }

  static Future<void> saveImagesToGallery(BuildContext context, String title, List<String> paths) async {
    try {
      if (paths.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nothing to save to gallery')),
        );
        return;
      }
      bool anySaved = false;
      for (final p in paths) {
        final lower = p.toLowerCase();
        if (lower.endsWith('.jpg') || lower.endsWith('.jpeg') || lower.endsWith('.png')) {
          final ok = await _gallery.invokeMethod<bool>('saveImage', {
            'path': normalizePath(p),
            'title': title,
          });
          anySaved = anySaved || (ok ?? false);
        }
      }
      if (anySaved) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved to gallery')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nothing to save to gallery')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    }
  }

  static void openViewer(BuildContext context, String title, {String? filePath, List<String>? imagePaths}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DocumentViewer(
          documentTitle: title,
          filePath: filePath,
          imagePaths: imagePaths,
        ),
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';

class RateApp {
  static Future<void> promptAndRequest(BuildContext context) async {
    final themeColor = const Color(0xFF5B7FFF);

    // Stable root contexts for navigator and scaffold
    BuildContext rootContext;
    try {
      rootContext = Navigator.of(context, rootNavigator: true).context;
    } catch (_) {
      rootContext = context;
    }

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (ctx) {
        int selected = 0;
        const labels = <int, String>{
          1: 'Not great',
          2: 'Could be better',
          3: 'It’s okay',
          4: 'I like it',
          5: 'Simply the best for us',
        };
        return StatefulBuilder(
          builder: (ctx, setState) => SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text('😍', style: TextStyle(fontSize: 48)),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Are you happy with this app?',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'How would you love this app?',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: List.generate(5, (i) {
                      final idx = i + 1;
                      final filled = idx <= selected;
                      return AnimatedScale(
                        scale: filled ? 1.08 : 1.0,
                        duration: const Duration(milliseconds: 120),
                        child: IconButton(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          constraints: const BoxConstraints(),
                          icon: Icon(
                            filled ? Icons.star_rounded : Icons.star_border_rounded,
                            color: filled ? themeColor : Colors.grey[400],
                            size: 40,
                          ),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            setState(() => selected = idx);
                          },
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: selected == 0
                        ? const SizedBox.shrink()
                        : Container(
                            key: ValueKey(selected),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: themeColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
                              ],
                            ),
                            child: Text(
                              labels[selected] ?? '',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
                            ),
                          ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: selected == 0
                          ? null
                          : () async {
                              Navigator.of(ctx).pop();
                              debugPrint('Rating dialog closed, selected: $selected');
                              
                              // Show quick toast-like thanks using root ScaffoldMessenger
                              final messenger = ScaffoldMessenger.maybeOf(rootContext) ?? ScaffoldMessenger.maybeOf(context);
                              messenger?.showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(Icons.favorite, color: Colors.white),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          selected >= 4
                                              ? 'Thank you for your ${selected}-star rating! 💖'
                                              : 'Thank you for your feedback!',
                                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                    ],
                                  ),
                                  backgroundColor: const Color(0xFF5B7FFF),
                                  duration: const Duration(seconds: 4),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  margin: const EdgeInsets.all(16),
                                ),
                              );
                              debugPrint('Thanks message shown via SnackBar');
                              
                              // Then request review or send feedback
                              await Future.delayed(const Duration(milliseconds: 300));
                              if (selected >= 4) {
                                debugPrint('Requesting in-app review...');
                                await _requestReview(rootContext);
                                debugPrint('Review request completed');
                                await _waitUntilResumed();
                              } else {
                                await _sendFeedbackEmail(rootContext, selected);
                              }

                              // Show modern thanks sheet after action
                              if (rootContext.mounted) {
                                await _showThanksSheet(rootContext, rating: selected);
                              }
                            },
                      child: const Text('RATE APP', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.6)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static Future<void> _requestReview(BuildContext context) async {
    final inAppReview = InAppReview.instance;
    try {
      final available = await inAppReview.isAvailable();
      if (available) {
        await inAppReview.requestReview();
      } else {
        await _openStoreListing();
      }
    } catch (_) {
      await _openStoreListing();
    }
  }

  static Future<void> _openStoreListing() async {
    try {
      await InAppReview.instance.openStoreListing();
    } catch (_) {}
  }

  static Future<void> _sendFeedbackEmail(BuildContext context, int rating) async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'work.devoff@gmail.com',
      queryParameters: {
        'subject': 'Scanner feedback - $rating star(s)',
        'body': 'Please share your feedback here. Rating: $rating star(s)\n\n',
      },
    );

    await _openEmailFlow(context, uri, fallbackBody:
        'Please email us at work.devoff@gmail.com\n\nSubject: ${Uri.decodeComponent(uri.queryParameters['subject'] ?? 'Scanner feedback')}\n\n${Uri.decodeComponent(uri.queryParameters['body'] ?? '')}');
  }

  static Future<void> sendGeneralFeedback(BuildContext context) async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'work.devoff@gmail.com',
      queryParameters: {
        'subject': 'Scanner feedback',
        'body': 'Please share your feedback here.\n\n',
      },
    );

    await _openEmailFlow(context, uri, fallbackBody:
        'Please email us at work.devoff@gmail.com\n\nSubject: Scanner feedback\n\nPlease share your feedback here.\n\n');
  }

  static Future<void> _openEmailFlow(BuildContext context, Uri mailto, {required String fallbackBody}) async {
    try {
      if (await canLaunchUrl(mailto)) {
        final launched = await launchUrl(mailto, mode: LaunchMode.externalApplication);
        if (launched) return;
      }

      // Try opening Gmail web compose as a fallback
      final webmail = Uri.parse(
          'https://mail.google.com/mail/?view=cm&fs=1&to=${Uri.encodeComponent(mailto.path)}&su=${Uri.encodeComponent(mailto.queryParameters['subject'] ?? '')}&body=${Uri.encodeComponent(mailto.queryParameters['body'] ?? '')}');
      if (await canLaunchUrl(webmail)) {
        final launched = await launchUrl(webmail, mode: LaunchMode.externalApplication);
        if (launched) return;
      }

      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('No email app found'),
          content: const Text('Please install an email app or copy our address to contact us.'),
          actions: [
            TextButton(
              onPressed: () async {
                await Clipboard.setData(const ClipboardData(text: 'work.devoff@gmail.com'));
                if (context.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email copied')));
                }
              },
              child: const Text('Copy Email'),
            ),
            TextButton(
              onPressed: () async {
                final market = Uri.parse('market://search?q=email app');
                final web = Uri.parse('https://play.google.com/store/search?q=email%20app');
                if (await canLaunchUrl(market)) {
                  await launchUrl(market);
                } else {
                  await launchUrl(web, mode: LaunchMode.externalApplication);
                }
                if (context.mounted) Navigator.pop(ctx);
              },
              child: const Text('Install App'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Share.share(fallbackBody, subject: 'Scanner feedback');
              },
              child: const Text('Share Instead'),
            ),
          ],
        ),
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open email app')));
    }
  }

  static Future<void> _waitUntilResumed({Duration timeout = const Duration(seconds: 8)}) async {
    final binding = WidgetsBinding.instance;
    final end = DateTime.now().add(timeout);
    while (binding.lifecycleState != AppLifecycleState.resumed && DateTime.now().isBefore(end)) {
      await Future.delayed(const Duration(milliseconds: 150));
    }
    await Future.delayed(const Duration(milliseconds: 120));
  }

  static Future<void> _showThanksSheet(BuildContext context, {int? rating}) async {
    debugPrint('=== _showThanksSheet called with rating: $rating ===');
    
    // Validate context before showing sheet
    if (!context.mounted) {
      debugPrint('❌ Context not mounted, skipping thanks sheet');
      return;
    }
    debugPrint('✓ Context is mounted');
    
    try {
      final themeColor = const Color(0xFF5B7FFF);
      HapticFeedback.lightImpact();
      debugPrint('Waiting 300ms before showing sheet...');
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Double-check context is still valid
      if (!context.mounted) {
        debugPrint('❌ Context became unmounted after delay, skipping thanks sheet');
        return;
      }
      debugPrint('✓ Context still mounted after delay');
      
      debugPrint('Calling showModalBottomSheet...');
      await showModalBottomSheet<void>(
        context: context,
        useRootNavigator: true,
        backgroundColor: Colors.white,
        isScrollControlled: false,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        builder: (ctx) {
          debugPrint('✓ Thanks sheet builder called - sheet is displaying');
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: themeColor.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Text('🎉', style: TextStyle(fontSize: 32)),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Thanks for rating!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.black87),
                ),
                const SizedBox(height: 6),
                Text(
                  'Your support helps us keep improving.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
                if (rating != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      final idx = i + 1;
                      final filled = rating >= idx;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Icon(
                          filled ? Icons.star_rounded : Icons.star_border_rounded,
                          color: filled ? themeColor : Colors.grey[300],
                          size: 22,
                        ),
                      );
                    }),
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('CLOSE', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.6)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
      debugPrint('✓ Thanks sheet displayed successfully');
    } catch (e, stackTrace) {
      debugPrint('❌ Error showing thanks sheet: $e');
      debugPrint('Stack trace: $stackTrace');
      // Silently fail - user already completed the rating action
    }
    debugPrint('=== _showThanksSheet completed ===');
  }
}

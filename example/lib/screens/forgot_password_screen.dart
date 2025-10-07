import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendReset() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSending = true);
    try {
      await AppFirebase.init();
      await FirebaseAuth.instance
          .sendPasswordResetEmail(email: _emailController.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset link sent to your email')),
      );
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message ?? 'Failed to send reset email')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to send reset email: $e')));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: const Color(0xFF5B7FFF).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.lock_reset,
                        size: 44, color: Color(0xFF5B7FFF)),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Forgot password',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter your account email to receive a reset link',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 28),

                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Enter email';
                      if (!v.contains('@')) return 'Enter a valid email';
                      return null;
                    },
                  ),
                  const SizedBox(height: 22),

                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSending ? null : _sendReset,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5B7FFF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSending
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Send reset link',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

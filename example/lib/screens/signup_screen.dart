import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../main.dart';
import '../services/firebase.dart';
import '../services/storage_service.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await AppFirebase.init();
      final auth = FirebaseAuth.instance;
      final email = _emailController.text.trim();
      final pass = _passwordController.text.trim();
      final name = _nameController.text.trim();

      await auth.createUserWithEmailAndPassword(email: email, password: pass);
      await auth.currentUser?.updateDisplayName(name.isEmpty ? email.split('@').first : name);

      await StorageService.saveUserData(
        email: email,
        name: name.isEmpty ? email.split('@').first : name,
        loginMethod: 'email',
      );

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
        (_) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String msg = e.message ?? 'Sign up failed';
      if (e.code == 'email-already-in-use') {
        msg = 'Email already in use. Try logging in.';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Sign up failed: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
                    child: const Icon(Icons.person_add_alt_1,
                        size: 44, color: Color(0xFF5B7FFF)),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Create account',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Join to start scanning and managing documents',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 28),

                  // Name
                  TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: 'Full name',
                      prefixIcon: const Icon(Icons.badge_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Email
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
                  const SizedBox(height: 14),

                  // Password
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Enter password';
                      if (v.length < 6) return 'Min 6 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 22),

                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _signUp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5B7FFF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Create account',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Already have an account? ', style: TextStyle(color: Colors.grey)),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Login', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ],
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

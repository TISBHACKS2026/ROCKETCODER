import 'package:flutter/material.dart';
import 'package:eco_tisb/utils/colors.dart';
import 'package:eco_tisb/utils/constants.dart';
import 'package:eco_tisb/widgets/custom_button.dart';
import 'package:eco_tisb/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _AuthDialog(
        isLogin: true,
        onAuth: (email, password, {fullName}) async {
          setState(() => _isLoading = true);
          try {
            await _supabaseService.signIn(email: email, password: password);
            if (!mounted) return;

            Navigator.pop(context); // Close dialog
            Navigator.pushReplacementNamed(context, '/marketplace');
          } on AuthException catch (e) {
            if (!mounted) return;
            Navigator.pop(context); // Close dialog
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(e.message), backgroundColor: Colors.red),
            );
          } catch (e) {
            if (!mounted) return;
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Connection error. Please try again.'), backgroundColor: Colors.red),
            );
          } finally {
            if (mounted) setState(() => _isLoading = false);
          }
        },
      ),
    );
  }

  Future<void> _handleSignUp() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _AuthDialog(
        isLogin: false,
        onAuth: (email, password, {fullName}) async {
          setState(() => _isLoading = true);
          try {
            final response = await _supabaseService.signUp(
              email: email,
              password: password,
              startFullName: fullName ?? 'Student',
            );
            if (!mounted) return;

            Navigator.pop(context);
            if (response.session == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Account created! Please check your email to confirm.'),
                  backgroundColor: AppColors.success,
                ),
              );
            } else {
              Navigator.pushReplacementNamed(context, '/marketplace');
            }
          } on AuthException catch (e) {
            if (!mounted) return;
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(e.message), backgroundColor: Colors.red),
            );
          } finally {
            if (mounted) setState(() => _isLoading = false);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // --- APP LOGO HEADER ---
              Container(
                padding: const EdgeInsets.all(12),
                child: Image.asset(
                  'assets/images/logo-nobg.png',
                  height: 120, // Increased size for better brand presence
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 16),
              // Hero Image / Card
              Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Stack(
                  children: [
                    const Center(
                      child: Icon(Icons.swap_horizontal_circle_outlined,
                          size: 80, color: AppColors.primaryGreen),
                    ),
                    Positioned(
                      bottom: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Text(
                              'SUSTAINABILITY INITIATIVE',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              const Text(
                'Exchange your old\ntextbooks and uniforms.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 12),

              const Text(
                'Save the planet, one swap at a time. Join the\nTISB community marketplace today.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),

              CustomButton(
                text: 'Login with Email',
                icon: Icons.login,
                onPressed: _handleLogin,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _handleSignUp,
                  icon: const Icon(Icons.person_add_outlined),
                  label: const Text('Create Account'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: const BorderSide(color: AppColors.primaryGreen),
                    foregroundColor: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Impact Counter
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.co2Green.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.eco,
                        size: 30,
                        color: AppColors.co2Green,
                      ),
                    ),

                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'LIVE CAMPUS IMPACT',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.co2Green,
                            ),
                          ),
                          StreamBuilder<Map<String, dynamic>>(
                            stream: _supabaseService.getGlobalStatsStream(),
                            builder: (context, snapshot) {
                              final co2 = snapshot.hasData
                                  ? (snapshot.data!['total_co2_saved'] ?? 0.0).toStringAsFixed(1)
                                  : '...';
                                  
                              return Text(
                                '$co2 Kg',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              );
                            },
                          ),
                          const Text(
                            'CO2 Saved by Students',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthDialog extends StatefulWidget {
  final bool isLogin;
  final Function(String email, String password, {String? fullName}) onAuth;

  const _AuthDialog({required this.isLogin, required this.onAuth});

  @override
  State<_AuthDialog> createState() => _AuthDialogState();
}

class _AuthDialogState extends State<_AuthDialog> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _errorMessage;


  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(widget.isLogin ? 'Welcome Back' : 'Join Verde'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!widget.isLogin)
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder()),
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'TISB Email', border: OutlineInputBorder()),
              keyboardType: TextInputType.emailAddress,
              validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
              obscureText: true,
              validator: (value) => (value?.length ?? 0) < 6 ? 'Min 6 chars' : null,
            ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen, foregroundColor: Colors.black),
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              if (!widget.isLogin) {
                final email = _emailController.text.trim().toLowerCase();
                if (!email.endsWith('@tisb.ac.in')) {
                  setState(() {
                    _errorMessage =
                        'Please enter a valid @tisb.ac.in email address.';
                  });
                  return;
                }
              }
              setState(() => _errorMessage = null);
              widget.onAuth(
                _emailController.text.trim(),
                _passwordController.text,
                fullName: widget.isLogin ? null : _nameController.text.trim(),
              );
            }
          },
          child: Text(widget.isLogin ? 'Login' : 'Get Started'),
        ),
      ],
    );
  }
}
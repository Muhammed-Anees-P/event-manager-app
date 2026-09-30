import 'package:flutter/material.dart';

import '../data/app_data_repository.dart';
import '../services/auth_session_service.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import 'main_shell_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _rememberMe = true;
  bool _isLoading = false;
  bool _isCheckingSession = true;

  @override
  void initState() {
    super.initState();
    _checkSavedSession();
  }

  Future<void> _checkSavedSession() async {
    final bool isLoggedIn = await AuthSessionService.instance.checkIsLoggedIn();
    if (!mounted) return;

    if (isLoggedIn) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainShellScreen()),
      );
    } else {
      setState(() {
        _isCheckingSession = false;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final String inputUser = _emailController.text.trim().toLowerCase();
    final String password = _passwordController.text;

    setState(() {
      _isLoading = true;
    });

    String targetEmail = inputUser;
    String targetName = 'Anees';

    if (inputUser == 'anees' || inputUser == 'anees@hayaevents.com') {
      targetEmail = 'anees@hayaevents.com';
      targetName = 'Anees';
    } else if (inputUser == 'mubeen' || inputUser == 'mubeen@hayaevents.com') {
      targetEmail = 'mubeen@hayaevents.com';
      targetName = 'Mubeen';
    } else {
      targetName = inputUser.split('@').first;
      if (!targetEmail.contains('@')) {
        targetEmail = '$inputUser@hayaevents.com';
      }
    }

    bool isValid = (password == 'anees@2255');

    if (SupabaseService.instance.isConfigured) {
      try {
        final res = await SupabaseService.instance.signInWithEmail(
          email: targetEmail,
          password: password,
        );
        if (res != null && res.session != null) {
          isValid = true;
        }
      } catch (e) {
        try {
          await SupabaseService.instance.signUp(
            email: targetEmail,
            password: password,
          );
          isValid = true;
        } catch (_) {}
      }
    } else {
      await Future.delayed(const Duration(milliseconds: 300));
    }

    if (!isValid) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid username or password. Use "anees" or "mubeen" with "anees@2255"'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Persistent login session
    await AuthSessionService.instance.saveSession(targetName, targetEmail);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const MainShellScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingSession) {
      return const Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
      );
    }

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;

          if (width >= 900) {
            return _buildTabletLayout();
          }

          return _buildMobileLayout();
        },
      ),
    );
  }

  // TABLET / DESKTOP LAYOUT
  Widget _buildTabletLayout() {
    return Row(
      children: [
        Expanded(flex: 5, child: _buildImageSection()),
        Expanded(
          flex: 5,
          child: Container(
            color: AppTheme.background,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 40),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: _buildLoginCard(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // MOBILE LAYOUT
  Widget _buildMobileLayout() {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: 260,
              width: double.infinity,
              child: _buildImageSection(),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: _buildLoginCard(showCardBackground: false),
            ),
          ],
        ),
      ),
    );
  }

  // BRAND IMAGE SECTION
  Widget _buildImageSection() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset('assets/images/login_bg.png', fit: BoxFit.cover),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0.2, 1.0],
              colors: [
                Colors.black.withValues(alpha: 0.15),
                Colors.black.withValues(alpha: 0.75),
              ],
            ),
          ),
        ),
        Positioned(
          top: 30,
          left: 30,
          child: Row(
            children: [
              _buildLogo(size: 40),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Haya',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    'Event Management',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Positioned(
          left: 30,
          right: 30,
          bottom: 35,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Turning Moments Into\nUnforgettable Memories',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  height: 1.25,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Container(width: 40, height: 2, color: Colors.white70),
              const SizedBox(height: 10),
              const Text(
                'Events  •  People  •  Happiness',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // CLEAN LOGIN CARD (Username, Password, Login Button)
  Widget _buildLoginCard({bool showCardBackground = true}) {
    final content = Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                _buildLogo(size: 54, dark: true),
                const SizedBox(height: 16),
                const Text(
                  'Sign In to Account',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Enter your username and password to continue',
                  style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Username Field
          const Text(
            'Username',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _emailController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              hintText: 'Enter username (anees or mubeen)',
              prefixIcon: Icon(Icons.person_outline, size: 20),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter username';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),

          // Password Field
          const Text(
            'Password',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _login(),
            decoration: InputDecoration(
              hintText: 'Enter password',
              prefixIcon: const Icon(Icons.lock_outline, size: 20),
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter password';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),

          // Remember Me Checkbox
          Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: Checkbox(
                  value: _rememberMe,
                  activeColor: AppTheme.primary,
                  onChanged: (value) {
                    setState(() {
                      _rememberMe = value ?? false;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              const Text('Keep me logged in', style: TextStyle(fontSize: 13, color: AppTheme.textMuted)),
            ],
          ),
          const SizedBox(height: 24),

          // LOGIN BUTTON
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _login,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text(
                      'Login',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );

    if (!showCardBackground) {
      return content;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 36),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            blurRadius: 24,
            spreadRadius: 0,
            offset: const Offset(0, 8),
            color: Colors.black.withValues(alpha: 0.06),
          ),
        ],
      ),
      child: content,
    );
  }

  Widget _buildLogo({required double size, bool dark = false}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: dark ? AppTheme.primary : Colors.white,
          width: 1.5,
        ),
      ),
      child: Center(
        child: Text(
          'H',
          style: TextStyle(
            color: dark ? AppTheme.primaryDark : Colors.white,
            fontSize: size * 0.48,
            fontWeight: FontWeight.w600,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }
}

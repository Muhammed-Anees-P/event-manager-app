import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

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
  bool _rememberMe = false;
  bool _isLoading = false;

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

    setState(() {
      _isLoading = true;
    });

    // TODO:
    // Connect backend login API here.
    //
    // Example:
    // POST /auth/login
    //
    // email
    // password

    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Login API will be connected next.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;

          // Tablet landscape / large screens
          if (width >= 900) {
            return _buildTabletLayout();
          }

          // Phone / portrait tablet
          return _buildMobileLayout();
        },
      ),
    );
  }

  // ============================================================
  // TABLET
  // ============================================================

  Widget _buildTabletLayout() {
    return Row(
      children: [
        // LEFT IMAGE
        Expanded(flex: 5, child: _buildImageSection()),

        // RIGHT LOGIN
        Expanded(
          flex: 5,
          child: Container(
            color: AppTheme.background,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 60,
                  vertical: 40,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: _buildLoginCard(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // MOBILE / PORTRAIT
  // ============================================================

  Widget _buildMobileLayout() {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: 300,
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

  // ============================================================
  // IMAGE SECTION
  // ============================================================

  Widget _buildImageSection() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset('assets/images/login_bg.png', fit: BoxFit.cover),

        // Dark overlay
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0.2, 1.0],
              colors: [
                Colors.black.withValues(alpha: 0.10),
                Colors.black.withValues(alpha: 0.72),
              ],
            ),
          ),
        ),

        // Brand
        Positioned(
          top: 35,
          left: 35,
          child: Row(
            children: [
              _buildLogo(size: 42),

              const SizedBox(width: 12),

              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Haya',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    'Event Management',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Bottom text
        Positioned(
          left: 40,
          right: 40,
          bottom: 45,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Turning Moments Into\nUnforgettable Memories',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  height: 1.25,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 18),

              Container(width: 50, height: 2, color: Colors.white70),

              const SizedBox(height: 14),

              const Text(
                'Events  •  People  •  Happiness',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // LOGIN CARD
  // ============================================================

  Widget _buildLoginCard({bool showCardBackground = true}) {
    final content = Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo
          Center(
            child: Column(
              children: [
                _buildLogo(size: 58, dark: true),

                const SizedBox(height: 20),

                const Text(
                  'Welcome Back',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                ),

                const SizedBox(height: 6),

                const Text(
                  'Sign in to manage your events',
                  style: TextStyle(fontSize: 14, color: AppTheme.textMuted),
                ),
              ],
            ),
          ),

          const SizedBox(height: 35),

          // EMAIL
          const Text(
            'Email',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppTheme.textDark,
            ),
          ),

          const SizedBox(height: 8),

          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              hintText: 'admin@hayaevents.com',
              prefixIcon: Icon(Icons.email_outlined, size: 20),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your email';
              }

              if (!value.contains('@')) {
                return 'Please enter a valid email';
              }

              return null;
            },
          ),

          const SizedBox(height: 20),

          // PASSWORD
          const Text(
            'Password',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
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
              hintText: 'Enter your password',

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
                return 'Please enter your password';
              }

              if (value.length < 6) {
                return 'Password must contain at least 6 characters';
              }

              return null;
            },
          ),

          const SizedBox(height: 12),

          // REMEMBER / FORGOT
          Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
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

              const Text(
                'Remember me',
                style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
              ),

              const Spacer(),

              TextButton(
                onPressed: () {
                  // TODO: Forgot password
                },
                child: const Text(
                  'Forgot password?',
                  style: TextStyle(color: AppTheme.primaryDark, fontSize: 13),
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          // SIGN IN
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _login,
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Sign In',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 24),

          // OR
          Row(
            children: [
              const Expanded(child: Divider()),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Text(
                  'or',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                ),
              ),

              const Expanded(child: Divider()),
            ],
          ),

          const SizedBox(height: 20),

          // GOOGLE
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () {
                // TODO: Google login
              },
              icon: const Text(
                'G',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              label: const Text('Continue with Google'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.textDark,
                side: const BorderSide(color: Color(0xFFD8DDE5)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),

          const SizedBox(height: 35),

          // FOOTER
          Center(
            child: Column(
              children: [
                _buildLogo(size: 28, dark: true),

                const SizedBox(height: 8),

                const Text(
                  'Haya Event Management',
                  style: TextStyle(
                    color: AppTheme.primaryDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 5),

                const Text(
                  'Events  •  People  •  Happiness',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (!showCardBackground) {
      return content;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 42, vertical: 42),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            blurRadius: 30,
            spreadRadius: 0,
            offset: const Offset(0, 10),
            color: Colors.black.withValues(alpha: 0.06),
          ),
        ],
      ),
      child: content,
    );
  }

  // ============================================================
  // LOGO
  // ============================================================

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

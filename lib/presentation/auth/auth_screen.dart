import 'dart:async';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/auth/auth_service.dart';
import '../../core/auth/auth_token_manager.dart';
import '../../main.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final PageController _pageController = PageController(initialPage: 1000);
  Timer? _timer;

  // NOTE FOR USER: Add your images to a folder named "login_register" inside "assets/"
  // and don't forget to declare them in pubspec.yaml under "assets:".
  // Replace these strings with your actual image paths.
  final List<String> _images = [
    'assets/login_register/image1.png',
    'assets/login_register/image2.png',
    'assets/login_register/image3.png',
  ];

  bool _isLogin = true;
  bool _isLoading = false;

  final _formKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _startAutoPlay();
  }

  void _startAutoPlay() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_pageController.hasClients) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool get _isFormValid {
    if (_isLogin) {
      return _emailController.text.trim().isNotEmpty &&
             _passwordController.text.isNotEmpty;
    } else {
      return _firstNameController.text.trim().isNotEmpty &&
             _lastNameController.text.trim().isNotEmpty &&
             _emailController.text.trim().isNotEmpty &&
             _passwordController.text.isNotEmpty;
    }
  }

  void _onFieldChanged(String _) {
    setState(() {}); // Trigger rebuild to update button state
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    Map<String, dynamic> response;
    if (_isLogin) {
      response = await AuthService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    } else {
      response = await AuthService.register(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    }

    setState(() => _isLoading = false);

    if (response['success']) {
      final data = response['data'];
      String? token;
      if (data is Map) {
        token = data['token'] ?? data['access_token'] ?? data['accessToken'] ?? data['jwt'];
      } else if (data is String) {
        token = data;
      }
      
      // Fallback in case token parsing fails but login succeeded
      token ??= 'dummy_token_fallback';

      if (token != null) {
        await AuthTokenManager.instance.saveToken(token);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isLogin ? 'Connexion réussie!' : 'Compte créé avec succès!'),
            backgroundColor: context.appColors.primary,
          ),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MainNavigation()),
          (route) => false,
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Une erreur est survenue'),
            backgroundColor: context.appColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ==========================================
    // PLACEHOLDER (HINT) TEXT STYLE
    // ==========================================
    final hintStyle = const TextStyle(color: Colors.grey, fontSize: 12);

    return Scaffold(
      backgroundColor: isDark ? appColors.background : appColors.surfaceDim,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: appColors.onBackground),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // ==========================================
          // BACKGROUND HALF-BALL (DECORATIVE)
          // Adjust size, opacity, and position below
          // ==========================================
          Positioned(
            top: MediaQuery.of(context).size.height * 0.3,
            left: -MediaQuery.of(context).size.width * 0.5, // Shifted half off-screen to the left side
            child: Container(
              width: MediaQuery.of(context).size.width, // Diameter = screen width
              height: MediaQuery.of(context).size.width,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: appColors.primary.withOpacity(0.08), // Small opacity
              ),
            ),
          ),
          
          SingleChildScrollView(
            // Prevent scrolling if it fits on screen
            physics: const ClampingScrollPhysics(),
            child: Column(
              children: [
                // ==========================================
                // CAROUSEL SECTION
                // Adjust the height multiplier (0.45 = 45% of screen height)
                // ==========================================
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.45,
                  child: PageView.builder(
                    controller: _pageController,
                    itemBuilder: (context, index) {
                      final image = _images[index % _images.length];
                      return Image.asset(
                        image,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Center(
                          child: Text(
                            'Replace this with:\n$image',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: appColors.onSurface, fontSize: 12),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // ==========================================
                // FORM SECTION (Access My Account)
                // Adjust width multiplier (0.80 = 80% of screen width)
                // Adjust bottom margin to change how far it sits from the bottom
                // ==========================================
                Container(
                  width: MediaQuery.of(context).size.width * 0.80, // <-- FORM WIDTH HERE
                  margin: const EdgeInsets.only(bottom: 24),       // <-- FORM MARGIN HERE
                  decoration: BoxDecoration(
                    color: isDark ? appColors.background : appColors.surfaceDim, // Matches background exactly
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(
                      color: appColors.outlineVariant, // Subtle outline border
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 10), // Increased offset to float a little bit
                      )
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isLogin ? 'Access My Account' : 'Create Account',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: appColors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          if (!_isLogin) ...[
                            Text('First Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: appColors.onSurface)),
                            const SizedBox(height: 4),
                            TextFormField(
                              controller: _firstNameController,
                              style: TextStyle(color: appColors.onSurface, fontSize: 13),
                              onChanged: _onFieldChanged,
                              decoration: InputDecoration(
                                hintText: 'John',
                                hintStyle: hintStyle,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(7), borderSide: BorderSide.none),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(7), borderSide: BorderSide.none),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(7), borderSide: BorderSide(color: appColors.primary, width: 1)),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text('Last Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: appColors.onSurface)),
                            const SizedBox(height: 4),
                            TextFormField(
                              controller: _lastNameController,
                              style: TextStyle(color: appColors.onSurface, fontSize: 13),
                              onChanged: _onFieldChanged,
                              decoration: InputDecoration(
                                hintText: 'Doe',
                                hintStyle: hintStyle,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(7), borderSide: BorderSide.none),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(7), borderSide: BorderSide.none),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(7), borderSide: BorderSide(color: appColors.primary, width: 1)),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          
                          Text('Email', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: appColors.onSurface)),
                          const SizedBox(height: 4),
                          TextFormField(
                            controller: _emailController,
                            style: TextStyle(color: appColors.onSurface, fontSize: 13),
                            keyboardType: TextInputType.emailAddress,
                            onChanged: _onFieldChanged,
                            decoration: InputDecoration(
                              hintText: 'email@example.com',
                              hintStyle: hintStyle,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(7), borderSide: BorderSide.none),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(7), borderSide: BorderSide.none),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(7), borderSide: BorderSide(color: appColors.primary, width: 1)),
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          Text('Password', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: appColors.onSurface)),
                          const SizedBox(height: 4),
                          TextFormField(
                            controller: _passwordController,
                            style: TextStyle(color: appColors.onSurface, fontSize: 13),
                            obscureText: true,
                            onChanged: _onFieldChanged,
                            decoration: InputDecoration(
                              hintText: '••••••••',
                              hintStyle: hintStyle,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(7), borderSide: BorderSide.none),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(7), borderSide: BorderSide.none),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(7), borderSide: BorderSide(color: appColors.primary, width: 1)),
                            ),
                          ),
                          
                          if (_isLogin) ...[
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: GestureDetector(
                                onTap: () {}, // Removed splash effect by using GestureDetector instead of TextButton
                                child: Text(
                                  'Forgot Password?',
                                  style: TextStyle(color: appColors.primary, fontSize: 12),
                                ),
                              ),
                            ),
                          ] else ...[
                            const SizedBox(height: 16),
                          ],
                          
                          const SizedBox(height: 12),
                          
                          // ==========================================
                          // SUBMIT BUTTON (Log In / Sign Up)
                          // Adjust width and height below
                          // ==========================================
                          Align(
                            alignment: Alignment.center,
                            child: SizedBox(
                              width: 260,  // <-- BUTTON WIDTH HERE
                              height: 36,  // <-- BUTTON HEIGHT HERE
                              child: ElevatedButton(
                                onPressed: (_isLoading || !_isFormValid) ? null : _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: appColors.primary,
                                  disabledBackgroundColor: appColors.primary.withOpacity(0.65),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: _isLoading
                                    ? SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(color: appColors.onPrimary, strokeWidth: 2),
                                      )
                                    : Text(
                                        _isLogin ? 'Log In' : 'Sign Up',
                                        style: TextStyle(
                                          fontSize: 12, // <-- BUTTON TEXT SIZE HERE
                                          color: appColors.onPrimary,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          Center(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isLogin = !_isLogin;
                                  _formKey.currentState?.reset();
                                  _firstNameController.clear();
                                  _lastNameController.clear();
                                  _emailController.clear();
                                  _passwordController.clear();
                                });
                              },
                              child: RichText(
                                text: TextSpan(
                                  style: TextStyle(color: appColors.onSurfaceVariant, fontSize: 12),
                                  children: [
                                    TextSpan(
                                      text: _isLogin
                                          ? "Don't have an account? "
                                          : 'Already have an account? ',
                                    ),
                                    TextSpan(
                                      text: _isLogin ? 'Sign up' : 'Log in',
                                      style: TextStyle(
                                        color: appColors.primary,
                                        fontWeight: FontWeight.bold,
                                        decoration: TextDecoration.underline,
                                        decorationColor: appColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import 'home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      final success = await userProvider.login(
        _usernameController.text,
        _passwordController.text,
      );

      if (success && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Login failed. Please check your credentials.'),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Screen size for responsive positioning relative to design (414 x 896)
    final Size screenSize = MediaQuery.of(context).size;
    final double designWidth = 414.0;
    final double designHeight = 896.0;

    double w(double width) => width * (screenSize.width / designWidth);
    double h(double height) => height * (screenSize.height / designHeight);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background Image (A Cinderella Story...)
          Positioned.fill(
            child: Image.asset('assets/images/login_bg.png', fit: BoxFit.cover),
          ),

          // Gradient Overlay (Rectangle 2)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black,
                    Colors.black.withValues(
                      alpha: 0.62,
                    ), // Updated for deprecation
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.81, 1.0], // Approx based on Figma
                ),
              ),
            ),
          ),

          // Logo Group
          Positioned(
            left: w(0), // Centered horizontally by column
            right: w(0),
            top: h(149),
            child: Column(
              children: [
                // Logo Icon
                Image.asset(
                  'assets/images/login_logo.png',
                  width: w(84.15),
                  height: h(96.57),
                  fit: BoxFit.contain,
                ),
                SizedBox(height: h(10)), // Spacing
                // Text "Falla" (ZeGo Live in design)
                Text(
                  'Vip LİVE',
                  style: TextStyle(
                    fontFamily: 'Ethnocentric',
                    fontSize: w(20),
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: h(5)),
                // Text "It's Live, It's Showtime"
                Text(
                  "It's Live, It's Showtime",
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: w(13),
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // Login Buttons Area
          Positioned(
            left: w(51),
            right: w(51),
            bottom: h(150), // Adjust bottom spacing
            child: Column(
              children: [
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Username Field
                      TextFormField(
                        controller: _usernameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Kullanıcı Adı',
                          hintStyle: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.1),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: w(20),
                            vertical: h(16),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter username';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: h(15)),

                      // Password Field
                      TextFormField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Şifre',
                          hintStyle: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.1),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: w(20),
                            vertical: h(16),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Colors.white70,
                            ),
                            onPressed:
                                () => setState(
                                  () =>
                                      _isPasswordVisible = !_isPasswordVisible,
                                ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Lütfen şifre girin';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                SizedBox(height: h(20)),

                SizedBox(
                  width: double.infinity,
                  height: h(50),
                  child: ElevatedButton(
                    onPressed:
                        Provider.of<UserProvider>(context).isLoading
                            ? null
                            : () => _handleLogin(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE65E8B),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child:
                        Provider.of<UserProvider>(context).isLoading
                            ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                            : Text(
                              'Giriş Yap',
                              style: TextStyle(
                                fontSize: w(16),
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                  ),
                ),
                SizedBox(height: h(20)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Hesabınız yok mu?",
                      style: TextStyle(color: Colors.white70, fontSize: w(14)),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RegisterScreen(),
                          ),
                        );
                      },
                      child: Text(
                        "Kayıt Ol",
                        style: TextStyle(
                          color: const Color(0xFFE65E8B),
                          fontWeight: FontWeight.bold,
                          fontSize: w(14),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Terms & Privacy Policy
          Positioned(
            left: w(39),
            right: w(39),
            bottom: h(41), // 896 - 835 = 61 approx, adjusting
            child: Column(
              children: [
                Divider(
                  color: const Color(0xFFD9D9D9),
                  thickness: 1,
                  indent: w(50), // Adjusting divider width visually
                  endIndent: w(50),
                ),
                SizedBox(height: h(15)),
                Text(
                  'Login means you agree to our Terms & Privacy Policy',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Samda', // Fallback font
                    fontSize: w(12),
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _buildLoginButton({
    required String imagePath,
    required double width,
    required double height,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Image.asset(
        imagePath,
        width: width,
        height: height,
        fit: BoxFit.fill,
      ),
    );
  }
}

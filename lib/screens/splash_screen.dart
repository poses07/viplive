import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart'; // flutter_svg package
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Navigate to Login Screen after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    });
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
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/splash_bg.png',
              fit: BoxFit.cover,
            ),
          ),

          // Gradient Overlay
          Positioned(
            left: w(-125),
            top: h(0),
            width: w(989),
            height: h(2173),
            child: SvgPicture.asset(
              'assets/images/splash_gradient.svg',
              fit: BoxFit.fill,
            ),
          ),

          // Girl Image
          Positioned(
            left: w(0),
            top: h(-1),
            width: w(607),
            height: h(910),
            child: Image.asset(
              'assets/images/splash_girl.png',
              fit: BoxFit.cover,
            ),
          ),

          // Text Graphic "It's Live It's Showtime"
          Positioned(
            left: w(38),
            top: h(299),
            width: w(338),
            height: h(123),
            child: Image.asset(
              'assets/images/splash_text_graphic.png',
              fit: BoxFit.contain,
            ),
          ),

          // Logo Group
          Positioned(
            left: w(165),
            top: h(129),
            child: Column(
              children: [
                // Logo Icon Container
                Container(
                  width: w(72.91),
                  height: w(72.91),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(w(11.5)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        offset: Offset(0, 3),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Image.asset(
                      'assets/images/splash_logo.png',
                      width: w(46.81),
                      height: h(53.72),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                SizedBox(height: h(5)),
                // Text "ZeGo Live" (or Falla)
                Text(
                  'Vip LİVE', // Changing to Falla as per user intent
                  style: TextStyle(
                    fontFamily:
                        'Ethnocentric', // Fallback to default if not available
                    fontSize: w(12),
                    fontWeight: FontWeight.bold,
                    color:
                        Colors
                            .white, // Assuming white text on dark/gradient background
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

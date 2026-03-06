import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:viplive/screens/home_screen.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final TextEditingController _nicknameController = TextEditingController();
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double designWidth = 414.0;
    final double designHeight = 896.0;

    double w(double width) => width * (screenSize.width / designWidth);
    double h(double height) => height * (screenSize.height / designHeight);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background Image (Reuse from Register or Login)
          Positioned.fill(
            child: Image.asset(
              'assets/images/register_background.png', // Reusing register background for consistency
              fit: BoxFit.cover,
            ),
          ),
          // Gradient Overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.2),
                    Colors.black.withValues(alpha: 0.8),
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: w(36)),
                child: Column(
                  children: [
                    SizedBox(height: h(40)),
                    // Title
                    Text(
                      'Profile Setup',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: w(24),
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: h(10)),
                    Text(
                      'Fill in your details',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: w(14),
                        color: Colors.white70,
                      ),
                    ),

                    SizedBox(height: h(60)),

                    // Profile Photo Upload
                    GestureDetector(
                      onTap: _pickImage,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            width: w(120),
                            height: w(120),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.1),
                              border: Border.all(
                                color: const Color(0xFFE65E8B),
                                width: 2,
                              ),
                              image:
                                  _imageFile != null
                                      ? DecorationImage(
                                        image: FileImage(_imageFile!),
                                        fit: BoxFit.cover,
                                      )
                                      : null,
                            ),
                            child:
                                _imageFile == null
                                    ? Icon(
                                      Icons.person,
                                      size: w(60),
                                      color: Colors.white54,
                                    )
                                    : null,
                          ),
                          Container(
                            padding: EdgeInsets.all(w(8)),
                            decoration: const BoxDecoration(
                              color: Color(0xFFE65E8B),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: w(20),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: h(40)),

                    // Nickname Input
                    Container(
                      width: double.infinity,
                      height: h(50),
                      decoration: BoxDecoration(
                        color: const Color(0x1AFEF8F8),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 0.5,
                        ),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: w(16)),
                      child: Row(
                        children: [
                          Icon(Icons.edit, color: Colors.white70, size: w(20)),
                          SizedBox(width: w(12)),
                          Expanded(
                            child: TextField(
                              controller: _nicknameController,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: w(14),
                                color: Colors.white,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Nickname (Rumuz)',
                                hintStyle: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: w(14),
                                  color: Colors.white54,
                                ),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: h(60)),

                    // Complete Button
                    GestureDetector(
                      onTap: () {
                        // Basic Validation
                        if (_nicknameController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter a nickname'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        // Navigate to Home Screen
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const HomeScreen(),
                          ),
                          (route) => false, // Remove all previous routes
                        );
                      },
                      child: Container(
                        width: w(263),
                        height: h(57),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE65E8B),
                          borderRadius: BorderRadius.circular(100),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFFE65E8B,
                              ).withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Complete',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: w(17),
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

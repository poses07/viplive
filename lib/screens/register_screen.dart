import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import 'package:viplive/screens/profile_setup_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _inviteCodeController = TextEditingController();

  String _selectedGender = ''; // 'Male' or 'Female'

  @override
  void dispose() {
    _nameController.dispose();
    _dobController.dispose();
    _countryController.dispose();
    _inviteCodeController.dispose();
    super.dispose();
  }

  // ignore: unused_element
  Future<void> _handleRegister() async {
    if (_nameController.text.isEmpty ||
        _dobController.text.isEmpty ||
        _countryController.text.isEmpty ||
        _inviteCodeController.text.isEmpty ||
        _selectedGender.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields and select gender'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final userProvider = Provider.of<UserProvider>(context, listen: false);

    final success = await userProvider.register(
      username: _nameController.text,
      password: 'password', // Placeholder as password field is missing in UI
    );

    if (success && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ProfileSetupScreen()),
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Registration failed.')));
      }
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
      backgroundColor: Colors.black, // Fallback
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/register_background.png',
              fit: BoxFit.cover,
            ),
          ),
          // Gradient Overlay (optional, matching style)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.1),
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),
          ),

          // Content
          SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: w(36),
              ), // Based on Figma X=36
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: h(65)), // Top spacing
                  // Top Icon
                  Center(
                    child: SvgPicture.asset(
                      'assets/images/register_top_icon.svg',
                      width: w(139),
                      height: w(139),
                    ),
                  ),
                  SizedBox(height: h(40)), // Spacing
                  // Fields
                  _buildTextField(
                    label: 'Your Name',
                    iconPath: 'assets/images/icon_person.svg',
                    controller: _nameController,
                    w: w,
                    h: h,
                  ),
                  SizedBox(height: h(16)),
                  _buildTextField(
                    label: 'Date of birth',
                    iconPath: 'assets/images/icon_calendar.svg',
                    controller: _dobController,
                    w: w,
                    h: h,
                  ),
                  SizedBox(height: h(16)),
                  _buildTextField(
                    label: 'Country',
                    iconPath: 'assets/images/icon_country.svg',
                    controller: _countryController,
                    w: w,
                    h: h,
                  ),
                  SizedBox(height: h(16)),
                  _buildTextField(
                    label: 'Invitation code',
                    iconPath: 'assets/images/icon_invite.svg',
                    controller: _inviteCodeController,
                    w: w,
                    h: h,
                  ),

                  SizedBox(height: h(24)),

                  // Gender Section
                  Text(
                    'Choose gender',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: w(18),
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: h(4)),
                  Text(
                    'Choose your gender identity',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: w(10),
                      color: const Color(0xFFBEB8FE),
                    ),
                  ),
                  SizedBox(height: h(16)),

                  // Gender Buttons Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildGenderButton(
                        'Male',
                        'assets/images/gender_male.svg',
                        w,
                        h,
                      ),
                      _buildGenderButton(
                        'Female',
                        'assets/images/gender_female.svg',
                        w,
                        h,
                      ),
                    ],
                  ),

                  SizedBox(height: h(24)),

                  // Prefer not to say
                  Center(
                    child: Text(
                      "I'd prefer not to say",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: w(12),
                        color: const Color(0xFFBEB8FE),
                      ),
                    ),
                  ),
                  SizedBox(height: h(8)),
                  Center(
                    child: Text(
                      "Your gender won't be shown to others. It is only used to help filter matches",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: w(8),
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ),

                  SizedBox(height: h(32)),

                  // Submit Button
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        // Basic Validation
                        if (_nameController.text.isEmpty ||
                            _dobController.text.isEmpty ||
                            _countryController.text.isEmpty ||
                            _inviteCodeController.text.isEmpty ||
                            _selectedGender.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Please fill all fields and select gender',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        // Navigate to Profile Setup
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProfileSetupScreen(),
                          ),
                        );
                      },
                      child: Container(
                        width: w(263),
                        height: h(57),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE65E8B),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Submit',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: w(17),
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: h(50)), // Bottom padding
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String iconPath,
    required TextEditingController controller,
    required Function(double) w,
    required Function(double) h,
  }) {
    return Container(
      width: double.infinity,
      height: h(48),
      decoration: BoxDecoration(
        color: const Color(0x1AFEF8F8), // rgba(254, 248, 248, 0.1)
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 0.2,
        ),
      ),
      child: Row(
        children: [
          SizedBox(width: w(20)),
          SvgPicture.asset(
            iconPath,
            width: w(22),
            height: w(22),
            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
          ),
          SizedBox(width: w(16)),
          Expanded(
            child: TextField(
              controller: controller,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: w(13),
                color: Colors.white,
              ),
              decoration: InputDecoration(
                hintText: label,
                hintStyle: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: w(13),
                  color: Colors.white.withValues(alpha: 0.7),
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero, // Align text vertically
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderButton(
    String gender,
    String iconPath,
    Function(double) w,
    Function(double) h,
  ) {
    bool isSelected = _selectedGender == gender;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedGender = gender;
        });
      },
      child: Column(
        children: [
          Container(
            width: w(60),
            height: w(60),
            decoration: const BoxDecoration(shape: BoxShape.circle),
            child: SvgPicture.asset(iconPath),
          ),
          SizedBox(height: h(8)),
          Container(
            padding: EdgeInsets.symmetric(horizontal: w(12), vertical: h(4)),
            decoration: BoxDecoration(
              color:
                  isSelected
                      ? const Color(0xFFE65E8B)
                      : Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              gender,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: w(12),
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

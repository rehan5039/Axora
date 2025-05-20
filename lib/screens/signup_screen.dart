import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:axora/services/auth_service.dart';
import 'package:email_validator/email_validator.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:axora/widgets/axora_logo.dart';
import 'package:provider/provider.dart';
import 'package:axora/providers/theme_provider.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  String _errorMessage = '';
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  
  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      try {
        if (_passwordController.text != _confirmPasswordController.text) {
          throw FirebaseAuthException(
            code: 'passwords-dont-match',
            message: 'Passwords do not match',
          );
        }

        await _authService.signUpWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text,
          fullName: _nameController.text.trim(),
        );

        if (mounted) {
          // Navigate to home screen
          Navigator.of(context).pushReplacementNamed('/home');
        }
      } on FirebaseAuthException catch (e) {
        setState(() {
          _errorMessage = e.message ?? 'An error occurred during sign up';
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signUpWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final userCredential = await _authService.signInWithGoogle();
      
      if (userCredential != null && mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      } else if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Google sign-in was cancelled';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        
        // Provide more user-friendly error messages
        if (e.toString().contains('SHA-1 key')) {
          _errorMessage = 'Google Sign-In is not properly configured. Please contact support.';
        } else if (e.toString().contains('network')) {
          _errorMessage = 'Network error. Please check your internet connection and try again.';
        } else if (e.toString().contains('Google Play Services')) {
          _errorMessage = 'Google Play Services issue. Please make sure Google Play Services is updated on your device.';
        } else {
          // If not a recognized error, show the original error
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        }
        
        // Log the original error for debugging
        print('Google Sign-Up Error: $e');
      });
    }
  }

  Future<void> _skipLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      final userCredential = await _authService.signInAnonymously();
      
      if (userCredential != null && mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to sign in anonymously: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final textColor = isDarkMode ? Colors.white : Colors.grey[700];
    final backgroundColor = isDarkMode ? Colors.black : Colors.white;
    
    final screenWidth = MediaQuery.of(context).size.width;
    final inputFieldWidth = screenWidth * 0.8; // Limit width to 80% of screen

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _skipLogin,
            child: Text(
              'Skip Login',
              style: GoogleFonts.poppins(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // App Logo
                  const AxoraLogo(fontSize: 64),
                  const SizedBox(height: 20),
                  
                  // Title
                  Text(
                    'Create Account',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Subtitle
                  Text(
                    'Join Axora and start exploring',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Error message
                  if (_errorMessage.isNotEmpty)
                    Container(
                      width: inputFieldWidth,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.red.shade900.withOpacity(0.3) : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _errorMessage,
                        style: GoogleFonts.poppins(
                          color: isDarkMode ? Colors.red.shade200 : Colors.red,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  if (_errorMessage.isNotEmpty) const SizedBox(height: 20),
                  
                  // Name Field
                  Container(
                    width: inputFieldWidth,
                    child: TextFormField(
                      controller: _nameController,
                      style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        labelStyle: TextStyle(color: isDarkMode ? Colors.white70 : null),
                        hintText: 'Enter your full name',
                        hintStyle: TextStyle(color: isDarkMode ? Colors.white30 : null),
                        prefixIcon: Icon(Icons.person_outline, color: isDarkMode ? Colors.white70 : null),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: isDarkMode ? Colors.white54 : Colors.grey),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: isDarkMode ? Colors.white38 : Colors.grey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Theme.of(context).primaryColor),
                        ),
                        filled: isDarkMode,
                        fillColor: isDarkMode ? Colors.grey[800] : null,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 15,
                          horizontal: 20,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Email Field
                  Container(
                    width: inputFieldWidth,
                    child: TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
                      decoration: InputDecoration(
                        labelText: 'Email',
                        labelStyle: TextStyle(color: isDarkMode ? Colors.white70 : null),
                        hintText: 'Enter your email address',
                        hintStyle: TextStyle(color: isDarkMode ? Colors.white30 : null),
                        prefixIcon: Icon(Icons.email_outlined, color: isDarkMode ? Colors.white70 : null),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: isDarkMode ? Colors.white54 : Colors.grey),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: isDarkMode ? Colors.white38 : Colors.grey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Theme.of(context).primaryColor),
                        ),
                        filled: isDarkMode,
                        fillColor: isDarkMode ? Colors.grey[800] : null,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 15,
                          horizontal: 20,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!EmailValidator.validate(value.trim())) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Password Field
                  Container(
                    width: inputFieldWidth,
                    child: TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        labelStyle: TextStyle(color: isDarkMode ? Colors.white70 : null),
                        hintText: 'Create a password',
                        hintStyle: TextStyle(color: isDarkMode ? Colors.white30 : null),
                        prefixIcon: Icon(Icons.lock_outline, color: isDarkMode ? Colors.white70 : null),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: isDarkMode ? Colors.white70 : null,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: isDarkMode ? Colors.white54 : Colors.grey),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: isDarkMode ? Colors.white38 : Colors.grey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Theme.of(context).primaryColor),
                        ),
                        filled: isDarkMode,
                        fillColor: isDarkMode ? Colors.grey[800] : null,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 15,
                          horizontal: 20,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Confirm Password Field
                  Container(
                    width: inputFieldWidth,
                    child: TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        labelStyle: TextStyle(color: isDarkMode ? Colors.white70 : null),
                        hintText: 'Confirm your password',
                        hintStyle: TextStyle(color: isDarkMode ? Colors.white30 : null),
                        prefixIcon: Icon(Icons.lock_outline, color: isDarkMode ? Colors.white70 : null),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                            color: isDarkMode ? Colors.white70 : null,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword = !_obscureConfirmPassword;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: isDarkMode ? Colors.white54 : Colors.grey),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: isDarkMode ? Colors.white38 : Colors.grey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Theme.of(context).primaryColor),
                        ),
                        filled: isDarkMode,
                        fillColor: isDarkMode ? Colors.grey[800] : null,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 15,
                          horizontal: 20,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm your password';
                        }
                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Sign Up Button
                  SizedBox(
                    width: inputFieldWidth,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _signUp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              'Sign Up',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // OR Divider
                  Container(
                    width: inputFieldWidth,
                    child: Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
                            thickness: 1,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'OR',
                            style: GoogleFonts.poppins(
                              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
                            thickness: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Google Sign In Button
                  SizedBox(
                    width: inputFieldWidth,
                    height: 55,
                    child: OutlinedButton.icon(
                      icon: SvgPicture.asset(
                        'assets/images/google_logo.svg',
                        height: 24,
                        width: 24,
                      ),
                      label: Text(
                        'Continue with Google',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      onPressed: _isLoading ? null : _signUpWithGoogle,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: isDarkMode ? Colors.grey[600]! : Colors.grey[300]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: isDarkMode ? Colors.grey[800] : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Login Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account?',
                        style: GoogleFonts.poppins(color: isDarkMode ? Colors.grey[300] : Colors.grey[700]),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pushReplacementNamed('/login');
                        },
                        child: Text(
                          'Log In',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
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
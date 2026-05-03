// lib/screens/auth_screens.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../globals.dart';
import 'dashboard_screen.dart';
import 'admin_dashboard.dart'; 

// ==================== MODERN UI TOAST HELPERS ====================
void showErrorToast(BuildContext context, String message) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar(); 
  final screenHeight = MediaQuery.of(context).size.height;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.white, size: 24),
          const SizedBox(width: 12),
          Expanded(child: Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))),
        ],
      ),
      backgroundColor: Colors.red.shade700, 
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), 
      margin: EdgeInsets.only(bottom: screenHeight - 130, left: 20, right: 20),
      dismissDirection: DismissDirection.up,
      elevation: 4,
      duration: const Duration(seconds: 4),
    ),
  );
}

void showSuccessToast(BuildContext context, String message) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  final screenHeight = MediaQuery.of(context).size.height;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: Colors.white, size: 24),
          const SizedBox(width: 12),
          Expanded(child: Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))),
        ],
      ),
      backgroundColor: Colors.green.shade700, 
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: EdgeInsets.only(bottom: screenHeight - 130, left: 20, right: 20),
      dismissDirection: DismissDirection.up,
      elevation: 4,
      duration: const Duration(seconds: 3),
    ),
  );
}

// ==================== SHARED DESIGN CONSTANTS ====================
const Color primaryBlue = Color(0xFF1A0088);
const Color accentYellow = Color(0xFFFFD700);
const Color textDark = Color(0xFF1F2937);
const Color textLight = Color(0xFF6B7280);
const Color borderGrey = Color(0xFFE5E7EB);
const Color bgGray = Color(0xFFF8FAFC);

InputDecoration modernInputDecoration(String hint, {Widget? suffixIcon}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: textLight, fontSize: 14),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: borderGrey)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: borderGrey)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: primaryBlue, width: 1.5)),
    errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.red.shade300)),
    errorStyle: TextStyle(color: Colors.red.shade400, fontWeight: FontWeight.w600, fontSize: 12),
    errorMaxLines: 2, // Added to allow longer validation messages
    suffixIcon: suffixIcon,
  );
}

// ==================== AUTH SCREENS ====================
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePass = true;
  bool _isLoading = false;

  Future<void> doLogin() async {
    if (!_formKey.currentState!.validate()) {
      showErrorToast(context, "Please fix the missing fields to login.");
      return;
    }
    setState(() => _isLoading = true);

    try {
      var res = await http.post(
        Uri.parse('https://huramay-app.onrender.com/api/login'), 
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': _emailCtrl.text.trim(), 'password': _passCtrl.text}),
      );
      if (!mounted) return; 

      var data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        currentUser = data;
        
        try {
          String? fcmToken = await FirebaseMessaging.instance.getToken();
          if (fcmToken != null) {
            await http.post(
              Uri.parse('https://huramay-app.onrender.com/api/user/update_token'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'user_id': data['id'],
                'fcm_token': fcmToken
              }),
            );
          }
        } catch (e) {
          debugPrint("FCM token error");
        }

        bool isAdmin = data['is_admin'] ?? false;
        showSuccessToast(context, "Welcome back!");
        
        if (isAdmin) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const AdminDashboard()));
        } else {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const DashboardScreen()));
        }
      } else {
        showErrorToast(context, data['message']);
      }
    } catch (e) {
      showErrorToast(context, "Connection Error. Please check your internet.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), 
      body: Stack(
        children: [
          Positioned(
            top: -100, right: -50,
            child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, color: primaryBlue.withOpacity(0.04))),
          ),
          Positioned(
            top: 150, left: -100,
            child: Container(width: 200, height: 200, decoration: BoxDecoration(shape: BoxShape.circle, color: accentYellow.withOpacity(0.05))),
          ),
          
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16), 
                        child: Image.asset('assets/images/huramay_logo.png', height: 90),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text("Huramay", textAlign: TextAlign.center, style: TextStyle(fontSize: 36, color: primaryBlue, fontWeight: FontWeight.w900, letterSpacing: -1.0)),
                    const SizedBox(height: 8),
                    const Text("Sign in to your account", textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: textLight)),
                    const SizedBox(height: 40),
                    
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24), 
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 24, offset: const Offset(0, 10))],
                        border: Border.all(color: Colors.grey.shade100, width: 1.5),
                      ),
                      child: Form( 
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text("Email", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textDark)),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _emailCtrl,
                              style: const TextStyle(color: textDark, fontWeight: FontWeight.w500),
                              decoration: modernInputDecoration("@gmail.com"),
                              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                            ),
                            const SizedBox(height: 20),
                            
                            const Text("Password", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textDark)),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _passCtrl,
                              obscureText: _obscurePass,
                              style: const TextStyle(color: textDark, fontWeight: FontWeight.w500),
                              decoration: modernInputDecoration("••••••••", suffixIcon: IconButton(
                                icon: Icon(_obscurePass ? Icons.visibility_off : Icons.visibility, color: textLight, size: 20),
                                onPressed: () => setState(() => _obscurePass = !_obscurePass),
                              )),
                              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                            ),
                            const SizedBox(height: 32),
                            
                            SizedBox(
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : doLogin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryBlue, foregroundColor: Colors.white, elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: _isLoading 
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: accentYellow, strokeWidth: 2))
                                  : const Text("Sign In", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            TextButton(
                              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const UniversalRecoveryScreen())),
                              child: const Text("Forgot Password?", style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold)),
                            )
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Don't have an account? ", style: TextStyle(color: textLight)),
                        GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const SignUpScreen())),
                          child: const Text("Create one", style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold)),
                        )
                      ],
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

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});
  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confCtrl = TextEditingController();
  
  final _colorCtrl = TextEditingController();
  final _songCtrl = TextEditingController();
  
  String? _selectedDept;
  final _formKey = GlobalKey<FormState>();
  bool _obscurePass = true;
  bool _obscureConf = true;
  bool _isLoading = false;

  final List<String> _lnuDepartments = [
    'Bachelor of Elementary Education', 'Bachelor of Early Childhood Education', 'Bachelor of Special Needs Education', 'Bachelor of Technology and Livelihood Education', 'Bachelor of Physical Education', 'Bachelor of Secondary Education major in English', 'Bachelor of Secondary Education major in Filipino', 'Bachelor of Secondary Education major in Mathematics', 'Bachelor of Secondary Education major in Science', 'Bachelor of Secondary Education major in Social Studies', 'Bachelor of Secondary Education major in Values Education', 'Teacher Certificate Program (TCP)', 'Bachelor of Library and Information Science', 'Bachelor of Arts in Communication', 'Bachelor of Music in Music Education', 'Bachelor of Science in Information Technology', 'Bachelor of Arts in English Language', 'Bachelor of Arts in Political Science', 'Bachelor of Science in Biology', 'Bachelor of Science in Social Work', 'Bachelor of Science in Tourism Management', 'Bachelor of Science in Hospitality Management', 'Bachelor of Science in Entrepreneurship', 'Faculty / Staff'
  ];

  Future<void> doSignup() async {
    if (!_formKey.currentState!.validate()) {
      showErrorToast(context, "Please fix the form errors before submitting.");
      return;
    }
    if (_selectedDept == null) {
      showErrorToast(context, "Please select your department from the dropdown.");
      return;
    }
    
    setState(() => _isLoading = true);
    String emailInput = _emailCtrl.text.trim().toLowerCase();
    
    try {
      var res = await http.post(
        Uri.parse('https://huramay-app.onrender.com/api/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'full_name': _nameCtrl.text.trim(), 
          'email': emailInput, 
          'department': _selectedDept, 
          'password': _passCtrl.text,
          'security_color': _colorCtrl.text.trim(),
          'security_song': _songCtrl.text.trim()
        }),
      );
      if (!mounted) return;

      if (res.statusCode == 201) {
        Navigator.pop(context);
        showSuccessToast(context, "Account created! Please log in.");
      } else {
        var data = jsonDecode(res.body);
        showErrorToast(context, data['message']);
      }
    } catch (e) {
      showErrorToast(context, "Connection Error. Please check your internet.");
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
        elevation: 0,
        iconTheme: const IconThemeData(color: textDark),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
        child: Form( 
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset('assets/images/huramay_logo.png', height: 70),
                ),
              ),
              const SizedBox(height: 24),
              const Text("Create Account", style: TextStyle(fontSize: 32, color: primaryBlue, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
              const SizedBox(height: 8),
              const Text("Join Huramay to get started", style: TextStyle(fontSize: 16, color: textLight)),
              const SizedBox(height: 40),
              
              const Text("Full Name", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textDark)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameCtrl,
                style: const TextStyle(color: textDark, fontWeight: FontWeight.w500),
                decoration: modernInputDecoration("John Doe"),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (!RegExp(r'^[a-zA-Z\s\.]+$').hasMatch(v)) return 'No numbers or special characters';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              const Text("Email", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textDark)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _emailCtrl,
                style: const TextStyle(color: textDark, fontWeight: FontWeight.w500),
                decoration: modernInputDecoration("@gmail.com"),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  bool hasEmoji = RegExp(r'[\u00A9\u00AE\u2000-\u3300\ud83c\ud000-\ud83c\udfff\ud83d\ud000-\ud83d\udfff\ud83e\ud000-\ud83e\udfff]').hasMatch(v);
                  bool hasSpecialChars = v.contains(RegExp(r'[!#\$%^&*() \?":{}|<>]'));
                  if (hasEmoji || hasSpecialChars) return 'No special chars or emoji allowed';
                  if (!v.toLowerCase().endsWith('@gmail.com')) return 'Must end with @gmail.com'; 
                  return null;
                },
              ),
              const SizedBox(height: 20),

              const Text("Department", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textDark)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                isExpanded: true,
                value: _selectedDept,
                hint: const Text("Select program", style: TextStyle(color: textLight, fontSize: 14)),
                icon: const Icon(Icons.expand_more, color: textLight),
                items: _lnuDepartments.map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontSize: 14, color: textDark, fontWeight: FontWeight.w500)))).toList(),
                onChanged: (v) => setState(() => _selectedDept = v),
                decoration: modernInputDecoration(""),
              ),
              const SizedBox(height: 32),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: bgGray,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderGrey)
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.security, color: primaryBlue, size: 20),
                        SizedBox(width: 8),
                        Text("Account Recovery Setup", style: TextStyle(fontWeight: FontWeight.bold, color: primaryBlue)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text("What is your favorite color?", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textDark)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _colorCtrl,
                      decoration: modernInputDecoration("e.g. Blue"),
                      validator: (v) => v == null || v.isEmpty ? 'Required for account recovery' : null,
                    ),
                    const SizedBox(height: 16),
                    const Text("What is your favorite song?", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textDark)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _songCtrl,
                      decoration: modernInputDecoration("e.g. Bohemian Rhapsody"),
                      validator: (v) => v == null || v.isEmpty ? 'Required for account recovery' : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              const Text("Password", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textDark)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _passCtrl,
                obscureText: _obscurePass,
                autovalidateMode: AutovalidateMode.onUserInteraction, // Live validation as user types
                style: const TextStyle(color: textDark, fontWeight: FontWeight.w500),
                decoration: modernInputDecoration("••••••••", suffixIcon: IconButton(
                  icon: Icon(_obscurePass ? Icons.visibility_off : Icons.visibility, color: textLight, size: 20),
                  onPressed: () => setState(() => _obscurePass = !_obscurePass),
                )),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Password is required';
                  
                  // LIVE VALIDATION CHECKS
                  if (v.length < 8 || v.length > 12) return 'Must be between 8 and 12 characters.';
                  if (!v.contains(RegExp(r'[A-Z]'))) return 'Must include at least 1 uppercase letter.';
                  if (!v.contains(RegExp(r'[a-z]'))) return 'Must include at least 1 lowercase letter.';
                  if (!v.contains(RegExp(r'[0-9]'))) return 'Must include at least 1 number.';
                  if (!v.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'))) return 'Must include at least 1 special character (e.g. @, #, \$, &).';
                  if (v.contains(RegExp(r'[^\x00-\x7F]'))) return 'Standard characters only. No emojis allowed.';
                  
                  return null;
                },
              ),
              const SizedBox(height: 20),

              const Text("Confirm Password", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textDark)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _confCtrl,
                obscureText: _obscureConf,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                style: const TextStyle(color: textDark, fontWeight: FontWeight.w500),
                decoration: modernInputDecoration("••••••••", suffixIcon: IconButton(
                  icon: Icon(_obscureConf ? Icons.visibility_off : Icons.visibility, color: textLight, size: 20),
                  onPressed: () => setState(() => _obscureConf = !_obscureConf),
                )),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Please confirm your password';
                  if (v != _passCtrl.text) return 'Passwords do not match';
                  return null;
                },
              ),
              
              const SizedBox(height: 40),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : doSignup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isLoading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: accentYellow, strokeWidth: 2))
                    : const Text("Create Account", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== PROFILE SCREEN ====================
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _imageBase64;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _imageBase64 = currentUser?['photo_path'];
    if (_imageBase64 != null && _imageBase64!.isEmpty) _imageBase64 = null;
  }

  Future<void> _pickImage() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 20, 
      maxWidth: 400,    
      maxHeight: 400,
    );
    
    if (image != null) {
      final bytes = await File(image.path).readAsBytes();
      setState(() {
        _imageBase64 = base64Encode(bytes);
      });
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);
    try {
      var res = await http.post(
        Uri.parse('https://huramay-app.onrender.com/api/user/update'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id': currentUser!['id'], 'photo_path': _imageBase64 ?? ""}),
      );
      if (res.statusCode == 200) {
        currentUser!['photo_path'] = _imageBase64; 
        if (mounted) showSuccessToast(context, "Profile Saved");
      } else {
        if (mounted) showErrorToast(context, "Failed to save profile.");
      }
    } catch (e) {
      if (mounted) showErrorToast(context, "Connection error.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _logout() {
    currentUser = null;
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (c) => const LoginScreen()), (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    double rating = (currentUser?['rating'] ?? 0.0).toDouble();
    List<Widget> stars = List.generate(5, (index) => Icon(
      index < rating ? Icons.star : Icons.star_border, 
      color: accentYellow, 
      size: 20
    ));
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: textDark),
        title: const Text("Profile", style: TextStyle(color: textDark, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(color: borderGrey, height: 1)),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          children: [
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                      border: Border.all(color: borderGrey, width: 1),
                      image: (_imageBase64 != null && _imageBase64!.isNotEmpty)
                        ? DecorationImage(image: MemoryImage(base64Decode(_imageBase64!)), fit: BoxFit.cover) 
                        : null,
                    ),
                    child: (_imageBase64 == null || _imageBase64!.isEmpty) 
                      ? const Icon(Icons.person, size: 40, color: textLight) 
                      : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: borderGrey, width: 1)),
                        child: const Icon(Icons.camera_alt, color: primaryBlue, size: 16),
                      ),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 32),

            Container(
              decoration: BoxDecoration(
                border: Border.all(color: borderGrey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  _modernProfileRow("Full Name", currentUser?['full_name'] ?? "Unknown"),
                  const Divider(height: 1, thickness: 1, color: borderGrey),
                  _modernProfileRow("Email", currentUser?['email'] ?? "Unknown"),
                  const Divider(height: 1, thickness: 1, color: borderGrey),
                  _modernProfileRow("Department", currentUser?['department'] ?? "Unknown"),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border.all(color: borderGrey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Trust Rating", style: TextStyle(color: textDark, fontWeight: FontWeight.bold, fontSize: 14)),
                  Row(children: stars),
                ],
              ),
            ),
            const SizedBox(height: 40),

            OutlinedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const PasswordResetScreen())),
              style: OutlinedButton.styleFrom(
                foregroundColor: textDark,
                side: const BorderSide(color: borderGrey),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text("Change Password", style: TextStyle(fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _logout,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red.shade600,
                      minimumSize: const Size(0, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text("Sign Out", style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: const Size(0, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: _isLoading 
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: accentYellow, strokeWidth: 2)) 
                      : const Text("Save Changes", style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40)
          ],
        ),
      ),
    );
  }

  Widget _modernProfileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(fontSize: 13, color: textLight, fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 14, color: textDark, fontWeight: FontWeight.w600), textAlign: TextAlign.right),
          )
        ],
      ),
    );
  }
}

// ==================== PASSWORD RESET SCREEN ====================
class PasswordResetScreen extends StatefulWidget {
  const PasswordResetScreen({super.key});
  @override
  State<PasswordResetScreen> createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends State<PasswordResetScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confCtrl = TextEditingController();
  bool _isLoading = false;

  Future<void> doReset() async {
    if (_emailCtrl.text.isEmpty || _passCtrl.text.isEmpty) {
      showErrorToast(context, "Please fill in all fields.");
      return;
    }
    if (_passCtrl.text != _confCtrl.text) {
      showErrorToast(context, "New passwords do not match.");
      return;
    }
    setState(() => _isLoading = true);
    try {
      var res = await http.post(
        Uri.parse('https://huramay-app.onrender.com/api/user/reset_password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': _emailCtrl.text, 'new_password': _passCtrl.text, 'current_user_id': currentUser!['id']}),
      );
      if (!mounted) return;
      if (res.statusCode == 200) {
        showSuccessToast(context, "Password updated successfully.");
        Navigator.pop(context);
      } else {
        var data = jsonDecode(res.body);
        showErrorToast(context, data['message'] ?? "Failed to reset password.");
      }
    } catch (e) {
      showErrorToast(context, "Connection error.");
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
        elevation: 0,
        iconTheme: const IconThemeData(color: textDark),
        title: const Text("Security", style: TextStyle(color: textDark, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(color: borderGrey, height: 1)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text("Update Password", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: textDark, letterSpacing: -0.5)),
            const SizedBox(height: 8),
            const Text("Ensure your account is using a secure password.", style: TextStyle(fontSize: 14, color: textLight)),
            const SizedBox(height: 40),
            
            const Text("Email Address", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textDark)),
            const SizedBox(height: 8),
            TextField(controller: _emailCtrl, decoration: modernInputDecoration("Enter registered email")),
            const SizedBox(height: 20),
            
            const Text("New Password", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textDark)),
            const SizedBox(height: 8),
            TextField(controller: _passCtrl, obscureText: true, decoration: modernInputDecoration("••••••••")),
            const SizedBox(height: 20),
            
            const Text("Confirm Password", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textDark)),
            const SizedBox(height: 8),
            TextField(controller: _confCtrl, obscureText: true, decoration: modernInputDecoration("••••••••")),
            const SizedBox(height: 40),
            
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : doReset,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _isLoading 
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: accentYellow, strokeWidth: 2)) 
                  : const Text("Save Password", style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            )
          ],
        ),
      ),
    );
  }
}

// ==================== NEW UNIVERSAL RECOVERY SCREEN ====================
class UniversalRecoveryScreen extends StatefulWidget {
  const UniversalRecoveryScreen({super.key});
  @override
  State<UniversalRecoveryScreen> createState() => _UniversalRecoveryScreenState();
}

class _UniversalRecoveryScreenState extends State<UniversalRecoveryScreen> {
  final _emailCtrl = TextEditingController();
  final _colorCtrl = TextEditingController();
  final _songCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confPassCtrl = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePass = true;

  Future<void> _submitRecovery() async {
    if (_emailCtrl.text.isEmpty || _colorCtrl.text.isEmpty || _songCtrl.text.isEmpty || _newPassCtrl.text.isEmpty) {
      showErrorToast(context, "Please fill in all fields to recover your account.");
      return;
    }
    if (_newPassCtrl.text != _confPassCtrl.text) {
      showErrorToast(context, "Passwords do not match.");
      return;
    }

    setState(() => _isLoading = true);
    try {
      var res = await http.post(
        Uri.parse('https://huramay-app.onrender.com/api/user/recover_account'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailCtrl.text.trim(),
          'security_color': _colorCtrl.text.trim(),
          'security_song': _songCtrl.text.trim(),
          'new_password': _newPassCtrl.text
        }),
      );
      var data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        if (mounted) {
          showSuccessToast(context, data['message']);
          Navigator.pop(context); // Send them back to the login screen
        }
      } else {
        if (mounted) showErrorToast(context, data['message']); // E.g., "Security answers incorrect"
      }
    } catch (e) {
      if (mounted) showErrorToast(context, "Connection Error.");
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
        elevation: 0,
        iconTheme: const IconThemeData(color: textDark),
        title: const Text("Account Recovery", style: TextStyle(color: textDark, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.lock_reset, size: 64, color: primaryBlue),
            const SizedBox(height: 24),
            const Text("Recover Password", textAlign: TextAlign.center, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: textDark, letterSpacing: -0.5)),
            const SizedBox(height: 8),
            const Text("Answer your security questions to set a new password.", textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: textLight)),
            const SizedBox(height: 40),

            // EMAIL
            const Text("Email Address", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textDark)),
            const SizedBox(height: 8),
            TextField(
              controller: _emailCtrl,
              decoration: modernInputDecoration("your.email@gmail.com"),
            ),
            const SizedBox(height: 24),

            // SECURITY QUESTIONS
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: bgGray, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderGrey)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Security Verification", style: TextStyle(fontWeight: FontWeight.bold, color: primaryBlue)),
                  const SizedBox(height: 16),
                  const Text("What is your favorite color?", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textDark)),
                  const SizedBox(height: 8),
                  TextField(controller: _colorCtrl, decoration: modernInputDecoration("Enter your answer")),
                  const SizedBox(height: 16),
                  const Text("What is your favorite song?", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textDark)),
                  const SizedBox(height: 8),
                  TextField(controller: _songCtrl, decoration: modernInputDecoration("Enter your answer")),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // NEW PASSWORD
            const Text("New Password", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textDark)),
            const SizedBox(height: 8),
            TextField(
              controller: _newPassCtrl,
              obscureText: _obscurePass,
              decoration: modernInputDecoration("••••••••", suffixIcon: IconButton(
                icon: Icon(_obscurePass ? Icons.visibility_off : Icons.visibility, color: textLight, size: 20),
                onPressed: () => setState(() => _obscurePass = !_obscurePass),
              )),
            ),
            const SizedBox(height: 16),
            const Text("Confirm New Password", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textDark)),
            const SizedBox(height: 8),
            TextField(
              controller: _confPassCtrl,
              obscureText: _obscurePass,
              decoration: modernInputDecoration("••••••••"),
            ),
            const SizedBox(height: 32),

            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitRecovery,
                style: ElevatedButton.styleFrom(backgroundColor: primaryBlue, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: accentYellow)
                  : const Text("Recover Account", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
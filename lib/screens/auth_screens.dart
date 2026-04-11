// lib/screens/auth_screens.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

import '../globals.dart';
import '../utils/ui_helpers.dart';
import 'dashboard_screen.dart';
import 'admin_dashboard.dart'; 

// ==================== AUTH & PROFILE SCREENS ====================
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  
  // NEW: Added FormKey and visibility boolean
  final _formKey = GlobalKey<FormState>();
  bool _obscurePass = true;

  Future<void> doLogin() async {
    // NEW: Trigger validators before making the HTTP request
    if (!_formKey.currentState!.validate()) return;

    try {
      var res = await http.post(
        Uri.parse('https://huramay-app.onrender.com/api/login'), 
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': _emailCtrl.text, 'password': _passCtrl.text}),
      );
      
      if (!mounted) return; // FIX: Prevent BuildContext across async gaps warning

      var data = jsonDecode(res.body);
      
      if (res.statusCode == 200) {
        currentUser = data;
        bool isAdmin = data['is_admin'] ?? false;

        if (isAdmin) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const AdminDashboard()));
        } else {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const DashboardScreen()));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'])));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Connection Error")));
    }
  }

  // NEW: Helper method to support validators and the eye icon
  Widget _buildValidatedInput(TextEditingController ctrl, {bool isPass = false, String? Function(String?)? validator}) {
    return TextFormField(
      controller: ctrl,
      obscureText: isPass ? _obscurePass : false,
      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        errorStyle: const TextStyle(color: Color.fromARGB(255, 255, 0, 0), fontWeight: FontWeight.bold, fontSize: 13),
        suffixIcon: isPass ? IconButton(
          icon: Icon(_obscurePass ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
          onPressed: () => setState(() => _obscurePass = !_obscurePass),
        ) : null,
      ),
      validator: validator,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: figmaBackground(),
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Form( // NEW: Wrapped in Form
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Huramay", style: TextStyle(fontSize: 45, color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 40),
                const Text("Login", style: TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 30),
                
                figmaLabel("Email"),
                _buildValidatedInput(_emailCtrl, validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter your email';
                  return null;
                }),
                
                const SizedBox(height: 10),
                
                figmaLabel("Password"),
                _buildValidatedInput(_passCtrl, isPass: true, validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter your password';
                  return null;
                }),
                
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account? ", style: TextStyle(color: Colors.white)),
                    GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const SignUpScreen())),
                      child: const Text("SignUp", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
                const SizedBox(height: 40),
                figmaButton("Login", doLogin),
              ],
            ),
          ),
        ),
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
  String? _selectedDept;
  
  // NEW: Added FormKey and visibility booleans
  final _formKey = GlobalKey<FormState>();
  bool _obscurePass = true;
  bool _obscureConf = true;

  final List<String> _lnuDepartments = [
    'Bachelor of Elementary Education', 'Bachelor of Early Childhood Education', 'Bachelor of Special Needs Education', 'Bachelor of Technology and Livelihood Education', 'Bachelor of Physical Education', 'Bachelor of Secondary Education major in English', 'Bachelor of Secondary Education major in Filipino', 'Bachelor of Secondary Education major in Mathematics', 'Bachelor of Secondary Education major in Science', 'Bachelor of Secondary Education major in Social Studies', 'Bachelor of Secondary Education major in Values Education', 'Teacher Certificate Program (TCP)', 'Bachelor of Library and Information Science', 'Bachelor of Arts in Communication', 'Bachelor of Music in Music Education', 'Bachelor of Science in Information Technology', 'Bachelor of Arts in English Language', 'Bachelor of Arts in Political Science', 'Bachelor of Science in Biology', 'Bachelor of Science in Social Work', 'Bachelor of Science in Tourism Management', 'Bachelor of Science in Hospitality Management', 'Bachelor of Science in Entrepreneurship', 'Faculty / Staff'
  ];

  Future<void> doSignup() async {
    // NEW: Trigger validators (Regex for emojis, special chars, matching passwords)
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDept == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a department")));
      return;
    }
    
    String emailInput = _emailCtrl.text.trim().toLowerCase();
    
    try {
      var res = await http.post(
        Uri.parse('https://huramay-app.onrender.com/api/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'full_name': _nameCtrl.text, 'email': emailInput, 'department': _selectedDept, 'password': _passCtrl.text}),
      );
      
      if (!mounted) return; // FIX: Prevent BuildContext across async gaps warning

      if (res.statusCode == 201) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Account created! Please log in.")));
      } else {
        var data = jsonDecode(res.body);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'])));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Connection Error")));
    }
  }

  // NEW: Helper method to support validators and the eye icon
  Widget _buildValidatedInput(TextEditingController ctrl, {bool isPass = false, bool? obscure, VoidCallback? onToggle, String? Function(String?)? validator}) {
    return TextFormField(
      controller: ctrl,
      obscureText: obscure ?? false,
      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        suffixIcon: isPass ? IconButton(
          icon: Icon(obscure! ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
          onPressed: onToggle,
        ) : null,
      ),
      validator: validator,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: figmaBackground(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(40),
          child: Form( // NEW: Wrapped in Form
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 60),
                const Center(child: Text("Huramay", style: TextStyle(fontSize: 45, color: Colors.white, fontWeight: FontWeight.bold))),
                const SizedBox(height: 10),
                const Center(child: Text("SignUp", style: TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold))),
                const SizedBox(height: 30),
                
                // NAME VALIDATION
                figmaLabel("Full Name"),
                _buildValidatedInput(_nameCtrl, validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter your name';
                  if (!RegExp(r'^[a-zA-Z\s\.]+$').hasMatch(value)) return 'No numbers, special characters, or emoji';
                  return null;
                }),
                const SizedBox(height: 10),

                // EMAIL VALIDATION
                figmaLabel("Email"),
                _buildValidatedInput(_emailCtrl, validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter your email';
                  bool hasEmoji = RegExp(r'[\u00A9\u00AE\u2000-\u3300\ud83c\ud000-\ud83c\udfff\ud83d\ud000-\ud83d\udfff\ud83e\ud000-\ud83e\udfff]').hasMatch(value);
                  bool hasSpecialChars = value.contains(RegExp(r'[!#\$%^&*() \?":{}|<>]'));
                  if (hasEmoji || hasSpecialChars) return 'No special characters other @ or emoji allowed';
                  if (!value.toLowerCase().endsWith('@gmail.com')) return 'Email must end with @gmail.com';
                  return null;
                }),
                const SizedBox(height: 10),

                // DEPARTMENT
                figmaLabel("Department"),
                Container(
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 3),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: _selectedDept,
                      hint: const Text("Select program", style: TextStyle(fontSize: 14, color: Colors.black54)),
                      items: _lnuDepartments.map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontSize: 12, color: Colors.black, fontWeight: FontWeight.bold)))).toList(),
                      onChanged: (v) => setState(() => _selectedDept = v),
                      decoration: const InputDecoration(border: InputBorder.none),
                      validator: (value) => value == null ? 'Please select a department' : null,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // PASSWORD VALIDATION + EYE ICON
                figmaLabel("Password"),
                _buildValidatedInput(_passCtrl, isPass: true, obscure: _obscurePass, onToggle: () => setState(() => _obscurePass = !_obscurePass), validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter a password';
                  if (RegExp(r'[\u00A9\u00AE\u2000-\u3300\ud83c\ud000-\ud83c\udfff\ud83d\ud000-\ud83d\udfff\ud83e\ud000-\ud83e\udfff]').hasMatch(value)) return 'Password cannot contain emojis';
                  return null;
                }),
                const SizedBox(height: 10),

                // CONFIRM PASSWORD VALIDATION + EYE ICON
                figmaLabel("Confirm Password"),
                _buildValidatedInput(_confCtrl, isPass: true, obscure: _obscureConf, onToggle: () => setState(() => _obscureConf = !_obscureConf), validator: (value) {
                  if (value == null || value.isEmpty) return 'Please confirm your password';
                  if (value != _passCtrl.text) return 'Passwords do not match';
                  return null;
                }),
                
                const SizedBox(height: 40),
                Center(child: figmaButton("SignUp", doSignup)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==================== PROFILE SCREEN (Modernized) ====================
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _localPhotoPath;

  @override
  void initState() {
    super.initState();
    _localPhotoPath = currentUser?['photo_path'];
    if (_localPhotoPath != null && _localPhotoPath!.isEmpty) _localPhotoPath = null;
  }

  Future<void> _pickImage() async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (image != null) setState(() => _localPhotoPath = image.path);
  }

  Future<void> _saveProfile() async {
    try {
      var res = await http.post(
        Uri.parse('https://huramay-app.onrender.com/api/user/update'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id': currentUser!['id'], 'photo_path': _localPhotoPath ?? ""}),
      );
      if (res.statusCode == 200) {
        currentUser!['photo_path'] = _localPhotoPath;
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile Saved!")));
      }
    } catch (e) {}
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
      color: Colors.amber, 
      size: 28
    ));
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A0088),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text("My Profile", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF1A0088), width: 3),
                      image: _localPhotoPath != null 
                        ? DecorationImage(image: FileImage(File(_localPhotoPath!)), fit: BoxFit.cover) 
                        : null,
                    ),
                    child: _localPhotoPath == null ? const Icon(Icons.person, size: 65, color: Colors.grey) : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 5,
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.yellow,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2)
                        ),
                        child: const Icon(Icons.camera_alt, color: Colors.black, size: 22),
                      ),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 35),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.black12),
              ),
              child: Column(
                children: [
                  _modernProfileRow("Full Name", currentUser?['full_name'] ?? "Unknown", Icons.person_outline),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1, thickness: 1, color: Colors.black12),
                  ),
                  _modernProfileRow("Email", currentUser?['email'] ?? "Unknown", Icons.email_outlined),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1, thickness: 1, color: Colors.black12),
                  ),
                  _modernProfileRow("Department", currentUser?['department'] ?? "Unknown", Icons.business_outlined),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Trust Rating", style: TextStyle(color: Color(0xFF1A0088), fontWeight: FontWeight.bold, fontSize: 16)),
                  Row(children: stars),
                ],
              ),
            ),
            const SizedBox(height: 35),

            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (c) => const PasswordResetScreen()));
              },
              icon: const Icon(Icons.lock_reset),
              label: const Text("Reset Password", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A0088),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 0,
              ),
            ),
            const SizedBox(height: 15),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout, size: 20),
                    label: const Text("Logout", style: TextStyle(fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red, width: 1.5),
                      minimumSize: const Size(0, 55),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _saveProfile,
                    icon: const Icon(Icons.save, size: 20),
                    label: const Text("Save", style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.yellow,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      minimumSize: const Size(0, 55),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30)
          ],
        ),
      ),
    );
  }

  Widget _modernProfileRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: Colors.black12)),
          child: Icon(icon, color: const Color(0xFF1A0088), size: 20),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.bold)),
              const SizedBox(height: 3),
              Text(value, style: const TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.bold)),
            ],
          ),
        )
      ],
    );
  }
}

// ==================== PASSWORD RESET SCREEN (Modernized) ====================
class PasswordResetScreen extends StatefulWidget {
  const PasswordResetScreen({super.key});
  @override
  State<PasswordResetScreen> createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends State<PasswordResetScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confCtrl = TextEditingController();

  Future<void> doReset() async {
    if (_emailCtrl.text.isEmpty || _passCtrl.text.isEmpty || _passCtrl.text != _confCtrl.text) return;
    try {
      var res = await http.post(
        Uri.parse('https://huramay-app.onrender.com/api/user/reset_password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': _emailCtrl.text, 'new_password': _passCtrl.text, 'current_user_id': currentUser!['id']}),
      );
      if (!mounted) return;
      if (res.statusCode == 200) Navigator.pop(context);
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A0088),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text("Reset Password", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Security Settings", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A0088))),
            const SizedBox(height: 30),
            
            _modernResetLabel("Email Address"),
            _modernResetInput(_emailCtrl),
            const SizedBox(height: 15),
            
            _modernResetLabel("New Password"),
            _modernResetInput(_passCtrl, isPass: true),
            const SizedBox(height: 15),
            
            _modernResetLabel("Confirm Password"),
            _modernResetInput(_confCtrl, isPass: true),
            const SizedBox(height: 40),
            
            ElevatedButton(
              onPressed: doReset,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.yellow,
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 0,
              ),
              child: const Text("Update Password", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            )
          ],
        ),
      ),
    );
  }

  Widget _modernResetLabel(String text) => Padding(
    padding: const EdgeInsets.only(left: 5, bottom: 8),
    child: Text(text, style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.bold)),
  );

  Widget _modernResetInput(TextEditingController ctrl, {bool isPass = false}) => TextField(
    controller: ctrl,
    obscureText: isPass,
    style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 14),
    decoration: InputDecoration(
      filled: true,
      fillColor: const Color(0xFFF3F4F6),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.black12)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.black12)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFF1A0088), width: 1.5)),
    ),
  );
}
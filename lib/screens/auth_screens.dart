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

  Future<void> doLogin() async {
    try {
      var res = await http.post(
        Uri.parse('http://10.174.134.39:5000/api/login'), 
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': _emailCtrl.text, 'password': _passCtrl.text}),
      );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: figmaBackground(),
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Huramay", style: TextStyle(fontSize: 45, color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 40),
              const Text("Login", style: TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),
              figmaLabel("Email"),
              figmaInputAuth(_emailCtrl),
              figmaLabel("Password"),
              figmaInputAuth(_passCtrl, isPass: true),
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
  
  final List<String> _lnuDepartments = [
    'Bachelor of Elementary Education', 'Bachelor of Early Childhood Education', 'Bachelor of Special Needs Education', 'Bachelor of Technology and Livelihood Education', 'Bachelor of Physical Education', 'Bachelor of Secondary Education major in English', 'Bachelor of Secondary Education major in Filipino', 'Bachelor of Secondary Education major in Mathematics', 'Bachelor of Secondary Education major in Science', 'Bachelor of Secondary Education major in Social Studies', 'Bachelor of Secondary Education major in Values Education', 'Teacher Certificate Program (TCP)', 'Bachelor of Library and Information Science', 'Bachelor of Arts in Communication', 'Bachelor of Music in Music Education', 'Bachelor of Science in Information Technology', 'Bachelor of Arts in English Language', 'Bachelor of Arts in Political Science', 'Bachelor of Science in Biology', 'Bachelor of Science in Social Work', 'Bachelor of Science in Tourism Management', 'Bachelor of Science in Hospitality Management', 'Bachelor of Science in Entrepreneurship', 'Faculty / Staff'
  ];

  Future<void> doSignup() async {
    // TICKET VAVT-64: Enforce @gmail.com extension
    String emailInput = _emailCtrl.text.trim().toLowerCase();
    if (!emailInput.endsWith('@gmail.com')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Not an email address extension.")),
      );
      return; // Stop the signup process right here
    }

    if (_selectedDept == null || _passCtrl.text != _confCtrl.text) return;
    
    try {
      var res = await http.post(
        Uri.parse('http://10.174.134.39:5000/api/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'full_name': _nameCtrl.text, 'email': emailInput, 'department': _selectedDept, 'password': _passCtrl.text}),
      );
      
      if (res.statusCode == 201) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Account created! Please log in.")));
      } else {
        // PRO FIX: Actually show the user why it failed (e.g. Email already exists)
        var data = jsonDecode(res.body);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'])));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Connection Error")));
    }
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
          child: Column(
            children: [
              const SizedBox(height: 60),
              const Text("Huramay", style: TextStyle(fontSize: 45, color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              const Text("SignUp", style: TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),
              figmaLabel("Full Name"),
              figmaInputAuth(_nameCtrl),
              figmaLabel("Email"),
              figmaInputAuth(_emailCtrl),
              figmaLabel("Department"),
              Container(
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: DropdownButtonHideUnderline(
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: _selectedDept,
                    hint: const Text("Select program", style: TextStyle(fontSize: 12)),
                    items: _lnuDepartments.map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontSize: 12)))).toList(),
                    onChanged: (v) => setState(() => _selectedDept = v),
                    decoration: const InputDecoration(border: InputBorder.none),
                  ),
                ),
              ),
              _passInputWithLabel("Password", _passCtrl),
              _passInputWithLabel("Confirm Password", _confCtrl),
              const SizedBox(height: 40),
              figmaButton("SignUp", doSignup),
            ],
          ),
        ),
      ),
    );
  }

  Widget _passInputWithLabel(String label, TextEditingController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start, 
      children: [
        figmaLabel(label), 
        figmaInputAuth(ctrl, isPass: true)
      ],
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
        Uri.parse('http://10.174.134.39:5000/api/user/update'), // FIXED: Using $baseUrl
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id': currentUser!['id'], 'photo_path': _localPhotoPath ?? ""}),
      );
      if (res.statusCode == 200) {
        currentUser!['photo_path'] = _localPhotoPath;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile Saved!")));
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
      backgroundColor: Colors.white, // Clean white background
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
            // 1. Modern Interactive Avatar
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

            // 2. User Information Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6), // Matches the dashboard grey
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

            // 3. Trust Rating Highlight Box
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

            // 4. Action Buttons
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
        Uri.parse('http://10.174.134.39:5000/api/user/reset_password'), // FIXED: Using $baseUrl
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': _emailCtrl.text, 'new_password': _passCtrl.text, 'current_user_id': currentUser!['id']}),
      );
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
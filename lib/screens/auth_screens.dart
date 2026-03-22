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
        Uri.parse('http://10.33.87.39:5000/api/login'), 
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
        Uri.parse('http://10.33.87.39:5000/api/register'),
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
        Uri.parse('http://10.33.87.39:5000/api/user/update'),
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
    List<Widget> stars = List.generate(5, (index) => Icon(index < rating ? Icons.star : Icons.star_border, color: Colors.yellow, size: 30));
    
    return Scaffold(
      backgroundColor: const Color(0xFF1A0088),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: const BoxDecoration(color: Colors.yellow, shape: BoxShape.circle),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20), 
              onPressed: () => Navigator.pop(context)
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center, 
            children: [
              const Text("Huramay", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 20),
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.white,
                backgroundImage: _localPhotoPath != null ? FileImage(File(_localPhotoPath!)) : null,
                child: _localPhotoPath == null ? const Icon(Icons.person, size: 50, color: Colors.grey) : null,
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _pickImage,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.yellow, foregroundColor: Colors.black),
                child: const Text("Photo Upload", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 30),
              _profileField("Name", currentUser?['full_name'] ?? "Unknown"),
              _profileField("Email", currentUser?['email'] ?? "Unknown"),
              _profileField("Department", currentUser?['department'] ?? "Unknown"),
              const SizedBox(height: 20),
              const Text("Rating", style: TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold, fontSize: 16)),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: stars),
              const SizedBox(height: 30),
              TextButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (c) => const PasswordResetScreen()));
                },
                child: const Text("Password Reset", style: TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveProfile,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.yellow, foregroundColor: Colors.black, minimumSize: const Size(120, 45)),
                child: const Text("Save", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 15),
              ElevatedButton(
                onPressed: _logout,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.yellow, foregroundColor: Colors.black, minimumSize: const Size(120, 45)),
                child: const Text("Logout", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 40)
            ],
          ),
        ),
      ),
    );
  }

  Widget _profileField(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold, fontSize: 16)),
        Text(value, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    ),
  );
}

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
        Uri.parse('http://10.33.87.39:5000/api/user/reset_password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': _emailCtrl.text, 'new_password': _passCtrl.text, 'current_user_id': currentUser!['id']}),
      );
      if (res.statusCode == 200) Navigator.pop(context);
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A0088),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: const BoxDecoration(color: Colors.yellow, shape: BoxShape.circle),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20), 
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            const Text("Huramay", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 50),
            _whiteResetLabel("Email"),
            _yellowResetInput(_emailCtrl),
            _whiteResetLabel("Password"),
            _yellowResetInput(_passCtrl, isPass: true),
            _whiteResetLabel("Confirm Password"),
            _yellowResetInput(_confCtrl, isPass: true),
            const SizedBox(height: 50),
            ElevatedButton(
              onPressed: doReset,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.yellow,
                foregroundColor: Colors.black,
                minimumSize: const Size(120, 45),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
              ),
              child: const Text("Reset", style: TextStyle(fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }

  Widget _whiteResetLabel(String text) => Padding(
    padding: const EdgeInsets.only(left: 10, bottom: 5, top: 15),
    child: Align(
      alignment: Alignment.centerLeft, 
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
    ),
  );

  Widget _yellowResetInput(TextEditingController ctrl, {bool isPass = false}) => TextField(
    controller: ctrl,
    obscureText: isPass,
    style: const TextStyle(color: Colors.black),
    decoration: InputDecoration(
      filled: true,
      fillColor: Colors.yellow,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
    ),
  );
}
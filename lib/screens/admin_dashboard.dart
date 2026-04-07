// lib/screens/admin_dashboard.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

import '../globals.dart';
import 'auth_screens.dart'; // Needed for LoginScreen routing

// =========================================================================
// 1. ADMIN DASHBOARD
// =========================================================================
class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  List<dynamic> allItems = [];
  bool isLoading = true;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchAllItems();
  }

  Future<void> _fetchAllItems() async {
    setState(() => isLoading = true);
    try {
      // FIXED: Swapped hardcoded IP for $baseUrl
      String url = 'http://10.174.134.39:5000/api/items';
      String searchQuery = _searchCtrl.text.trim();
      if (searchQuery.isNotEmpty) {
        url += '?search=${Uri.encodeComponent(searchQuery)}';
      }

      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        setState(() {
          allItems = jsonDecode(res.body);
        });
      }
    } catch (e) {
      debugPrint("Admin fetch error: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _executeDelete(int itemId) async {
    try {
      final res = await http.delete(Uri.parse('http://10.174.134.39:5000/api/items/$itemId'));
      if (res.statusCode == 200) {
        _fetchAllItems();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Item Deleted permanently.")));
      }
    } catch (e) {
      debugPrint("Delete error: $e");
    }
  }

  Future<void> _executeBan(int userId) async {
    try {
      final res = await http.delete(Uri.parse('http://10.174.134.39:5000/api/users/$userId'));
      if (res.statusCode == 200) {
        _fetchAllItems();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("User Banned permanently.")));
      }
    } catch (e) {
      debugPrint("Ban error: $e");
    }
  }

  void _showConfirmation(String title, String content, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A0088))),
        content: Text(content),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF1A0088),
              side: const BorderSide(color: Color(0xFF1A0088), width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text("Cancel", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text("Confirm", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _openAdminReportModal(dynamic item) {
    showDialog(
      context: context,
      builder: (ctx) => AdminReportOverlay(
        itemData: item,
        onReportSubmitted: () {
          _fetchAllItems(); 
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A0088),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Container(
          height: 35,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (value) => _fetchAllItems(),
            decoration: const InputDecoration(
              hintText: "Search items...",
              prefixIcon: Icon(Icons.search, color: Colors.grey),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (c) => const AdminProfileScreen())
              );
            },
            icon: const Icon(Icons.account_circle, size: 30),
          )
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              "Admin Dashboard",
              style: TextStyle(
                fontSize: 28, 
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A0088),
              ),
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : allItems.isEmpty
                    ? const Center(child: Text("No items found.", style: TextStyle(color: Colors.grey, fontSize: 18)))
                    : ListView.builder(
                        itemCount: allItems.length,
                        itemBuilder: (context, index) => _buildAdminCard(allItems[index]),
                      ),
          ),
        ],
      ),
    );
  }

  // =======================================================================
  // UPDATED: Modern UI Match for the Admin Card
  // =======================================================================
  Widget _buildAdminCard(dynamic item) {
    String? imgPath = item['image'];
    bool hasImage = imgPath != null && imgPath.isNotEmpty;
    bool isFlagged = item['status']?.toString().toLowerCase() == 'flagged';

    return GestureDetector(
      onTap: () => _openAdminReportModal(item), 
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6), // Matches the modern dashboard grey
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.black12, width: 1),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left side: The White Image Box with Blue Border
              Container(
                width: 85,
                height: 85,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isFlagged ? Colors.red : const Color(0xFF1A0088), width: 1.5),
                  image: hasImage ? DecorationImage(image: FileImage(File(imgPath!)), fit: BoxFit.cover) : null,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (!hasImage) const Icon(Icons.image, size: 30, color: Colors.grey),
                    if (isFlagged)
                      Container(
                        width: double.infinity,
                        height: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.do_not_disturb_alt, size: 45, color: Colors.red),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 15),
              // Right side: Details & Buttons
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row 1: Name & Status Pill
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item['owner'],
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A0088), fontSize: 13),
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 5),
                        // Modern Status Pill (Green for Available, Red for Flagged)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isFlagged ? Colors.red.shade50 : Colors.green.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isFlagged ? Colors.red : Colors.green, width: 1),
                          ),
                          child: Text(
                            item['status'],
                            style: TextStyle(
                              color: isFlagged ? Colors.red : Colors.green, 
                              fontWeight: FontWeight.bold, 
                              fontSize: 10
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Row 2: Title
                    Text(
                      item['title'],
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    // Row 3: Department
                    Text(
                      item['dept'],
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 12),
                    // Row 4: Buttons docked to the bottom right
                    if (isFlagged)
                      Align(
                        alignment: Alignment.centerRight,
                        child: _adminBtn("Delete Flagged Item", Colors.red, () {
                          _showConfirmation("Delete Flagged Item", "Are you sure you want to permanently delete '${item['title']}'?", () => _executeDelete(item['id']));
                        }, textColor: Colors.white),
                      )
                    else
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          _adminBtn("Review", Colors.yellow, () {
                            _openAdminReportModal(item);
                          }),
                          const SizedBox(width: 10),
                          _adminBtn("Delete", Colors.yellow, () {
                            _showConfirmation("Delete Item", "Are you sure you want to permanently delete '${item['title']}' from the feed?", () => _executeDelete(item['id']));
                          }),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _adminBtn(String text, Color color, VoidCallback action, {Color textColor = Colors.black}) {
    return GestureDetector(
      onTap: action,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(15), // Softer pill shape
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 2, offset: const Offset(0, 2))]
        ),
        child: Text(
          text,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textColor),
        ),
      ),
    );
  }
}

// =========================================================================
// 2. THE ADMIN REPORT OVERLAY DIALOG 
// =========================================================================
class AdminReportOverlay extends StatefulWidget {
  final dynamic itemData;
  final VoidCallback onReportSubmitted;

  const AdminReportOverlay({super.key, required this.itemData, required this.onReportSubmitted});

  @override
  State<AdminReportOverlay> createState() => _AdminReportOverlayState();
}

class _AdminReportOverlayState extends State<AdminReportOverlay> {
  final TextEditingController _reportTextCtrl = TextEditingController();
  bool isSubmitting = false;

  void _handleReport() {
    if (_reportTextCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please type a report details first.")));
      return;
    }
    _showConfirmation(); 
  }

  void _showConfirmation() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Are you sure you want to report?",
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF1A0088), fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 25),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1A0088),
                    side: const BorderSide(color: Color(0xFF1A0088), width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    minimumSize: const Size(90, 40),
                  ),
                  child: const Text("No", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); 
                    _submitReportToBackend(); 
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.yellow,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    minimumSize: const Size(90, 40),
                    elevation: 0,
                  ),
                  child: const Text("Yes", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Future<void> _submitReportToBackend() async {
    setState(() => isSubmitting = true);
    try {
      final res = await http.post(
        Uri.parse('http://10.174.134.39:5000/api/report'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'reporter_id': currentUser!['id'], 
          'item_id': widget.itemData['id'],
          'report_text': _reportTextCtrl.text.trim()
        }),
      );
      if (res.statusCode == 201) {
        if(mounted) Navigator.pop(context); 
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Report submitted successfully.")));
        widget.onReportSubmitted(); 
      }
    } catch (e) {
      debugPrint("Report Submission Error: $e");
    } finally {
      if(mounted) setState(() => isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    String? imgPath = widget.itemData['image'];
    bool hasImage = imgPath != null && imgPath.isNotEmpty;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 0.65, 
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5))],
        ),
        child: Column(
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle),
                  child: const Icon(Icons.close, size: 18, color: Color(0xFF1A0088)),
                ),
              ),
            ),
            Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: const Color(0xFF1A0088), width: 3),
                image: hasImage ? DecorationImage(image: FileImage(File(imgPath)), fit: BoxFit.cover) : null,
              ),
              child: !hasImage ? const Icon(Icons.image, size: 50, color: Colors.grey) : null,
            ),
            const SizedBox(height: 20),
            const Text("Type here your report", style: TextStyle(color: Color(0xFF1A0088), fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6), 
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.black12)
                ),
                child: TextField(
                  controller: _reportTextCtrl,
                  maxLines: null, 
                  keyboardType: TextInputType.multiline,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(15),
                    hintText: "Enter formal flag reason or note...",
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            isSubmitting 
              ? const CircularProgressIndicator()
              : ElevatedButton(
                  onPressed: _handleReport, 
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                    padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 12),
                    elevation: 0,
                  ),
                  child: const Text("Report", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                )
          ],
        ),
      ),
    );
  }
}

// =========================================================================
// 3. ADMIN PROFILE SCREEN
// =========================================================================
class AdminProfileScreen extends StatelessWidget {
  const AdminProfileScreen({super.key});

  void _logout(BuildContext context) {
    currentUser = null;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (c) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A0088),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text("Admin Profile", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.yellow, width: 3),
              ),
              child: const CircleAvatar(
                radius: 60,
                backgroundColor: Color(0xFF1A0088),
                child: Icon(Icons.admin_panel_settings, size: 70, color: Colors.white),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              currentUser?['full_name'] ?? "System Administrator",
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1A0088)),
            ),
            const SizedBox(height: 8),
            Text(
              currentUser?['email'] ?? "admin@gmail.com",
              style: const TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 40),
            
            OutlinedButton.icon(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (c) => const AdminManagementScreen()));
              },
              icon: const Icon(Icons.manage_accounts),
              label: const Text("Manage Admins", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1A0088),
                side: const BorderSide(color: Color(0xFF1A0088), width: 2),
                minimumSize: const Size(200, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
              ),
            ),
            
            const SizedBox(height: 15),

            ElevatedButton.icon(
              onPressed: () => _logout(context),
              icon: const Icon(Icons.logout, color: Colors.black),
              label: const Text("Logout", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.yellow,
                minimumSize: const Size(200, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =========================================================================
// 4. ADMIN MANAGEMENT SCREEN 
// =========================================================================
class AdminManagementScreen extends StatefulWidget {
  const AdminManagementScreen({super.key});

  @override
  State<AdminManagementScreen> createState() => _AdminManagementScreenState();
}

class _AdminManagementScreenState extends State<AdminManagementScreen> {
  List<dynamic> adminList = [];
  bool isLoading = true;

  final String superAdminEmail = "admin@gmail.com"; 

  @override
  void initState() {
    super.initState();
    _fetchAdmins();
  }

  Future<void> _fetchAdmins() async {
    setState(() => isLoading = true);
    try {
      final res = await http.get(Uri.parse('http://10.174.134.39:5000/api/admins'));
      if (res.statusCode == 200) {
        setState(() => adminList = jsonDecode(res.body));
      }
    } catch (e) {
      debugPrint("Fetch admins error: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _deleteAdmin(int id, String email) async {
    if (email == superAdminEmail) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Action Denied: Cannot delete the Super Admin.")));
      return;
    }

    try {
      final res = await http.delete(Uri.parse('http://10.174.134.39:5000/api/admins/$id'));
      if (res.statusCode == 200) {
        _fetchAdmins();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Admin account deleted.")));
      }
    } catch (e) {
      debugPrint("Delete admin error: $e");
    }
  }

  void _showAddAdminModal() {
    final _nameCtrl = TextEditingController();
    final _emailCtrl = TextEditingController();
    final _passCtrl = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            title: const Text("Create New Admin", style: TextStyle(color: Color(0xFF1A0088), fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _nameCtrl,
                    decoration: InputDecoration(labelText: "Full Name", filled: true, fillColor: Colors.grey.shade100, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _emailCtrl,
                    decoration: InputDecoration(labelText: "Email (@gmail.com)", filled: true, fillColor: Colors.grey.shade100, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _passCtrl,
                    obscureText: true,
                    decoration: InputDecoration(labelText: "Password", filled: true, fillColor: Colors.grey.shade100, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)),
                  ),
                ],
              ),
            ),
            actions: [
              OutlinedButton(
                onPressed: () => Navigator.pop(ctx),
                style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF1A0088), side: const BorderSide(color: Color(0xFF1A0088), width: 1.5)),
                child: const Text("Cancel", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              isSubmitting 
                ? const CircularProgressIndicator() 
                : ElevatedButton(
                    onPressed: () async {
                      if (_nameCtrl.text.trim().isEmpty || _emailCtrl.text.trim().isEmpty || _passCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill all fields.")));
                        return;
                      }
                      
                      setModalState(() => isSubmitting = true);
                      
                      try {
                        final res = await http.post(
                          Uri.parse('http://10.174.134.39:5000/api/admins/create'),
                          headers: {'Content-Type': 'application/json'},
                          body: jsonEncode({
                            'full_name': _nameCtrl.text.trim(),
                            'email': _emailCtrl.text.trim(),
                            'password': _passCtrl.text.trim(),
                            'is_admin': true 
                          }),
                        );
                        
                        if (res.statusCode == 201) {
                          if (context.mounted) Navigator.pop(ctx);
                          _fetchAdmins();
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Admin created successfully!")));
                        } else {
                          final data = jsonDecode(res.body);
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${data['message']}")));
                        }
                      } catch (e) {
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Server Error: Unable to connect.")));
                      } finally {
                        setModalState(() => isSubmitting = false);
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A0088), foregroundColor: Colors.white),
                    child: const Text("Create", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
            ],
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A0088),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text("Manage Admins", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddAdminModal,
        backgroundColor: Colors.yellow,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text("Add Admin", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: adminList.length,
            itemBuilder: (context, index) {
              final admin = adminList[index];
              bool isSuperAdmin = admin['email'] == superAdminEmail;

              return Container(
                margin: const EdgeInsets.only(bottom: 15),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.black12)
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(admin['full_name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                            if (isSuperAdmin) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: Colors.yellow, borderRadius: BorderRadius.circular(10)),
                                child: const Text("Super Admin", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                              )
                            ]
                          ],
                        ),
                        Text(admin['email'], style: const TextStyle(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    if (!isSuperAdmin)
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (deleteCtx) => AlertDialog(
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              title: const Text("Delete Admin?", style: TextStyle(color: Color(0xFF1A0088), fontWeight: FontWeight.bold)),
                              content: Text("Are you sure you want to permanently delete the admin account for '${admin['email']}'?"),
                              actions: [
                                OutlinedButton(
                                  onPressed: () => Navigator.pop(deleteCtx),
                                  style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF1A0088), side: const BorderSide(color: Color(0xFF1A0088), width: 1.5)),
                                  child: const Text("Cancel", style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(deleteCtx);
                                    _deleteAdmin(admin['id'], admin['email']);
                                  },
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                                  child: const Text("Delete", style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ],
                            )
                          );
                        },
                      )
                  ],
                ),
              );
            },
          ),
    );
  }
}
// lib/screens/admin_dashboard.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

import '../globals.dart';
import 'auth_screens.dart'; 

// ==================== SHARED DESIGN CONSTANTS ====================
const Color primaryBlue = Color(0xFF1A0088);
const Color accentYellow = Color(0xFFFFD700);
const Color textDark = Color(0xFF1F2937);
const Color textLight = Color(0xFF6B7280);
const Color borderGrey = Color(0xFFE5E7EB);
const Color bgGray = Color(0xFFF8FAFC);

ImageProvider? _getSafeImage(String? base64Str) {
  if (base64Str == null || base64Str.isEmpty || base64Str.length < 100) return null;
  try {
    return MemoryImage(base64Decode(base64Str));
  } catch (e) {
    return null; 
  }
}

// =========================================================================
// 1. ADMIN DASHBOARD WRAPPER
// =========================================================================
class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const AdminItemsFeed(),
    const AdminUserListScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgGray,
      body: _pages[_currentIndex], 
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(top: BorderSide(color: borderGrey, width: 1)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, -5))
          ]
        ),
        child: NavigationBar(
          backgroundColor: Colors.white,
          elevation: 0,
          selectedIndex: _currentIndex,
          indicatorColor: primaryBlue.withOpacity(0.1),
          onDestinationSelected: (index) => setState(() => _currentIndex = index),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined, color: textLight),
              selectedIcon: Icon(Icons.inventory_2, color: primaryBlue),
              label: 'Items Feed',
            ),
            NavigationDestination(
              icon: Icon(Icons.people_outline, color: textLight),
              selectedIcon: Icon(Icons.people, color: primaryBlue),
              label: 'Users',
            ),
          ],
        ),
      ),
    );
  }
}

// =========================================================================
// 2. ADMIN ITEMS FEED 
// =========================================================================
class AdminItemsFeed extends StatefulWidget {
  const AdminItemsFeed({super.key});

  @override
  State<AdminItemsFeed> createState() => _AdminItemsFeedState();
}

class _AdminItemsFeedState extends State<AdminItemsFeed> {
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
      String url = 'https://huramay-app.onrender.com/api/items';
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
      final res = await http.delete(Uri.parse('https://huramay-app.onrender.com/api/items/$itemId'));
      if (res.statusCode == 200) {
        _fetchAllItems();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Item Deleted permanently.")));
      }
    } catch (e) {
      debugPrint("Delete error: $e");
    }
  }

  void _showConfirmation(String title, String content, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, color: textDark)),
        content: Text(content, style: const TextStyle(color: textLight, fontSize: 14)),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx),
            style: OutlinedButton.styleFrom(
              foregroundColor: textDark,
              side: const BorderSide(color: borderGrey, width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Cancel", style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Confirm", style: TextStyle(fontWeight: FontWeight.w600)),
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
      backgroundColor: bgGray,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: textDark),
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: bgGray,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderGrey, width: 1),
          ),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (value) => _fetchAllItems(),
            style: const TextStyle(fontSize: 14, color: textDark, fontWeight: FontWeight.w500),
            decoration: const InputDecoration(
              hintText: "Search feed...",
              hintStyle: TextStyle(color: textLight, fontSize: 14),
              prefixIcon: Icon(Icons.search, color: textLight, size: 20),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 10),
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
            icon: const Icon(Icons.account_circle_outlined, size: 28, color: textDark),
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: borderGrey, height: 1),
        ),
      ),
      body: Stack(
        children: [
          Positioned(
            top: -80, right: -60,
            child: Container(width: 250, height: 250, decoration: BoxDecoration(shape: BoxShape.circle, color: primaryBlue.withOpacity(0.03))),
          ),
          Positioned(
            bottom: 100, left: -80,
            child: Container(width: 200, height: 200, decoration: BoxDecoration(shape: BoxShape.circle, color: accentYellow.withOpacity(0.04))),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Text("Item Reports", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: textDark, letterSpacing: -0.5)),
              ),
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator(color: primaryBlue))
                    : allItems.isEmpty
                        ? _emptyState()
                        : ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.only(bottom: 24),
                            itemCount: allItems.length,
                            itemBuilder: (context, index) => _buildAdminCard(allItems[index]),
                          ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: borderGrey)),
            child: const Icon(Icons.check_circle_outline, size: 48, color: textLight),
          ),
          const SizedBox(height: 24),
          const Text("No items found. Feed is clean.", style: TextStyle(color: textLight, fontSize: 16, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildAdminCard(dynamic item) {
    ImageProvider? safeImg = _getSafeImage(item['image']);
    bool isFlagged = item['status']?.toString().toLowerCase() == 'flagged';

    return GestureDetector(
      onTap: () => _openAdminReportModal(item), 
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isFlagged ? Colors.red.shade100 : borderGrey, width: 1),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 16, offset: const Offset(0, 4))],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: bgGray,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isFlagged ? Colors.red.shade300 : borderGrey, width: 1),
                image: safeImg != null ? DecorationImage(image: safeImg, fit: BoxFit.cover) : null,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (safeImg == null) const Icon(Icons.image_outlined, size: 32, color: textLight),
                  if (isFlagged)
                    Container(
                      width: double.infinity, height: double.infinity,
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.7), borderRadius: BorderRadius.circular(11)),
                      child: const Icon(Icons.warning_amber_rounded, size: 36, color: Colors.red),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item['owner'],
                          style: const TextStyle(fontWeight: FontWeight.w600, color: textLight, fontSize: 12),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isFlagged ? Colors.red.shade50 : Colors.green.shade50,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: isFlagged ? Colors.red.shade200 : Colors.green.shade200, width: 1),
                        ),
                        child: Text(
                          item['status'],
                          style: TextStyle(color: isFlagged ? Colors.red.shade700 : Colors.green.shade700, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 0.5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(item['title'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDark, height: 1.2), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(item['dept'], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: textLight), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 16),
                  if (isFlagged)
                    Align(
                      alignment: Alignment.centerRight,
                      child: _modernAdminBtn("Delete Flagged Item", Colors.red.shade600, Colors.white, () {
                        _showConfirmation("Delete Flagged Item", "Are you sure you want to permanently delete '${item['title']}'?", () => _executeDelete(item['id']));
                      }),
                    )
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _modernAdminBtn("Review", Colors.white, textDark, () { _openAdminReportModal(item); }, isOutlined: true),
                        const SizedBox(width: 8),
                        _modernAdminBtn("Delete", Colors.red.shade50, Colors.red.shade700, () {
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
    );
  }

  Widget _modernAdminBtn(String text, Color bgColor, Color textColor, VoidCallback action, {bool isOutlined = false}) {
    return GestureDetector(
      onTap: action,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor, borderRadius: BorderRadius.circular(8),
          border: isOutlined ? Border.all(color: borderGrey) : null,
        ),
        child: Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textColor)),
      ),
    );
  }
}

// =========================================================================
// 3. USER MANAGEMENT SCREEN
// =========================================================================
class AdminUserListScreen extends StatefulWidget {
  const AdminUserListScreen({super.key});

  @override
  State<AdminUserListScreen> createState() => _AdminUserListScreenState();
}

class _AdminUserListScreenState extends State<AdminUserListScreen> {
  List<dynamic> allUsers = [];
  List<dynamic> filteredUsers = []; 
  bool isLoading = true;
  final TextEditingController _searchCtrl = TextEditingController();
  String _currentSort = 'Name (A-Z)';

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() => isLoading = true);
    try {
      final res = await http.get(Uri.parse('https://huramay-app.onrender.com/api/users'));
      if (res.statusCode == 200) {
        setState(() {
          allUsers = jsonDecode(res.body);
          filteredUsers = List.from(allUsers);
        });
        _applySorting(); 
      }
    } catch (e) {
      debugPrint("Fetch users error: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _applySorting() {
    setState(() {
      if (_currentSort == 'Name (A-Z)') {
        filteredUsers.sort((a, b) => a['full_name'].toString().toLowerCase().compareTo(b['full_name'].toString().toLowerCase()));
      } else if (_currentSort == 'Name (Z-A)') {
        filteredUsers.sort((a, b) => b['full_name'].toString().toLowerCase().compareTo(a['full_name'].toString().toLowerCase()));
      } else if (_currentSort == 'Department') {
        filteredUsers.sort((a, b) {
          int deptComp = a['department'].toString().toLowerCase().compareTo(b['department'].toString().toLowerCase());
          if (deptComp == 0) {
            return a['full_name'].toString().toLowerCase().compareTo(b['full_name'].toString().toLowerCase());
          }
          return deptComp;
        });
      }
    });
  }

  void _runFilter(String enteredKeyword) {
    List<dynamic> results = [];
    if (enteredKeyword.isEmpty) {
      results = List.from(allUsers); 
    } else {
      results = allUsers.where((user) {
        final nameLower = user['full_name'].toString().toLowerCase();
        final emailLower = user['email'].toString().toLowerCase();
        final deptLower = user['department'].toString().toLowerCase();
        final searchLower = enteredKeyword.toLowerCase();
        
        return nameLower.contains(searchLower) || emailLower.contains(searchLower) || deptLower.contains(searchLower);
      }).toList();
    }
    setState(() => filteredUsers = results);
    _applySorting(); 
  }

  // --- NEW: TOGGLE DISABLE LOGIC ---
  Future<void> _executeToggleDisable(dynamic user) async {
    int userId = user['id'];
    try {
      final res = await http.put(Uri.parse('https://huramay-app.onrender.com/api/users/$userId/toggle_disable'));
      final data = jsonDecode(res.body);
      
      if (res.statusCode == 200) {
        _fetchUsers();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'])));
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'])));
      }
    } catch (e) {
      debugPrint("Toggle disable error: $e");
    }
  }

  void _showDisableConfirmation(dynamic user, bool isDisabled) {
    String action = isDisabled ? "Enable" : "Disable";
    Color actionColor = isDisabled ? Colors.green.shade600 : Colors.orange.shade600;
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(isDisabled ? Icons.check_circle : Icons.warning_amber_rounded, color: actionColor),
            const SizedBox(width: 8),
            Text("$action User?", style: const TextStyle(fontWeight: FontWeight.w800, color: textDark)),
          ],
        ),
        content: Text(
          "Are you sure you want to ${action.toLowerCase()} '${user['full_name']}'?\n\n${isDisabled ? 'They will be allowed to log in and use the app again.' : 'They will be locked out of their account, but their data will remain safe.'}", 
          style: const TextStyle(color: textLight, fontSize: 14)
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx),
            style: OutlinedButton.styleFrom(foregroundColor: textDark, side: const BorderSide(color: borderGrey, width: 1.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _executeToggleDisable(user);
            },
            style: ElevatedButton.styleFrom(backgroundColor: actionColor, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: Text(action, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // --- HARD DELETE LOGIC (VAVT-88) ---
  Future<void> _executeHardDelete(int userId) async {
    try {
      final res = await http.delete(Uri.parse('https://huramay-app.onrender.com/api/users/$userId/hard_delete'));
      if (res.statusCode == 200) {
        _fetchUsers();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("User completely wiped from database.")));
      } else {
        final data = jsonDecode(res.body);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'], style: const TextStyle(color: Colors.white)), backgroundColor: Colors.red.shade800));
      }
    } catch (e) {
      debugPrint("Delete error: $e");
    }
  }

  void _showHardDeleteConfirmation(dynamic user) {
    final TextEditingController _confirmCtrl = TextEditingController();
    bool isMatch = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.delete_forever, color: Colors.red),
                SizedBox(width: 8),
                Text("HARD DELETE", style: TextStyle(fontWeight: FontWeight.w800, color: Colors.red)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("This action is irreversible. All of '${user['full_name']}'s items and data will be destroyed.", style: const TextStyle(color: textLight, fontSize: 14)),
                const SizedBox(height: 16),
                const Text("Type DELETE to confirm:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: textDark)),
                const SizedBox(height: 8),
                TextField(
                  controller: _confirmCtrl,
                  onChanged: (val) {
                    setModalState(() => isMatch = val == 'DELETE');
                  },
                  decoration: InputDecoration(
                    hintText: "DELETE",
                    filled: true,
                    fillColor: bgGray,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: borderGrey)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: borderGrey)),
                  ),
                )
              ],
            ),
            actions: [
              OutlinedButton(
                onPressed: () => Navigator.pop(ctx),
                style: OutlinedButton.styleFrom(foregroundColor: textDark, side: const BorderSide(color: borderGrey, width: 1.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: isMatch ? () {
                  Navigator.pop(ctx);
                  _executeHardDelete(user['id']);
                } : null, 
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text("Permanently Delete", style: TextStyle(fontWeight: FontWeight.w600)),
              )
            ]
          );
        }
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgGray,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text("Registered Users", style: TextStyle(color: textDark, fontWeight: FontWeight.w800)),
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (c) => const AdminProfileScreen()));
            },
            icon: const Icon(Icons.account_circle_outlined, size: 28, color: textDark),
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: borderGrey, height: 1),
        ),
      ),
      body: Stack(
        children: [
          Positioned(
            top: -80, right: -60,
            child: Container(width: 250, height: 250, decoration: BoxDecoration(shape: BoxShape.circle, color: primaryBlue.withOpacity(0.03))),
          ),
          
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: borderGrey)),
                        child: TextField(
                          controller: _searchCtrl,
                          onChanged: (value) => _runFilter(value),
                          style: const TextStyle(fontSize: 14, color: textDark, fontWeight: FontWeight.w500),
                          decoration: const InputDecoration(
                            hintText: "Search name, email...", hintStyle: TextStyle(fontSize: 14, color: textLight),
                            prefixIcon: Icon(Icons.search, size: 20, color: textLight), border: InputBorder.none, contentPadding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      height: 44,
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: borderGrey)),
                      child: PopupMenuButton<String>(
                        icon: const Icon(Icons.sort, color: textDark, size: 22),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        onSelected: (String newValue) {
                          setState(() => _currentSort = newValue);
                          _applySorting();
                        },
                        itemBuilder: (BuildContext context) => [
                          PopupMenuItem(value: 'Name (A-Z)', child: Text('Name (A-Z)', style: TextStyle(fontWeight: _currentSort == 'Name (A-Z)' ? FontWeight.bold : FontWeight.normal, color: textDark))),
                          PopupMenuItem(value: 'Name (Z-A)', child: Text('Name (Z-A)', style: TextStyle(fontWeight: _currentSort == 'Name (Z-A)' ? FontWeight.bold : FontWeight.normal, color: textDark))),
                          PopupMenuItem(value: 'Department', child: Text('By Department', style: TextStyle(fontWeight: _currentSort == 'Department' ? FontWeight.bold : FontWeight.normal, color: textDark))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    const Text("Total Users: ", style: TextStyle(color: textLight, fontWeight: FontWeight.w500, fontSize: 14)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: primaryBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: Text("${filteredUsers.length}", style: const TextStyle(color: primaryBlue, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator(color: primaryBlue))
                    : filteredUsers.isEmpty
                        ? const Center(child: Text("No users match your search.", style: TextStyle(color: textLight)))
                        : ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.only(bottom: 24),
                            itemCount: filteredUsers.length,
                            itemBuilder: (context, index) {
                              final user = filteredUsers[index];
                              String initials = user['full_name'].toString().isNotEmpty 
                                  ? user['full_name'].toString().substring(0, 1).toUpperCase() 
                                  : "?";
                                  
                              // Grab the status from the backend
                              bool isDisabled = user['is_disabled'] ?? false;

                              return Container(
                                margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white, 
                                  borderRadius: BorderRadius.circular(12), 
                                  border: Border.all(color: isDisabled ? Colors.orange.shade200 : borderGrey, width: isDisabled ? 1.5 : 1),
                                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))],
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 24, backgroundColor: primaryBlue.withOpacity(0.1), foregroundColor: primaryBlue,
                                      child: Text(initials, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(user['full_name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textDark), maxLines: 1, overflow: TextOverflow.ellipsis),
                                              ),
                                              if (isDisabled)
                                                Container(
                                                  margin: const EdgeInsets.only(left: 8),
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
                                                  child: Text("DISABLED", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.orange.shade700)),
                                                )
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(user['email'], style: const TextStyle(fontSize: 13, color: textLight)),
                                          const SizedBox(height: 2),
                                          Text(user['department'], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: textDark), maxLines: 1, overflow: TextOverflow.ellipsis),
                                        ],
                                      ),
                                    ),
<<<<<<< HEAD
                                    // DOUBLE ACTION BUTTONS (VAVT-91 Armor)
=======
>>>>>>> d2fde7bcb7b2ce08749157825de7d95a3a13f849
                                    user['is_admin'] == true
                                        ? Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: Colors.blueGrey.shade50, 
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(color: Colors.blueGrey.shade200)
                                            ),
<<<<<<< HEAD
                                            child: const Text("Protected Admin", style: TextStyle(color: Colors.blueGrey, fontSize: 10, fontWeight: FontWeight.bold)),
=======
                                            child: const Text("Protected", style: TextStyle(color: Colors.blueGrey, fontSize: 10, fontWeight: FontWeight.bold)),
>>>>>>> d2fde7bcb7b2ce08749157825de7d95a3a13f849
                                          )
                                        : Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
<<<<<<< HEAD
                                              IconButton(
                                                icon: const Icon(Icons.block, color: Colors.orange, size: 24),
                                                tooltip: "Ban User",
                                                onPressed: () => _showBanConfirmation(user),
                                              ),
=======
                                              // NEW TOGGLE BUTTON
                                              IconButton(
                                                icon: Icon(isDisabled ? Icons.check_circle_outline : Icons.block, color: isDisabled ? Colors.green : Colors.orange, size: 24),
                                                tooltip: isDisabled ? "Enable User" : "Disable User",
                                                onPressed: () => _showDisableConfirmation(user, isDisabled),
                                              ),
                                              // HARD DELETE REMAINS
>>>>>>> d2fde7bcb7b2ce08749157825de7d95a3a13f849
                                              IconButton(
                                                icon: const Icon(Icons.delete_forever, color: Colors.red, size: 24),
                                                tooltip: "Hard Delete",
                                                onPressed: () => _showHardDeleteConfirmation(user),
                                              ),
                                            ],
                                          ),
                                  ],
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// 4. THE ADMIN REPORT OVERLAY DIALOG 
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
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.info_outline, size: 48, color: primaryBlue),
            const SizedBox(height: 16),
            const Text(
              "Submit Report?",
              textAlign: TextAlign.center,
              style: TextStyle(color: textDark, fontWeight: FontWeight.w800, fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text(
              "Are you sure you want to flag this item?",
              textAlign: TextAlign.center,
              style: TextStyle(color: textLight, fontSize: 14),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: textDark,
                    side: const BorderSide(color: borderGrey, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    minimumSize: const Size(100, 44),
                  ),
                  child: const Text("Cancel", style: TextStyle(fontWeight: FontWeight.w600)),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); 
                    _submitReportToBackend(); 
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    minimumSize: const Size(100, 44),
                    elevation: 0,
                  ),
                  child: const Text("Submit", style: TextStyle(fontWeight: FontWeight.w600)),
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
        Uri.parse('https://huramay-app.onrender.com/api/report'),
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
    ImageProvider? safeImg = _getSafeImage(widget.itemData['image']);
    bool hasImage = safeImg != null;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 0.65, 
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Review Item", style: TextStyle(color: textDark, fontWeight: FontWeight.w800, fontSize: 18)),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: bgGray, shape: BoxShape.circle, border: Border.all(color: borderGrey)),
                    child: const Icon(Icons.close, size: 20, color: textLight),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: bgGray,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderGrey, width: 1),
                image: hasImage ? DecorationImage(image: safeImg, fit: BoxFit.cover) : null,
              ),
              child: !hasImage ? const Icon(Icons.image_outlined, size: 40, color: textLight) : null,
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: bgGray, 
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderGrey)
                ),
                child: TextField(
                  controller: _reportTextCtrl,
                  maxLines: null, 
                  keyboardType: TextInputType.multiline,
                  style: const TextStyle(fontSize: 14, color: textDark),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(16),
                    hintText: "Enter formal flag reason or note...",
                    hintStyle: TextStyle(color: textLight, fontSize: 14)
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            isSubmitting 
              ? const CircularProgressIndicator(color: primaryBlue)
              : SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _handleReport, 
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text("Submit Flag Report", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  ),
                )
          ],
        ),
      ),
    );
  }
}

// =========================================================================
// 5. ADMIN PROFILE SCREEN
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
      backgroundColor: bgGray,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: textDark),
        title: const Text("Admin Profile", style: TextStyle(color: textDark, fontWeight: FontWeight.w800)),
        centerTitle: true,
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(color: borderGrey, height: 1)),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: borderGrey, width: 1),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: const CircleAvatar(
                radius: 60,
                backgroundColor: primaryBlue,
                child: Icon(Icons.admin_panel_settings_outlined, size: 60, color: Colors.white),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              currentUser?['full_name'] ?? "System Administrator",
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: textDark, letterSpacing: -0.5),
            ),
            const SizedBox(height: 8),
            Text(
              currentUser?['email'] ?? "admin@lnu.edu.ph",
              style: const TextStyle(fontSize: 14, color: textLight, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 48),
            
<<<<<<< HEAD
            // VAVT-91: Only the Super Admin can see the "Manage Administrators" route
=======
>>>>>>> d2fde7bcb7b2ce08749157825de7d95a3a13f849
            if (currentUser?['email'] == 'admin@gmail.com') ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (c) => const AdminManagementScreen()));
                  },
                  icon: const Icon(Icons.manage_accounts_outlined, size: 20),
                  label: const Text("Manage Administrators", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: textDark,
                    side: const BorderSide(color: borderGrey, width: 1),
                    backgroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: ElevatedButton.icon(
                onPressed: () => _logout(context),
                icon: const Icon(Icons.logout, size: 20),
                label: const Text("Sign Out", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade50,
                  foregroundColor: Colors.red.shade700,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =========================================================================
// 6. ADMIN MANAGEMENT SCREEN 
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
      final res = await http.get(Uri.parse('https://huramay-app.onrender.com/api/admins'));
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
      final res = await http.delete(Uri.parse('https://huramay-app.onrender.com/api/admins/$id'));
      if (res.statusCode == 200) {
        _fetchAdmins();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Admin account deleted.")));
      }
    } catch (e) {
      debugPrint("Delete admin error: $e");
    }
  }

  void _showAddAdminModal() {
    final _formKey = GlobalKey<FormState>();
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
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text("Create New Admin", style: TextStyle(color: textDark, fontWeight: FontWeight.w800, fontSize: 18)),
            content: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _nameCtrl,
                      style: const TextStyle(fontSize: 14, color: textDark),
                      decoration: InputDecoration(
                        labelText: "Full Name", 
                        labelStyle: const TextStyle(color: textLight),
                        filled: true, fillColor: bgGray, 
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: borderGrey)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: borderGrey)),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return "Name is required";
                        if (!RegExp(r'^[a-zA-Z\s.]+$').hasMatch(value)) return "No special characters/emojis";
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailCtrl,
                      style: const TextStyle(fontSize: 14, color: textDark),
                      decoration: InputDecoration(
                        labelText: "Email Address", 
                        labelStyle: const TextStyle(color: textLight),
                        filled: true, fillColor: bgGray, 
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: borderGrey)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: borderGrey)),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return "Email is required";
                        if (!RegExp(r'^[a-zA-Z0-9._]+@gmail\.com$').hasMatch(value)) return "Must end in @gmail.com";
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passCtrl,
                      obscureText: true,
                      style: const TextStyle(fontSize: 14, color: textDark),
                      decoration: InputDecoration(
                        labelText: "Password", 
                        labelStyle: const TextStyle(color: textLight),
                        filled: true, fillColor: bgGray, 
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: borderGrey)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: borderGrey)),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return "Password is required";
                        if (RegExp(r'[^\x00-\x7F]').hasMatch(value)) return "Cannot contain emojis";
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              OutlinedButton(
                onPressed: () => Navigator.pop(ctx),
                style: OutlinedButton.styleFrom(foregroundColor: textDark, side: const BorderSide(color: borderGrey, width: 1.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text("Cancel", style: TextStyle(fontWeight: FontWeight.w600)),
              ),
              isSubmitting 
                ? const CircularProgressIndicator(color: primaryBlue) 
                : ElevatedButton(
                    onPressed: () async {
                      if (!_formKey.currentState!.validate()) return;
                      setModalState(() => isSubmitting = true);
                      try {
                        final res = await http.post(
                          Uri.parse('https://huramay-app.onrender.com/api/admins/create'),
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
                    style: ElevatedButton.styleFrom(backgroundColor: primaryBlue, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: const Text("Create", style: TextStyle(fontWeight: FontWeight.w600)),
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
      backgroundColor: bgGray,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: textDark),
        title: const Text("Manage Admins", style: TextStyle(color: textDark, fontWeight: FontWeight.w800)),
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(color: borderGrey, height: 1)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddAdminModal,
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.add, size: 20),
        label: const Text("Add Admin", style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator(color: primaryBlue))
        : ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(24),
            itemCount: adminList.length,
            itemBuilder: (context, index) {
              final admin = adminList[index];
              bool isSuperAdmin = admin['email'] == superAdminEmail;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderGrey),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))]
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(admin['full_name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textDark)),
                            if (isSuperAdmin) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: primaryBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                                child: const Text("Super Admin", style: TextStyle(color: primaryBlue, fontSize: 10, fontWeight: FontWeight.bold)),
                              )
                            ]
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(admin['email'], style: const TextStyle(color: textLight, fontSize: 13, fontWeight: FontWeight.w500)),
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
                              surfaceTintColor: Colors.transparent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              title: const Text("Delete Admin?", style: TextStyle(color: textDark, fontWeight: FontWeight.w800)),
                              content: Text("Are you sure you want to permanently delete the admin account for '${admin['email']}'?", style: const TextStyle(color: textLight, fontSize: 14)),
                              actions: [
                                OutlinedButton(
                                  onPressed: () => Navigator.pop(deleteCtx),
                                  style: OutlinedButton.styleFrom(foregroundColor: textDark, side: const BorderSide(color: borderGrey, width: 1.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                  child: const Text("Cancel", style: TextStyle(fontWeight: FontWeight.w600)),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(deleteCtx);
                                    _deleteAdmin(admin['id'], admin['email']);
                                  },
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                  child: const Text("Delete", style: TextStyle(fontWeight: FontWeight.w600)),
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
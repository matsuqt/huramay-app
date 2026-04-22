// lib/widgets/app_sidebar.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../globals.dart';
import '../screens/auth_screens.dart';
import '../screens/dashboard_screen.dart';
import '../screens/item_screens.dart';
import '../screens/chat_screens.dart';
import '../screens/borrowing_screens.dart';
import '../screens/history_screen.dart';
import '../screens/admin_dashboard.dart'; 
import '../screens/reports_screen.dart';

// ==================== SHARED DESIGN CONSTANTS ====================
const Color primaryBlue = Color(0xFF1A0088);
const Color accentYellow = Color(0xFFFFD700);
const Color textDark = Color(0xFF1F2937);
const Color textLight = Color(0xFF6B7280);
const Color borderGrey = Color(0xFFE5E7EB);
const Color bgGray = Color(0xFFF8FAFC);

// ==================== GLOBAL SIDEBAR ====================
class AppSidebar extends StatefulWidget {
  const AppSidebar({super.key});

  @override
  State<AppSidebar> createState() => _AppSidebarState();
}

class _AppSidebarState extends State<AppSidebar> {
  int unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchUnreadCount();
  }

  Future<void> _fetchUnreadCount() async {
    if (currentUser == null) return;
    try {
      final res = await http.get(Uri.parse('https://huramay-app.onrender.com/api/messages/unread/${currentUser!['id']}'));
      if (res.statusCode == 200) {
        if (mounted) {
          setState(() {
            unreadCount = jsonDecode(res.body)['unread_count'];
          });
        }
      }
    } catch (e) {
      debugPrint("Badge Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isAdmin = currentUser?['is_admin'] ?? false; 
    
    String userName = currentUser?['full_name'] ?? "User";
    String initial = userName.isNotEmpty ? userName[0].toUpperCase() : "U";

    return Drawer(
      backgroundColor: bgGray, 
      elevation: 0,
      child: Column(
        children: [
          // 1. Modern Custom Header (Replaces the heavy blue block)
          Container(
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: borderGrey, width: 1)),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: primaryBlue.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: primaryBlue.withOpacity(0.2), width: 1),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initial,
                    style: const TextStyle(fontSize: 24, color: primaryBlue, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName, 
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: textDark, letterSpacing: -0.5),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currentUser?['department'] ?? "No Department",
                        style: const TextStyle(fontSize: 12, color: textLight, fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // 2. Menu Items List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              physics: const BouncingScrollPhysics(),
              children: [
                _modernMenuBtn(context, "Dashboard", Icons.dashboard_outlined),
                _modernMenuBtn(context, "My Items", Icons.inventory_2_outlined),
                _modernMenuBtn(context, "Department Filters", Icons.filter_list),
                _modernMenuBtn(context, "Favorites", Icons.favorite_border),
                
                // Messages with modern pill badge
                _modernMenuBtn(
                  context, "Messages", Icons.message_outlined, 
                  trailing: unreadCount > 0 
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red.shade200)),
                        child: Text(
                          unreadCount.toString(), 
                          style: TextStyle(color: Colors.red.shade700, fontSize: 11, fontWeight: FontWeight.bold)
                        ),
                      )
                    : null
                ),
                
                _modernMenuBtn(context, "History", Icons.history),
                _modernMenuBtn(context, "Requests", Icons.notifications_none),
                _modernMenuBtn(context, "Reports", Icons.report_gmailerrorred),
                
                // Admin Section
                if (isAdmin) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Divider(color: borderGrey, thickness: 1),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(left: 24, bottom: 8),
                    child: Text("ADMIN CONTROLS", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textLight, letterSpacing: 1.2)),
                  ),
                  _modernMenuBtn(context, "Admin Panel", Icons.admin_panel_settings_outlined, isHighlight: true),
                ],
              ],
            ),
          ),
          
          // 3. Logout anchored at the bottom
          const Divider(color: borderGrey, thickness: 1, height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: _modernMenuBtn(context, "Logout", Icons.logout, isLogout: true),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // Modernized Pill-Shaped Menu Button
  Widget _modernMenuBtn(BuildContext context, String title, IconData icon, {bool isLogout = false, bool isHighlight = false, Widget? trailing}) {
    Color itemColor = isLogout ? Colors.red.shade600 : (isHighlight ? primaryBlue : textDark);
    Color iconColor = isLogout ? Colors.red.shade500 : (isHighlight ? primaryBlue : textLight);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        leading: Icon(icon, size: 22, color: iconColor),
        title: Text(
          title, 
          style: TextStyle(color: itemColor, fontWeight: FontWeight.w600, fontSize: 14)
        ),
        trailing: trailing,
        onTap: () {
          if (isLogout) {
            currentUser = null;
            Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (c) => const LoginScreen()), (route) => false);
          } else if (title == "Admin Panel") {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const AdminDashboard()));
          } else if (title == "My Items") {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const MyItemsScreen()));
          } else if (title == "Dashboard") {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const DashboardScreen()));
          } else if (title == "Department Filters") {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const DepartmentScreen()));
          } else if (title == "Favorites") {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const FavoritesScreen()));
          } else if (title == "Messages") {
            Navigator.pop(context); 
            Navigator.push(context, MaterialPageRoute(builder: (c) => const ChatInboxScreen()));
          } else if (title == "History") {
            Navigator.pop(context);
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const HistoryScreen()));
          } else if (title == "Requests") {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const RequestsScreen()));
          } else if (title == "Reports") { 
            Navigator.pop(context); 
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const ReportsScreen()));
          } else {
            Navigator.pop(context); 
          }
        },
      ),
    );
  }
}
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
      // FIXED: Now uses $baseUrl so it never breaks when your Wi-Fi changes!
      final res = await http.get(Uri.parse('$baseUrl/api/messages/unread/${currentUser!['id']}'));
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
    
    // Extracting initials for the modern avatar
    String userName = currentUser?['full_name'] ?? "User";
    String initial = userName.isNotEmpty ? userName[0].toUpperCase() : "U";

    return Drawer(
      backgroundColor: Colors.white, // Clean white background
      child: Column(
        children: [
          // Modern User Header in LNU Blue
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              color: Color(0xFF1A0088),
            ),
            accountName: Text(
              userName, 
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
            ),
            accountEmail: Text(
              currentUser?['department'] ?? "No Department",
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                initial,
                style: const TextStyle(
                  fontSize: 24, 
                  color: Color(0xFF1A0088), 
                  fontWeight: FontWeight.bold
                ),
              ),
            ),
          ),
          
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _modernMenuBtn(context, "Dashboard", Icons.dashboard_outlined),
                _modernMenuBtn(context, "My Items", Icons.inventory_2_outlined),
                _modernMenuBtn(context, "Department Filters", Icons.filter_list),
                _modernMenuBtn(context, "Favorites", Icons.favorite_border),
                
                // Messages with a modern badge
                _modernMenuBtn(
                  context, "Messages", Icons.message_outlined, 
                  trailing: unreadCount > 0 
                    ? Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                        child: Text(
                          unreadCount.toString(), 
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)
                        ),
                      )
                    : null
                ),
                
                _modernMenuBtn(context, "History", Icons.history),
                _modernMenuBtn(context, "Requests", Icons.notifications_none),
                
                // FIXED: Moved the Reports button here so EVERYONE can see it!
                _modernMenuBtn(context, "Reports", Icons.report_gmailerrorred),
                
                // Admin Section (Only Admins see the Admin Panel)
                if (isAdmin) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Divider(color: Colors.black12, thickness: 1),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(left: 20, bottom: 5),
                    child: Text("ADMIN CONTROLS", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
                  ),
                  _modernMenuBtn(context, "Admin Panel", Icons.admin_panel_settings_outlined, isHighlight: true),
                ],
              ],
            ),
          ),
          
          // Logout anchored at the bottom
          const Divider(color: Colors.black12, thickness: 1),
          _modernMenuBtn(context, "Logout", Icons.logout, isLogout: true),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // Modernized Menu Button Logic
  Widget _modernMenuBtn(BuildContext context, String title, IconData icon, {bool isLogout = false, bool isHighlight = false, Widget? trailing}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 25),
      leading: Icon(
        icon, 
        size: 24, 
        color: isLogout ? Colors.red : (isHighlight ? const Color(0xFF1A0088) : Colors.black87)
      ),
      title: Text(
        title, 
        style: TextStyle(
          color: isLogout ? Colors.red : (isHighlight ? const Color(0xFF1A0088) : Colors.black87), 
          fontWeight: FontWeight.w600, 
          fontSize: 15
        )
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
        } else if (title == "Reports") { // FIXED: Now exactly matches the button name!
          Navigator.pop(context); 
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const ReportsScreen()));
        } else {
          Navigator.pop(context); 
        }
      },
    );
  }
}
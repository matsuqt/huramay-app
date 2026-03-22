// lib/screens/admin_dashboard.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import '../globals.dart';
import '../widgets/app_sidebar.dart';
import 'auth_screens.dart';

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
      String url = 'http://10.33.87.39:5000/api/items';
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
      final res = await http.delete(Uri.parse('http://10.33.87.39:5000/api/items/$itemId'));
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
      final res = await http.delete(Uri.parse('http://10.33.87.39:5000/api/users/$userId'));
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
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A0088))),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Confirm", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // TICKET VAVT-54: Detailed View (Deep Dive Modal)
  void _showItemDetails(dynamic item) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text(
            item['title'] ?? 'Item Details', 
            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A0088))
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Owner: ${item['owner']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text("Department: ${item['dept']}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 15),
                const Text("Full Description:", style: TextStyle(fontWeight: FontWeight.bold)),
                Text(item['description'] ?? 'No description provided.', style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 15),
                Text("Status: ${item['status']}", style: TextStyle(fontWeight: FontWeight.bold, color: item['status'] == 'Flagged' ? Colors.red : const Color(0xFF1A0088))),
              ],
            ),
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: [
            _adminBtn("Review", Colors.blueAccent, () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Opening reports... (Review module pending)")));
            }, textColor: Colors.white),
            
            _adminBtn("Ban", Colors.yellow, () {
              Navigator.pop(ctx);
              _showConfirmation("Ban User", "Are you sure you want to ban ${item['owner']}? This deletes their account and items.", () => _executeBan(item['user_id']));
            }),
            
            _adminBtn("Delete", Colors.red, () {
              Navigator.pop(ctx);
              _showConfirmation("Delete Item", "Are you sure you want to permanently delete '${item['title']}'?", () => _executeDelete(item['id']));
            }, textColor: Colors.white),
          ],
        );
      },
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
            onPressed: () {},
            icon: const Icon(Icons.account_circle, size: 30),
          )
        ],
      ),
      drawer: const AppSidebar(),
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

  Widget _buildAdminCard(dynamic item) {
    String? imgPath = item['image'];
    bool hasImage = imgPath != null && imgPath.isNotEmpty;
    
    // TICKET VAVT-54: Flagged State Logic
    bool isFlagged = item['status']?.toString().toLowerCase() == 'flagged';

    return GestureDetector(
      onTap: () => _showItemDetails(item), // TICKET VAVT-54: Trigger Deep Dive Modal
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 110,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isFlagged ? Colors.red : const Color(0xFF1A0088), width: 2), // Red border if flagged
                  image: hasImage ? DecorationImage(image: FileImage(File(imgPath!)), fit: BoxFit.cover) : null,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (!hasImage) const Icon(Icons.image, size: 40, color: Colors.grey),
                    // TICKET VAVT-54: Red cancellation symbol overlay
                    if (isFlagged)
                      Container(
                        width: double.infinity,
                        height: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.do_not_disturb_alt, size: 65, color: Colors.red),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFCCCCCC), 
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade500, width: 1),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 3, offset: const Offset(0, 2))
                    ]
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['owner'],
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A0088), fontSize: 13),
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            item['title'],
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            item['dept'],
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black),
                            maxLines: 2, overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            item['status'],
                            style: TextStyle(
                              color: isFlagged ? Colors.red : const Color(0xFF1A0088), 
                              fontWeight: FontWeight.bold, 
                              fontSize: 13
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // TICKET VAVT-54: Morphing Buttons based on Flagged state
                      if (isFlagged)
                        Center(
                          child: _adminBtn("Delete Flagged Item", Colors.red, () {
                            _showConfirmation("Delete Flagged Item", "Are you sure you want to permanently delete '${item['title']}'?", () => _executeDelete(item['id']));
                          }, textColor: Colors.white),
                        )
                      else
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _adminBtn("Ban", Colors.yellow, () {
                              _showConfirmation("Ban User", "Are you sure you want to ban ${item['owner']}? This will permanently delete their account and all their items.", () => _executeBan(item['user_id']));
                            }),
                            _adminBtn("Delete", Colors.yellow, () {
                              _showConfirmation("Delete Item", "Are you sure you want to permanently delete '${item['title']}' from the feed?", () => _executeDelete(item['id']));
                            }),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // UPDATED: Added textColor parameter for flexibility (e.g., white text on red background)
  Widget _adminBtn(String text, Color color, VoidCallback action, {Color textColor = Colors.black}) {
    return GestureDetector(
      onTap: action,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black54, width: 1),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 2, offset: const Offset(0, 2))]
        ),
        child: Text(
          text,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor),
        ),
      ),
    );
  }
}
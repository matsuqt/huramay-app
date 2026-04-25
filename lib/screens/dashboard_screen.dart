// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart'; 

import '../widgets/app_sidebar.dart';
import 'auth_screens.dart';
import 'item_screens.dart';
import '../globals.dart'; 

// ==================== SHARED DESIGN CONSTANTS ====================
const Color primaryBlue = Color(0xFF1A0088);
const Color accentYellow = Color(0xFFFFD700);
const Color textDark = Color(0xFF1F2937);
const Color textLight = Color(0xFF6B7280);
const Color borderGrey = Color(0xFFE5E7EB);
const Color bgGray = Color(0xFFF8FAFC);

// ==================== DASHBOARD SCREEN ====================
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List items = []; 
  bool isLoading = true;
  String? _currentFilter; 
  final TextEditingController _searchCtrl = TextEditingController(); 

  @override
  void initState() {
    super.initState();
    _fetchItems();
    _setupFCMToken(); 
  }

  Future<void> _setupFCMToken() async {
    try {
      FirebaseMessaging messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();
      String? token = await messaging.getToken();
      
      if (token != null && currentUser != null) {
        debugPrint("📱 FIREBASE DEVICE TOKEN: $token"); 
        await http.post(
          Uri.parse('https://huramay-app.onrender.com/api/user/update_token'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'user_id': currentUser!['id'],
            'fcm_token': token,
          }),
        );
      }
    } catch (e) {
      debugPrint("FCM Setup Error: $e");
    }
  }

  Future<void> _fetchItems() async {
    setState(() => isLoading = true);
    try {
      String url = 'https://huramay-app.onrender.com/api/items';
      List<String> queryParams = [];
      
      if (_currentFilter != null && _currentFilter != 'All') {
        queryParams.add('status=$_currentFilter');
      }
      
      String searchQuery = _searchCtrl.text.trim();
      if (searchQuery.isNotEmpty) {
        queryParams.add('search=${Uri.encodeComponent(searchQuery)}');
      }
      
      if (queryParams.isNotEmpty) url += '?${queryParams.join('&')}';
      
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        setState(() {
          items = jsonDecode(res.body);
        });
      }
    } catch (e) {
      debugPrint("Dashboard Fetch Error: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // VAVT-84: Check for user profile image
    String? photoBase64 = currentUser?['photo_path'];
    bool hasPhoto = photoBase64 != null && photoBase64.isNotEmpty;

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
            onChanged: (value) => _fetchItems(), 
            style: const TextStyle(fontSize: 14, color: textDark, fontWeight: FontWeight.w500),
            decoration: const InputDecoration(
              hintText: "Search items...",
              hintStyle: TextStyle(color: textLight, fontSize: 14),
              prefixIcon: Icon(Icons.search, color: textLight, size: 20), 
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
        actions: [
          // VAVT-84: Dynamic Profile Picture Button
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (c) => const ProfileScreen()),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: primaryBlue.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: borderGrey, width: 1),
                  image: hasPhoto 
                    ? DecorationImage(image: MemoryImage(base64Decode(photoBase64!)), fit: BoxFit.cover) 
                    : null,
                ),
                child: !hasPhoto 
                  ? const Icon(Icons.person_outline, size: 20, color: textDark) 
                  : null,
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: borderGrey, height: 1),
        ),
      ),
      drawer: const AppSidebar(),
      body: Stack(
        children: [
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryBlue.withOpacity(0.03),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: -80,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentYellow.withOpacity(0.04), 
              ),
            ),
          ),
          
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16), 
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      "Dashboard",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: textDark,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Container(
                      height: 32,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: borderGrey),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _currentFilter,
                          hint: const Text("All Items", style: TextStyle(fontSize: 13, color: textDark, fontWeight: FontWeight.w600)),
                          icon: const Icon(Icons.keyboard_arrow_down, size: 16, color: textLight),
                          alignment: Alignment.centerRight,
                          items: ['Available', 'Borrowed'].map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value, style: const TextStyle(fontSize: 13, color: textDark, fontWeight: FontWeight.w600)),
                            );
                          }).toList(),
                          onChanged: (newValue) {
                            setState(() => _currentFilter = newValue);
                            _fetchItems();
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: isLoading 
                  ? const Center(child: CircularProgressIndicator(color: primaryBlue)) 
                  : items.isEmpty 
                      ? _emptyStateDashboard() 
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.only(bottom: 100, top: 8), 
                          itemCount: items.length,
                          itemBuilder: (c, i) => _itemCard(context, items[i]),
                        ),
              ),
            ],
          ),
        ],
      ),
      
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (c) => const AddItemScreen()),
          );
          _fetchItems();
        },
        backgroundColor: primaryBlue, 
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  Widget _emptyStateDashboard() {
    String message = "No Items Found";
    if (_searchCtrl.text.trim().isNotEmpty) message = "No results match your search";
    else if (_currentFilter == "Available") message = "No items currently available";
    else if (_currentFilter == "Borrowed") message = "No items currently borrowed";
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: borderGrey),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
              ],
            ),
            child: const Icon(Icons.inventory_2_outlined, size: 48, color: textLight),
          ),
          const SizedBox(height: 24),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: textLight,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemCard(BuildContext context, dynamic item) {
    String? imgPath = item['image'];
    bool hasImage = imgPath != null && imgPath.isNotEmpty;
    bool isAvailable = item['status']?.toString().toLowerCase() == 'available';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (c) => DetailedItemScreen(item: item)),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderGrey, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03), 
              blurRadius: 16, 
              offset: const Offset(0, 4)
            )
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Container
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: bgGray,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderGrey, width: 1), 
                image: hasImage 
                  ? DecorationImage(image: FileImage(File(imgPath!)), fit: BoxFit.cover) 
                  : null,
              ),
              child: !hasImage ? const Icon(Icons.image_outlined, size: 32, color: textLight) : null,
            ),
            const SizedBox(width: 16),
            
            // Text Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item['owner'],
                          style: const TextStyle(fontWeight: FontWeight.w600, color: textLight, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Modern Status Pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isAvailable ? Colors.green.shade50 : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: isAvailable ? Colors.green.shade200 : Colors.red.shade200, width: 1),
                        ),
                        child: Text(
                          item['status'],
                          style: TextStyle(
                            color: isAvailable ? Colors.green.shade700 : Colors.red.shade700, 
                            fontWeight: FontWeight.bold, 
                            fontSize: 10,
                            letterSpacing: 0.5,
                          ),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item['title'],
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDark, height: 1.2),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.inventory_2_outlined, size: 14, color: textLight),
                      const SizedBox(width: 4),
                      Text(
                        "Qty: ${item['quantity']}",
                        style: const TextStyle(fontSize: 12, color: textDark, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.info_outline, size: 14, color: textLight),
                      const SizedBox(width: 4),
                      Text(
                        item['condition'],
                        style: const TextStyle(fontSize: 12, color: textDark, fontWeight: FontWeight.w500),
                      ),
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
}
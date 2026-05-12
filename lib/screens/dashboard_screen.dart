// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../widgets/app_sidebar.dart';
import '../utils/ui_helpers.dart';
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
  String _currentFilter = 'All'; // Default filter set to 'All' to match Admin side
  final TextEditingController _searchCtrl = TextEditingController(); 

  // --- Lazy Loading Variables ---
  final ScrollController _scrollController = ScrollController();
  int _displayCount = 10;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _fetchItems();
    _setupFCMToken(); 

    // --- Scroll Listener to detect when user hits the bottom ---
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 50) {
        _loadMoreItems();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // --- Load More Function ---
  Future<void> _loadMoreItems() async {
    if (_isLoadingMore || _displayCount >= items.length) return;

    setState(() => _isLoadingMore = true);

    await Future.delayed(const Duration(milliseconds: 800));

    if (mounted) {
      setState(() {
        _displayCount += 10; 
        _isLoadingMore = false;
      });
    }
  }

  ImageProvider? _getSafeImage(String? base64Str) {
    if (base64Str == null || base64Str.isEmpty || base64Str.length < 100) return null;
    try {
      return MemoryImage(base64Decode(base64Str));
    } catch (e) {
      return null; 
    }
  }

  Future<void> _setupFCMToken() async {
    try {
      FirebaseMessaging messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();
      String? token = await messaging.getToken();
      
      if (token != null && currentUser != null) {
        debugPrint("📱 FIREBASE DEVICE TOKEN: $token"); 
        await http.post(
          Uri.parse('http://10.198.13.39:5000/api/user/update_token'),
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
    setState(() {
      isLoading = true;
      _displayCount = 10; 
    });
    
    try {
      String url = 'http://10.198.13.39:5000/api/items';
      List<String> queryParams = [];
      
      // Removed the backend status filter so we fetch ALL items 
      // and do local filtering to generate accurate real-time stats
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

  // --- NEW: Helper widget for the Stats Dropdown ---
  Widget _buildStatRow(String label, String count, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(width: 90, child: Text(label, style: const TextStyle(color: textDark, fontSize: 13, fontWeight: FontWeight.w600))),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Text(count, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider? profileImg = _getSafeImage(currentUser?['photo_path']);

    // --- NEW: Calculate real-time stats instantly ---
    int totalItems = items.length;
    int availableItems = items.where((item) => item['status']?.toString().toLowerCase() == 'available').length;
    int borrowedItems = items.where((item) => item['status']?.toString().toLowerCase() == 'borrowed').length;

    // --- Apply the local filter based on the dropdown ---
    List<dynamic> filteredList = items;
    if (_currentFilter == 'Available') {
      filteredList = items.where((item) => item['status']?.toString().toLowerCase() == 'available').toList();
    } else if (_currentFilter == 'Borrowed') {
      filteredList = items.where((item) => item['status']?.toString().toLowerCase() == 'borrowed').toList();
    }

    // --- Slice the filtered list for Lazy Loading ---
    List<dynamic> itemsToDisplay = filteredList.take(_displayCount).toList();
    bool hasMoreData = itemsToDisplay.length < filteredList.length;

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
                  image: profileImg != null 
                    ? DecorationImage(image: profileImg, fit: BoxFit.cover) 
                    : null,
                ),
                child: profileImg == null 
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
                    
                    // --- NEW: The Admin-style Stats Dropdown ---
                    Container(
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: borderGrey),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))],
                      ),
                      child: PopupMenuButton<String>(
                        offset: const Offset(0, 40),
                        color: Colors.white,
                        surfaceTintColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        onSelected: (String newValue) {
                          setState(() {
                            _currentFilter = newValue;
                            _displayCount = 10; // Reset lazy load when changing tabs
                          });
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            children: [
                              Icon(Icons.analytics_outlined, size: 18, color: primaryBlue),
                              SizedBox(width: 6),
                              Text("Stats", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textDark)),
                              SizedBox(width: 4),
                              Icon(Icons.keyboard_arrow_down, size: 18, color: textLight),
                            ],
                          ),
                        ),
                        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                          PopupMenuItem<String>(
                            value: 'All', 
                            child: _buildStatRow("Total Items", totalItems.toString(), Colors.blueGrey),
                          ),
                          const PopupMenuDivider(),
                          PopupMenuItem<String>(
                            value: 'Available',
                            child: _buildStatRow("Available", availableItems.toString(), Colors.green.shade600),
                          ),
                          PopupMenuItem<String>(
                            value: 'Borrowed',
                            child: _buildStatRow("Borrowed", borrowedItems.toString(), Colors.orange.shade700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: isLoading 
                  ? const Center(child: CircularProgressIndicator(color: primaryBlue)) 
                  : itemsToDisplay.isEmpty 
                      ? _emptyStateDashboard() 
                      : ListView.builder(
                          controller: _scrollController, 
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.only(bottom: 100, top: 8), 
                          itemCount: itemsToDisplay.length + (hasMoreData ? 1 : 0), 
                          itemBuilder: (c, i) {
                            if (i == itemsToDisplay.length) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 24),
                                child: Center(child: CircularProgressIndicator(color: primaryBlue)),
                              );
                            }
                            return _itemCard(context, itemsToDisplay[i]);
                          },
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
    ImageProvider? safeImg = _getSafeImage(item['image']);
    
    String statusStr = item['status']?.toString().toLowerCase() ?? '';
    bool isAvailable = statusStr == 'available';
    bool isBorrowed = statusStr == 'borrowed';

    Color badgeBgColor = isAvailable ? Colors.green.shade50 : (isBorrowed ? Colors.orange.shade50 : Colors.red.shade50);
    Color badgeBorderColor = isAvailable ? Colors.green.shade200 : (isBorrowed ? Colors.orange.shade200 : Colors.red.shade200);
    Color badgeTextColor = isAvailable ? Colors.green.shade700 : (isBorrowed ? Colors.orange.shade700 : Colors.red.shade700);

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
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: bgGray,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderGrey, width: 1), 
                image: safeImg != null 
                  ? DecorationImage(image: safeImg, fit: BoxFit.cover) 
                  : null,
              ),
              child: safeImg == null ? const Icon(Icons.image_outlined, size: 32, color: textLight) : null,
            ),
            const SizedBox(width: 16),
            
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
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: badgeBgColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: badgeBorderColor, width: 1),
                        ),
                        child: Text(
                          item['status'],
                          style: TextStyle(
                            color: badgeTextColor, 
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
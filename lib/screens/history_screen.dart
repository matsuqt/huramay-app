// lib/screens/history_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

import '../globals.dart';
import '../widgets/app_sidebar.dart';
import 'auth_screens.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List historyItems = [];
  bool isLoading = true;
  String? _currentFilter;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    if (currentUser == null) return;
    setState(() => isLoading = true);
    try {
      final res = await http.get(
        Uri.parse('http://10.174.134.39:5000/api/borrow/history/${currentUser!['id']}'),
      );
      if (res.statusCode == 200) {
        setState(() {
          historyItems = jsonDecode(res.body);
        });
      }
    } catch (e) {
      debugPrint("History Fetch Error: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
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
          child: const TextField(
            decoration: InputDecoration(
              hintText: "Search history...",
              prefixIcon: Icon(Icons.search),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (c) => const ProfileScreen()),
            ),
            icon: const Icon(Icons.account_circle, size: 30),
          )
        ],
      ),
      
      drawer: const AppSidebar(),
      
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "History",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A0088),
                  ),
                ),
                Row(
                  children: [
                    const Text("Filters ", style: TextStyle(fontSize: 12, color: Colors.black54)),
                    Container(
                      height: 35,
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _currentFilter,
                          hint: const Text("All", style: TextStyle(fontSize: 12, color: Colors.black)),
                          icon: const Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.black),
                          items: ['Pending', 'Accepted', 'Declined', 'Returned'].map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value, style: const TextStyle(fontSize: 12)),
                            );
                          }).toList(),
                          onChanged: (newValue) {
                            setState(() => _currentFilter = newValue);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : historyItems.isEmpty
                    ? const Center(
                        child: Text(
                          "No Borrowing History Found",
                          style: TextStyle(color: Colors.grey, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      )
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: historyItems.length,
                        itemBuilder: (c, i) => _HistoryCard(historyData: historyItems[i]),
                      ),
          ),
        ],
      ),
    );
  }
}

// =======================================================================
// UPDATED: Modernized UI Match for the History Card
// =======================================================================
class _HistoryCard extends StatelessWidget {
  final dynamic historyData;
  const _HistoryCard({required this.historyData});

  @override
  Widget build(BuildContext context) {
    dynamic item = historyData['item'] ?? {}; 
    String? imgPath = item['image'];
    bool hasImage = imgPath != null && imgPath.isNotEmpty;
    
    String currentStatus = historyData['status']?.toString() ?? 'Pending';
    
    // Dynamic color system for the Status Pill
    Color statusColor;
    Color statusBgColor;
    
    if (currentStatus.toLowerCase() == 'returned') {
      statusColor = Colors.green;
      statusBgColor = Colors.green.shade50;
    } else if (currentStatus.toLowerCase() == 'pending') {
      statusColor = Colors.orange;
      statusBgColor = Colors.orange.shade50;
    } else if (currentStatus.toLowerCase() == 'declined') {
      statusColor = Colors.red;
      statusBgColor = Colors.red.shade50;
    } else if (currentStatus.toLowerCase() == 'accepted') {
      statusColor = Colors.blue;
      statusBgColor = Colors.blue.shade50;
    } else {
      statusColor = const Color(0xFF1A0088);
      statusBgColor = Colors.blue.shade50;
    }

    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => HistoryDetailOverlay(historyData: historyData),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6), // Modern Dashboard Grey
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.black12, width: 1),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 5, offset: const Offset(0, 3))]
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left: Clean White Image Box
            Container(
              width: 85,
              height: 85,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: statusColor, width: 1.5), // Colored border matches the status!
                image: hasImage ? DecorationImage(image: FileImage(File(imgPath!)), fit: BoxFit.cover) : null,
              ),
              child: !hasImage ? const Icon(Icons.image, size: 30, color: Colors.grey) : null,
            ),
            const SizedBox(width: 15),
            
            // Right: Details and Status Pill
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
                          item['owner'] ?? "Unknown Owner",
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A0088), fontSize: 13),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 5),
                      // Modern Dynamic Status Pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusBgColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: statusColor, width: 1),
                        ),
                        child: Text(
                          currentStatus,
                          style: TextStyle(
                            color: statusColor, 
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
                    item['title'] ?? "Untitled Item",
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  
                  // Row 3: Department
                  Text(
                    item['dept'] ?? "No Department",
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  
                  // Row 4: Helper Text docked at bottom
                  const Text(
                    "Tap to view details & reviews", 
                    style: TextStyle(fontSize: 10, color: Colors.grey, fontStyle: FontStyle.italic)
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

class HistoryDetailOverlay extends StatefulWidget {
  final dynamic historyData;
  const HistoryDetailOverlay({super.key, required this.historyData});

  @override
  State<HistoryDetailOverlay> createState() => _HistoryDetailOverlayState();
}

class _HistoryDetailOverlayState extends State<HistoryDetailOverlay> {
  final TextEditingController _reviewTextCtrl = TextEditingController();
  
  bool isSubmitting = false;
  bool _showReviewForm = false; 
  int _rating = 5; 

  List<dynamic> _realReviews = [];
  bool _isLoadingReviews = true;

  @override
  void initState() {
    super.initState();
    _fetchItemReviews();
  }

  Future<void> _fetchItemReviews() async {
    try {
      int itemId = widget.historyData['item']['id'];
      final res = await http.get(Uri.parse('http://10.174.134.39:5000/api/reviews/item/$itemId'));

      if (res.statusCode == 200) {
        if (mounted) {
          setState(() {
            _realReviews = jsonDecode(res.body);
            _isLoadingReviews = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Fetch reviews error: $e");
      if (mounted) setState(() => _isLoadingReviews = false);
    }
  }

  Future<void> _submitReviewToBackend() async {
    if (_reviewTextCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please write a review first.")));
      return;
    }

    setState(() => isSubmitting = true);
    try {
      final res = await http.post(
        Uri.parse('http://10.174.134.39:5000/api/review'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'reviewer_id': currentUser!['id'],
          'item_id': widget.historyData['item']['id'],
          'lender_id': widget.historyData['item']['user_id'], 
          'rating': _rating,
          'review_text': _reviewTextCtrl.text.trim()
        }),
      );
      
      if (res.statusCode == 201) {
        if (mounted) {
          setState(() {
            _showReviewForm = false;
            _reviewTextCtrl.clear();
            _rating = 5;
            _isLoadingReviews = true; 
          });
          _fetchItemReviews(); 
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Review submitted successfully!")));
        }
      }
    } catch (e) {
      debugPrint("Review Submission Error: $e");
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  Widget _buildMiniStars(int rating) {
    return Row(
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          color: Colors.amber, 
          size: 14,
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    dynamic item = widget.historyData['item'] ?? {};
    String? imgPath = item['image'];
    bool hasImage = imgPath != null && imgPath.isNotEmpty;
    bool isReturned = widget.historyData['status']?.toString().toLowerCase() == 'returned';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 0.85, 
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5))]
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
            
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 100, height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: const Color(0xFF1A0088), width: 3),
                        image: hasImage ? DecorationImage(image: FileImage(File(imgPath!)), fit: BoxFit.cover) : null,
                      ),
                      child: !hasImage ? const Icon(Icons.image, size: 40, color: Colors.grey) : null,
                    ),
                    const SizedBox(height: 15),

                    Text(item['title'] ?? "Untitled", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
                    Text("Owned by: ${item['owner']}", style: const TextStyle(color: Color(0xFF1A0088), fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 10),
                    
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(10)),
                      child: Column(
                        children: [
                          _detailRow("Borrow Date:", widget.historyData['start_date'] ?? "N/A"),
                          const SizedBox(height: 5),
                          _detailRow("Return Date:", widget.historyData['end_date'] ?? "N/A"),
                          const SizedBox(height: 5),
                          _detailRow("Status:", widget.historyData['status'] ?? "N/A", isStatus: true),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    const Divider(color: Colors.black12, thickness: 1),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Item Reviews", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
                        
                        if (isReturned && !_showReviewForm)
                          ElevatedButton.icon(
                            onPressed: () => setState(() => _showReviewForm = true),
                            icon: const Icon(Icons.rate_review, size: 14),
                            label: const Text("Add Review", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.yellow,
                              foregroundColor: Colors.black,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                              minimumSize: const Size(0, 30)
                            ),
                          )
                      ],
                    ),
                    const SizedBox(height: 10),

                    if (_showReviewForm) ...[
                      Container(
                        padding: const EdgeInsets.all(15),
                        margin: const EdgeInsets.only(bottom: 15),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: const Color(0xFF1A0088), width: 1.5)
                        ),
                        child: Column(
                          children: [
                            const Text("Rate your experience", style: TextStyle(color: Color(0xFF1A0088), fontWeight: FontWeight.bold, fontSize: 14)),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(5, (index) {
                                return IconButton(
                                  icon: Icon(index < _rating ? Icons.star : Icons.star_border, color: Colors.amber, size: 30),
                                  onPressed: () => setState(() => _rating = index + 1),
                                );
                              }),
                            ),
                            Container(
                              decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.black12)),
                              child: TextField(
                                controller: _reviewTextCtrl,
                                maxLines: 2,
                                decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.all(10), hintText: "Write your review...", hintStyle: TextStyle(color: Colors.black38, fontSize: 12)),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => setState(() => _showReviewForm = false),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red,
                                      side: const BorderSide(color: Colors.red),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                    ),
                                    child: const Text("Cancel"),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: isSubmitting 
                                    ? const Center(child: CircularProgressIndicator())
                                    : ElevatedButton(
                                        onPressed: _submitReviewToBackend,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF1A0088),
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                        ),
                                        child: const Text("Submit"),
                                      ),
                                ),
                              ],
                            )
                          ],
                        ),
                      )
                    ],

                    _isLoadingReviews
                      ? const Padding(
                          padding: EdgeInsets.all(20),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : _realReviews.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Text("No reviews yet. Be the first to share your experience!", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(), 
                              itemCount: _realReviews.length,
                              itemBuilder: (context, index) {
                                final review = _realReviews[index];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(color: Colors.black12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      CircleAvatar(
                                        radius: 16,
                                        backgroundColor: const Color(0xFF1A0088),
                                        child: Text(
                                          review['reviewer_name'].isNotEmpty ? review['reviewer_name'][0].toUpperCase() : '?', 
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(review['reviewer_name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                                Text(review['date'], style: const TextStyle(color: Colors.black54, fontSize: 10)),
                                              ],
                                            ),
                                            const SizedBox(height: 2),
                                            _buildMiniStars(review['rating']),
                                            const SizedBox(height: 6),
                                            Text(
                                              review['comment'],
                                              style: const TextStyle(fontSize: 12, color: Colors.black87, height: 1.3),
                                            )
                                          ],
                                        ),
                                      )
                                    ],
                                  ),
                                );
                              },
                            ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, {bool isStatus = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.black54, fontWeight: FontWeight.w600)),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isStatus ? const Color(0xFF1A0088) : Colors.black87)),
      ],
    );
  }
}
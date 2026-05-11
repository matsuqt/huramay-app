// lib/screens/history_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

import '../globals.dart';
import '../widgets/app_sidebar.dart';
import 'auth_screens.dart';

// ==================== SHARED DESIGN CONSTANTS ====================
const Color primaryBlue = Color(0xFF1A0088);
const Color accentYellow = Color(0xFFFFD700);
const Color textDark = Color(0xFF1F2937);
const Color textLight = Color(0xFF6B7280);
const Color borderGrey = Color(0xFFE5E7EB);
const Color bgGray = Color(0xFFF8FAFC);

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
        Uri.parse('http://192.168.137.1:5000/api/borrow/history/${currentUser!['id']}'),
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
      backgroundColor: bgGray,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: primaryBlue), // Dark blue menu icon
        title: Container(
          height: 40,
          decoration: BoxDecoration(color: bgGray, borderRadius: BorderRadius.circular(8), border: Border.all(color: primaryBlue.withOpacity(0.1))), // Subtle blue tint to border
          child: const TextField(
            style: TextStyle(fontSize: 14, color: textDark),
            decoration: InputDecoration(
              hintText: "Search history...",
              hintStyle: TextStyle(color: textLight, fontSize: 14),
              prefixIcon: Icon(Icons.search, color: primaryBlue, size: 20), // Dark blue search icon
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (c) => const ProfileScreen()),
            ),
            icon: const Icon(Icons.account_circle_outlined, size: 28, color: primaryBlue), // Dark blue profile icon
          )
        ],
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(color: borderGrey, height: 1)),
      ),
      
      drawer: const AppSidebar(),
      
      body: Stack(
        children: [
          // Background Geometry - Sneaking the colors back in!
          Positioned(
            top: -80, right: -60, 
            child: Container(width: 250, height: 250, decoration: BoxDecoration(shape: BoxShape.circle, color: primaryBlue.withOpacity(0.04)))
          ),
          Positioned(
            bottom: 100, left: -80, 
            child: Container(width: 200, height: 200, decoration: BoxDecoration(shape: BoxShape.circle, color: accentYellow.withOpacity(0.06)))
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
                      "History",
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: primaryBlue, letterSpacing: -0.5), // Heavy Dark Blue Header
                    ),
                    Row(
                      children: [
                        const Text("Filters ", style: TextStyle(fontSize: 12, color: textLight, fontWeight: FontWeight.w600)),
                        Container(
                          height: 32,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(color: Colors.white, border: Border.all(color: borderGrey), borderRadius: BorderRadius.circular(16)),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _currentFilter,
                              hint: const Text("All", style: TextStyle(fontSize: 13, color: textDark, fontWeight: FontWeight.w600)),
                              icon: const Icon(Icons.keyboard_arrow_down, size: 16, color: primaryBlue), // Dark blue arrow
                              alignment: Alignment.centerRight,
                              items: ['Pending', 'Accepted', 'Declined', 'Returned'].map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value, style: const TextStyle(fontSize: 13, color: textDark, fontWeight: FontWeight.w600)),
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
                    ? const Center(child: CircularProgressIndicator(color: primaryBlue))
                    : historyItems.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: borderGrey)),
                                  child: const Icon(Icons.history, size: 48, color: textLight),
                                ),
                                const SizedBox(height: 24),
                                const Text("No Borrowing History Found", style: TextStyle(color: textLight, fontSize: 16, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          )
                        : ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.only(bottom: 24),
                            itemCount: historyItems.length,
                            itemBuilder: (c, i) => _HistoryCard(historyData: historyItems[i]),
                          ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final dynamic historyData;
  const _HistoryCard({required this.historyData});

  @override
  Widget build(BuildContext context) {
    dynamic item = historyData['item'] ?? {}; 
    String? imgPath = item['image'];
    bool hasImage = imgPath != null && imgPath.isNotEmpty;
    
    String currentStatus = historyData['status']?.toString() ?? 'Pending';
    
    Color statusColor;
    Color statusBgColor;
    
    if (currentStatus.toLowerCase() == 'returned') {
      statusColor = Colors.green.shade700;
      statusBgColor = Colors.green.shade50;
    } else if (currentStatus.toLowerCase() == 'pending') {
      statusColor = Colors.orange.shade700;
      statusBgColor = Colors.orange.shade50;
    } else if (currentStatus.toLowerCase() == 'declined') {
      statusColor = Colors.red.shade700;
      statusBgColor = Colors.red.shade50;
    } else if (currentStatus.toLowerCase() == 'accepted') {
      statusColor = primaryBlue;
      statusBgColor = primaryBlue.withOpacity(0.1);
    } else {
      statusColor = textLight;
      statusBgColor = bgGray;
    }

    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => HistoryDetailOverlay(historyData: historyData),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderGrey, width: 1),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))]
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: bgGray,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderGrey, width: 1), 
                image: hasImage ? DecorationImage(image: FileImage(File(imgPath!)), fit: BoxFit.cover) : null,
              ),
              child: !hasImage ? const Icon(Icons.image_outlined, size: 32, color: textLight) : null,
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
                          item['owner'] ?? "Unknown Owner",
                          style: const TextStyle(fontWeight: FontWeight.w700, color: primaryBlue, fontSize: 13), // Dark blue owner name
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusBgColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: statusColor.withOpacity(0.3), width: 1),
                        ),
                        child: Text(
                          currentStatus,
                          style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 0.5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  
                  Text(
                    item['title'] ?? "Untitled Item",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDark, height: 1.2),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  
                  Text(
                    item['dept'] ?? "No Department",
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: textLight),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  
                  const Text(
                    "Tap to view details & reviews", 
                    style: TextStyle(fontSize: 11, color: textLight, fontWeight: FontWeight.w600, fontStyle: FontStyle.italic)
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
      final res = await http.get(Uri.parse('http://192.168.137.1:5000/api/reviews/item/$itemId'));

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
        Uri.parse('http://192.168.137.1:5000/api/review'),
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
          color: accentYellow, // Yellow stars!
          size: 16,
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
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 0.85, 
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))]
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("History Details", style: TextStyle(color: primaryBlue, fontWeight: FontWeight.w900, fontSize: 20)), // Dark blue overlay title
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: bgGray, shape: BoxShape.circle, border: Border.all(color: borderGrey)),
                    child: const Icon(Icons.close, size: 18, color: textLight), 
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 120, height: 120,
                      decoration: BoxDecoration(
                        color: bgGray, borderRadius: BorderRadius.circular(16), border: Border.all(color: primaryBlue.withOpacity(0.2), width: 2), // Subtle blue border around image
                        image: hasImage ? DecorationImage(image: FileImage(File(imgPath!)), fit: BoxFit.cover) : null,
                      ),
                      child: !hasImage ? const Icon(Icons.image_outlined, size: 40, color: textLight) : null,
                    ),
                    const SizedBox(height: 16),

                    Text(item['title'] ?? "Untitled", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: textDark, letterSpacing: -0.5)),
                    const SizedBox(height: 4),
                    Text("Owned by: ${item['owner']}", style: const TextStyle(color: primaryBlue, fontWeight: FontWeight.w700, fontSize: 14)), // Dark blue owner name
                    const SizedBox(height: 24),
                    
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: bgGray, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderGrey)),
                      child: Column(
                        children: [
                          _detailRow("Borrow Date:", widget.historyData['start_date'] ?? "N/A"),
                          const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1, color: borderGrey)),
                          _detailRow("Return Date:", widget.historyData['end_date'] ?? "N/A"),
                          const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1, color: borderGrey)),
                          _detailRow("Status:", widget.historyData['status'] ?? "N/A", isStatus: true),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Item Reviews", style: TextStyle(color: primaryBlue, fontWeight: FontWeight.w800, fontSize: 18)), // Dark blue section header
                        
                        if (isReturned && !_showReviewForm)
                          ElevatedButton.icon(
                            onPressed: () => setState(() => _showReviewForm = true),
                            icon: const Icon(Icons.rate_review_outlined, size: 16),
                            label: const Text("Add Review", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accentYellow, // Bright yellow button!
                              foregroundColor: textDark,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                              minimumSize: const Size(0, 36)
                            ),
                          )
                      ],
                    ),
                    const SizedBox(height: 16),

                    if (_showReviewForm) ...[
                      Container(
                        padding: const EdgeInsets.all(20),
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          color: bgGray,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: primaryBlue.withOpacity(0.3)) // Subtle blue border
                        ),
                        child: Column(
                          children: [
                            const Text("Rate your experience", style: TextStyle(color: primaryBlue, fontWeight: FontWeight.w700, fontSize: 15)),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(5, (index) {
                                return IconButton(
                                  icon: Icon(index < _rating ? Icons.star : Icons.star_border, color: accentYellow, size: 36),
                                  onPressed: () => setState(() => _rating = index + 1),
                                );
                              }),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderGrey)),
                              child: TextField(
                                controller: _reviewTextCtrl,
                                maxLines: 3,
                                style: const TextStyle(fontSize: 14, color: textDark),
                                decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.all(16), hintText: "Write your review...", hintStyle: TextStyle(color: textLight, fontSize: 14)),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: TextButton(
                                    onPressed: () => setState(() => _showReviewForm = false),
                                    style: TextButton.styleFrom(
                                      foregroundColor: textDark,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    child: const Text("Cancel", style: TextStyle(fontWeight: FontWeight.w600)),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: isSubmitting 
                                    ? const Center(child: CircularProgressIndicator(color: primaryBlue))
                                    : ElevatedButton(
                                        onPressed: _submitReviewToBackend,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: primaryBlue, // Dark blue submit
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                        child: const Text("Submit", style: TextStyle(fontWeight: FontWeight.w600)),
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
                          padding: EdgeInsets.all(32),
                          child: Center(child: CircularProgressIndicator(color: primaryBlue)),
                        )
                      : _realReviews.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 32),
                              child: Text("No reviews yet. Be the first to share your experience!", textAlign: TextAlign.center, style: TextStyle(color: textLight, fontStyle: FontStyle.italic, fontSize: 14)),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(), 
                              itemCount: _realReviews.length,
                              itemBuilder: (context, index) {
                                final review = _realReviews[index];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(color: borderGrey),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))]
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      CircleAvatar(
                                        radius: 18,
                                        backgroundColor: primaryBlue.withOpacity(0.1), // Blue tinted avatar
                                        child: Text(
                                          review['reviewer_name'].isNotEmpty ? review['reviewer_name'][0].toUpperCase() : '?', 
                                          style: const TextStyle(color: primaryBlue, fontWeight: FontWeight.w900, fontSize: 14)
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(review['reviewer_name'], style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: textDark)),
                                                Text(review['date'], style: const TextStyle(color: textLight, fontSize: 11, fontWeight: FontWeight.w500)),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            _buildMiniStars(review['rating']),
                                            const SizedBox(height: 8),
                                            Text(
                                              review['comment'],
                                              style: const TextStyle(fontSize: 14, color: textDark, height: 1.4),
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
        Text(label, style: const TextStyle(fontSize: 14, color: textLight, fontWeight: FontWeight.w500)),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: isStatus ? primaryBlue : textDark)),
      ],
    );
  }
}
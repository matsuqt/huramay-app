// lib/screens/reports_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import '../widgets/app_sidebar.dart';
import 'auth_screens.dart'; // Added to enable ProfileScreen routing

// ==================== SHARED DESIGN CONSTANTS ====================
const Color primaryBlue = Color(0xFF1A0088);
const Color accentYellow = Color(0xFFFFD700);
const Color textDark = Color(0xFF1F2937);
const Color textLight = Color(0xFF6B7280);
const Color borderGrey = Color(0xFFE5E7EB);
const Color bgGray = Color(0xFFF8FAFC);

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  List<dynamic> allReports = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAllReports();
  }

  Future<void> _fetchAllReports() async {
    try {
      final res = await http.get(Uri.parse('https://huramay-app.onrender.com/api/reports/all'));
      if (res.statusCode == 200) {
        if (mounted) {
          setState(() {
            allReports = jsonDecode(res.body);
            isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Reports fetch error: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  // ==================== MODERNIZED REPORT DETAIL MODAL ====================
  void _openReportDetails(dynamic report) {
    String? imgPath = report['item_image'];
    bool hasImage = imgPath != null && imgPath.isNotEmpty;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white, 
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))]
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Report Details", style: TextStyle(color: primaryBlue, fontWeight: FontWeight.w900, fontSize: 18)),
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
              
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: bgGray,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: primaryBlue.withOpacity(0.2), width: 2),
                  image: hasImage ? DecorationImage(image: FileImage(File(imgPath!)), fit: BoxFit.cover) : null,
                ),
                child: !hasImage ? const Icon(Icons.image_outlined, size: 40, color: textLight) : null,
              ),
              const SizedBox(height: 24),
              
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: bgGray, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderGrey)),
                child: Column(
                  children: [
                    _modalText("Item Name", report['item_title']),
                    const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1, color: borderGrey)),
                    _modalText("Reporter", report['reporter_name']),
                    const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1, color: borderGrey)),
                    _modalText("Department", report['reporter_dept']),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade100)
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Report Reason", style: TextStyle(fontWeight: FontWeight.w800, color: Colors.red.shade700, fontSize: 13)),
                    const SizedBox(height: 6),
                    Text(
                      report['report_text'] ?? "No report details provided.",
                      style: TextStyle(fontSize: 14, color: Colors.red.shade900, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _modalText(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: textLight, fontWeight: FontWeight.w600)),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: textDark),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgGray,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: primaryBlue),
        title: Container(
          height: 40,
          decoration: BoxDecoration(color: bgGray, borderRadius: BorderRadius.circular(8), border: Border.all(color: primaryBlue.withOpacity(0.1))),
          child: const TextField(
            textAlignVertical: TextAlignVertical.center,
            decoration: InputDecoration(
              hintText: "Search reports...",
              hintStyle: TextStyle(color: textLight, fontSize: 14),
              prefixIcon: Icon(Icons.search, color: primaryBlue, size: 20),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const ProfileScreen())), 
            icon: const Icon(Icons.account_circle_outlined, size: 28, color: primaryBlue)
          )
        ],
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(color: borderGrey, height: 1)),
      ),
      drawer: const AppSidebar(),
      body: Stack(
        children: [
          // The Signature Background Geometry
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
              const Padding(
                padding: EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Text(
                  "Flag Reports",
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: primaryBlue, letterSpacing: -0.5),
                ),
              ),
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator(color: primaryBlue))
                    : allReports.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: borderGrey)),
                                  child: const Icon(Icons.gpp_good_outlined, size: 48, color: textLight),
                                ),
                                const SizedBox(height: 24),
                                const Text("No reports found. All clear!", style: TextStyle(color: textLight, fontSize: 16, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          )
                        : ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.only(bottom: 24),
                            itemCount: allReports.length,
                            itemBuilder: (context, index) => _buildReportCard(allReports[index]),
                          ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== MODERNIZED REPORT LIST CARD ====================
  Widget _buildReportCard(dynamic report) {
    String? imgPath = report['item_image'];
    bool hasImage = imgPath != null && imgPath.isNotEmpty;

    return GestureDetector(
      onTap: () => _openReportDetails(report),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.shade100, width: 1), // Subtle red warning border
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))]
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
                image: hasImage ? DecorationImage(image: FileImage(File(imgPath!)), fit: BoxFit.cover) : null,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (!hasImage) const Icon(Icons.image_outlined, size: 32, color: textLight),
                  // Subtle red warning tint over the image
                  Container(
                    width: double.infinity, height: double.infinity,
                    decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(11)),
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
                    children: [
                      Expanded(
                        child: Text(
                          report['item_title'] ?? "Unknown Item",
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDark, height: 1.2),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 18),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Text("By: ", style: TextStyle(color: textLight, fontSize: 12, fontWeight: FontWeight.w600)),
                      Expanded(
                        child: Text(
                          report['reporter_name'] ?? "Unknown", 
                          style: const TextStyle(fontWeight: FontWeight.w800, color: primaryBlue, fontSize: 12),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    report['reporter_dept'] ?? "Unknown Department", 
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: textLight),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    report['report_text'] ?? "No report details provided.",
                    style: const TextStyle(fontSize: 13, color: textDark, fontStyle: FontStyle.italic),
                    maxLines: 2, overflow: TextOverflow.ellipsis,
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
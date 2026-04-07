// lib/screens/reports_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

import '../globals.dart';
import '../widgets/app_sidebar.dart';

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
      // Using $baseUrl to ensure it connects to your active server!
      final res = await http.get(Uri.parse('$baseUrl/api/reports/all'));
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
        insetPadding: const EdgeInsets.all(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white, // Clean white background
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5))]
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Modern Close Button
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
              const SizedBox(height: 10),
              
              // Image Box
              Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: const Color(0xFF1A0088), width: 2),
                  image: hasImage ? DecorationImage(image: FileImage(File(imgPath!)), fit: BoxFit.cover) : null,
                ),
                child: !hasImage ? const Icon(Icons.image, size: 40, color: Colors.grey) : null,
              ),
              const SizedBox(height: 25),
              
              _modalText("Item Name", report['item_title']),
              _modalText("Reporter Name", report['reporter_name']),
              _modalText("Department", report['reporter_dept']),
              const Divider(color: Colors.black12, height: 30, thickness: 1),
              _modalText("Review Report", report['report_text'], isSmall: true),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _modalText(String label, String value, {bool isSmall = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A0088), fontSize: 13)),
          const SizedBox(height: 3),
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isSmall ? 13 : 15,
              fontWeight: isSmall ? FontWeight.normal : FontWeight.bold,
              color: Colors.black87,
              fontStyle: isSmall ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A0088),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Container(
          height: 35,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
          child: const TextField(
            textAlignVertical: TextAlignVertical.center,
            decoration: InputDecoration(
              hintText: "Search reports...",
              prefixIcon: Icon(Icons.search, color: Colors.grey),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.account_circle, size: 30))
        ],
      ),
      drawer: const AppSidebar(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              "Reports Page",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1A0088)),
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF1A0088)))
                : allReports.isEmpty
                    ? const Center(child: Text("No reviews found.", style: TextStyle(color: Colors.grey, fontSize: 18, fontWeight: FontWeight.bold)))
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: allReports.length,
                        itemBuilder: (context, index) => _buildReportCard(allReports[index]),
                      ),
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
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6), // Unified grey card matching Dashboard
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
                border: Border.all(color: const Color(0xFF1A0088), width: 1.5),
                image: hasImage ? DecorationImage(image: FileImage(File(imgPath!)), fit: BoxFit.cover) : null,
              ),
              child: !hasImage ? const Icon(Icons.image, size: 30, color: Colors.grey) : null,
            ),
            const SizedBox(width: 15),
            
            // Right: Text Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    report['item_title'] ?? "Unknown Item",
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "By: ${report['reporter_name']}", 
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A0088), fontSize: 12)
                  ),
                  Text(
                    report['reporter_dept'] ?? "Unknown Department", 
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black54)
                  ),
                  const SizedBox(height: 10),
                  Text(
                    report['report_text'] ?? "No report details provided.",
                    style: const TextStyle(fontSize: 12, color: Colors.black87, fontStyle: FontStyle.italic),
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
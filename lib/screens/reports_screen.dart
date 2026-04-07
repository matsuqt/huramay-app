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
      final res = await http.get(Uri.parse('http://10.174.134.39:5000/api/reports/all'));
      if (res.statusCode == 200) {
        setState(() {
          allReports = jsonDecode(res.body);
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Reports fetch error: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  // TICKET VAVT-63: Enlarge the display just like the other page
  void _openReportDetails(dynamic report) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFCCCCCC), // Grey background to match Figma style
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const CircleAvatar(
                    backgroundColor: Color(0xFFFDEB00),
                    radius: 15,
                    child: Icon(Icons.arrow_back_ios_new, size: 15, color: Colors.black),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Enlarged Image
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: const Color(0xFF1A0088), width: 3),
                  image: report['item_image'] != null && report['item_image'].isNotEmpty
                      ? DecorationImage(image: FileImage(File(report['item_image'])), fit: BoxFit.cover)
                      : null,
                ),
                child: report['item_image'] == null || report['item_image'].isEmpty 
                    ? const Icon(Icons.image, size: 60, color: Colors.grey) : null,
              ),
              const SizedBox(height: 15),
              _modalText("Item", report['item_title']),
              _modalText("Reporter Name", report['reporter_name']),
              _modalText("Department", report['reporter_dept']),
              _modalText("Review Report", report['report_text'], isSmall: true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _modalText(String label, String value, {bool isSmall = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A0088), fontSize: 13)),
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isSmall ? 12 : 14,
              fontWeight: FontWeight.bold,
              color: Colors.black,
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
        iconTheme: const IconThemeData(color: Colors.white),
        title: Container(
          height: 35,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
          child: const TextField(
            decoration: InputDecoration(
              hintText: "Search reports...",
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
      drawer: const AppSidebar(), // Uses standard side menu
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
                ? const Center(child: CircularProgressIndicator())
                : allReports.isEmpty
                    ? const Center(child: Text("No reviews found.", style: TextStyle(color: Colors.grey, fontSize: 18)))
                    : ListView.builder(
                        itemCount: allReports.length,
                        itemBuilder: (context, index) => _buildReportCard(allReports[index]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(dynamic report) {
    String? imgPath = report['item_image'];
    bool hasImage = imgPath != null && imgPath.isNotEmpty;

    return GestureDetector(
      onTap: () => _openReportDetails(report),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image Box
              Container(
                width: 110,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF1A0088), width: 2),
                  image: hasImage ? DecorationImage(image: FileImage(File(imgPath)), fit: BoxFit.cover) : null,
                ),
                child: !hasImage ? const Icon(Icons.image, size: 40, color: Colors.grey) : null,
              ),
              const SizedBox(width: 10),
              // Review Details Box
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
                    children: [
                      Text(
                        report['item_title'],
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      Text("By: ${report['reporter_name']}", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A0088), fontSize: 12)),
                      Text(report['reporter_dept'], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black54)),
                      const SizedBox(height: 8),
                      Text(
                        report['report_text'],
                        style: const TextStyle(fontSize: 12, color: Colors.black),
                        maxLines: 2, overflow: TextOverflow.ellipsis,
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
}
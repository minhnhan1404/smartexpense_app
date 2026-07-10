import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smartexpense_app/api_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' show Platform;

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  bool isLoading = true;
  String errorMessage = '';

  List<dynamic> categoryStats = [];
  List<dynamic> monthlyStats = [];
  double totalExpense = 0.0;
  double totalIncome = 0.0;

  @override
  void initState() {
    super.initState();
    fetchStatistics();
  }


  Future<void> fetchStatistics() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await http.get(
        Uri.parse(ApiConfig.getUrl('statistics')),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            categoryStats = data['data']['category_stats'] ?? [];
            monthlyStats = data['data']['monthly_stats'] ?? [];
            
            totalExpense = 0.0;
            totalIncome = 0.0;
            for (var c in categoryStats) {
               if (c['type'] == 'expense') {
                  totalExpense += double.tryParse(c['total'].toString()) ?? 0.0;
               } else {
                  totalIncome += double.tryParse(c['total'].toString()) ?? 0.0;
               }
            }

            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage = 'Lỗi kết nối máy chủ: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Lỗi không thể gọi API: $e';
        isLoading = false;
      });
    }
  }

  String formatVND(double amount) {
    return '${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'\\B(?=(\\d{3})+(?!\\d))'), (match) => '.')} đ';
  }

  Color _hexToColor(String code) {
    return Color(int.parse(code.substring(1, 7), radix: 16) + 0xFF000000);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Analytics',
          style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5)))
            : errorMessage.isNotEmpty
                ? Center(child: Text(errorMessage, style: const TextStyle(color: Colors.red)))
                : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tổng Thu/Chi tháng này
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Income', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                      const SizedBox(height: 8),
                      Text(formatVND(totalIncome), style: const TextStyle(color: Color(0xFF10B981), fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Container(width: 1, height: 40, color: Colors.grey.shade200),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Expense', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                      const SizedBox(height: 8),
                      Text(formatVND(totalExpense), style: const TextStyle(color: Color(0xFFEF4444), fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Biểu đồ Pie Chart (Danh mục chi tiêu)
          const Text('Expenses by Category', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: categoryStats.isEmpty
              ? const Center(child: Text("Không có dữ liệu"))
              : SizedBox(
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 60,
                      sections: categoryStats
                          .where((c) => c['type'] == 'expense' && double.parse(c['total'].toString()) > 0)
                          .map((cat) {
                        return PieChartSectionData(
                          color: _hexToColor(cat['color'] ?? '#4F46E5'),
                          value: double.tryParse(cat['total'].toString()) ?? 0,
                          title: '',
                          radius: 30,
                        );
                      }).toList(),
                    ),
                  ),
                ),
          ),
          const SizedBox(height: 32),
          
          // Chú thích
          Wrap(
            spacing: 16,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: categoryStats
                .where((c) => c['type'] == 'expense' && double.parse(c['total'].toString()) > 0)
                .map((cat) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12, height: 12,
                    decoration: BoxDecoration(color: _hexToColor(cat['color'] ?? '#4F46E5'), shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Text(cat['name'], style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                ],
              );
            }).toList(),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

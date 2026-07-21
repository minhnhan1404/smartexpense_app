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
          if (mounted) {
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
        }
      } else {
        if (mounted) {
          setState(() {
            errorMessage = 'Lỗi kết nối máy chủ: ${response.statusCode}';
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'Lỗi không thể gọi API: $e';
          isLoading = false;
        });
      }
    }
  }

  String formatVND(double amount) {
    return '${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'\\B(?=(\\d{3})+(?!\\d))'), (match) => '.')} ₫';
  }

  Color _hexToColor(String code) {
    return Color(int.parse(code.substring(1, 7), radix: 16) + 0xFF000000);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          'Thống kê',
          style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF0F172A)))
            : errorMessage.isNotEmpty
                ? _buildErrorScreen()
                : _buildContent(),
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
          const SizedBox(height: 16),
          Text(errorMessage, style: const TextStyle(color: Colors.redAccent)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: fetchStatistics,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A)),
            child: const Text('Thử lại', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  Widget _buildContent() {
    bool hasExpense = totalExpense > 0;

    return RefreshIndicator(
      onRefresh: fetchStatistics,
      color: const Color(0xFF0F172A),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tổng Thu/Chi tháng này (Premium Card)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withOpacity(0.04),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.1), shape: BoxShape.circle),
                              child: const Icon(Icons.arrow_downward, color: Color(0xFF10B981), size: 14),
                            ),
                            const SizedBox(width: 8),
                            const Text('Tổng Thu', style: TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(formatVND(totalIncome), style: const TextStyle(color: Color(0xFF10B981), fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 50, color: Colors.grey.shade200),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(color: const Color(0xFFEF4444).withOpacity(0.1), shape: BoxShape.circle),
                              child: const Icon(Icons.arrow_upward, color: Color(0xFFEF4444), size: 14),
                            ),
                            const SizedBox(width: 8),
                            const Text('Tổng Chi', style: TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(formatVND(totalExpense), style: const TextStyle(color: Color(0xFF0F172A), fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Biểu đồ Pie Chart (Danh mục chi tiêu)
            const Text('Chi tiêu theo danh mục', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withOpacity(0.04),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: !hasExpense
                ? Center(
                    child: Column(
                      children: [
                        Icon(Icons.pie_chart_outline, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text("Chưa có dữ liệu chi tiêu trong tháng này", style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      SizedBox(
                        height: 200,
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 4,
                            centerSpaceRadius: 50,
                            sections: categoryStats
                                .where((c) => c['type'] == 'expense' && double.parse(c['total'].toString()) > 0)
                                .map((cat) {
                              return PieChartSectionData(
                                color: _hexToColor(cat['color'] ?? '#0F172A'),
                                value: double.tryParse(cat['total'].toString()) ?? 0,
                                title: '',
                                radius: 40,
                                badgeWidget: _Badge(
                                  cat['name'],
                                  size: 32,
                                  borderColor: _hexToColor(cat['color'] ?? '#0F172A'),
                                ),
                                badgePositionPercentageOffset: .98,
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      // Chú thích
                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        alignment: WrapAlignment.center,
                        children: categoryStats
                            .where((c) => c['type'] == 'expense' && double.parse(c['total'].toString()) > 0)
                            .map((cat) {
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 10, height: 10,
                                decoration: BoxDecoration(color: _hexToColor(cat['color'] ?? '#0F172A'), borderRadius: BorderRadius.circular(3)),
                              ),
                              const SizedBox(width: 8),
                              Text(cat['name'], style: const TextStyle(fontSize: 13, color: Color(0xFF475569), fontWeight: FontWeight.w500)),
                            ],
                          );
                        }).toList(),
                      ),
                    ],
                  ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(
    this.text, {
    required this.size,
    required this.borderColor,
  });
  final String text;
  final double size;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: PieChart.defaultDuration,
      width: size * 1.5,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: borderColor,
          width: 2,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(.1),
            offset: const Offset(3, 3),
            blurRadius: 3,
          ),
        ],
      ),
      padding: const EdgeInsets.all(4),
      child: Center(
        child: Text(
          text.length > 5 ? '${text.substring(0, 4)}.' : text,
          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

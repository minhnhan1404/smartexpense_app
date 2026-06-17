import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Để dùng kIsWeb
import 'dart:math';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' show Platform;

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool isLoading = true;
  String errorMessage = '';

  // Dữ liệu sẽ lấy từ API
  double totalBalance = 0.0;
  List<dynamic> categoriesChart = [];
  List<dynamic> recentTransactions = [];

  @override
  void initState() {
    super.initState();
    fetchDashboardData();
  }

  // Cấu hình địa chỉ IP máy chủ (Tùy theo thiết bị bạn dùng để test)
  String getApiUrl() {
    // Nếu chạy trên trình duyệt Chrome (Web)
    if (kIsWeb) {
      return 'http://127.0.0.1/SmartExpense/public/api/dashboard/app';
    }
    // Nếu chạy trên Máy ảo Android (Emulator)
    try {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2/SmartExpense/public/api/dashboard/app';
      }
    } catch (e) {
      // Ignored for web
    }
    // Mặc định
    return 'http://127.0.0.1/SmartExpense/public/api/dashboard/app';
  }

  // Hàm định dạng tiền Việt Nam (VD: 3.000.000 đ)
  String formatVND(double amount) {
    return '${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'\\B(?=(\\d{3})+(?!\\d))'), (match) => '.')} đ';
  }

  Future<void> fetchDashboardData() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await http.get(
        Uri.parse(getApiUrl()),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            totalBalance = double.tryParse(data['data']['total_balance'].toString()) ?? 0.0;
            categoriesChart = data['data']['categories_chart'] ?? [];
            recentTransactions = data['data']['recent_transactions'] ?? [];
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
        errorMessage = 'Lỗi không thể gọi API: $e\n(Có thể do sai IP hoặc chưa bật XAMPP)';
        isLoading = false;
      });
    }
  }

  // Hàm chuyển mã màu từ dạng #RRGGBB sang Color
  Color _hexToColor(String code) {
    return Color(int.parse(code.substring(1, 7), radix: 16) + 0xFF000000);
  }

  IconData _getIconForCategory(String categoryName) {
    if (categoryName.toLowerCase().contains('food')) return Icons.restaurant;
    if (categoryName.toLowerCase().contains('shop')) return Icons.shopping_bag;
    if (categoryName.toLowerCase().contains('trans')) return Icons.directions_car;
    if (categoryName.toLowerCase().contains('util')) return Icons.bolt;
    if (categoryName.toLowerCase().contains('health')) return Icons.medical_services;
    if (categoryName.toLowerCase().contains('salary')) return Icons.attach_money;
    return Icons.category;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5)))
            : errorMessage.isNotEmpty
                ? _buildErrorScreen()
                : _buildDashboardContent(),
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 60),
            const SizedBox(height: 16),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red, fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: fetchDashboardData,
              child: const Text('Thử Lại'),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardContent() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Center(
              child: Column(
                children: [
                  Text(
                    'Total Unallocated Balance',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    formatVND(totalBalance), // Dữ liệu thật đã format
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                      letterSpacing: -1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Card Biểu Đồ
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4F46E5).withOpacity(0.06),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Spending by Category',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'June',
                          style: TextStyle(
                            color: Color(0xFF4F46E5),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  
                  // Biểu đồ thật vẽ từ dữ liệu SQL
                  categoriesChart.isEmpty 
                  ? const SizedBox(
                      height: 180, 
                      child: Center(child: Text("Chưa có chi tiêu nào"))
                    )
                  : SizedBox(
                    height: 180,
                    width: 180,
                    child: CustomPaint(
                      painter: DonutChartPainter(categoriesChart),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Chú thích (Legend) sinh ra từ SQL
                  Wrap(
                    spacing: 16,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: categoriesChart.map((cat) {
                      return _buildLegendItem(
                        _hexToColor(cat['color']), 
                        cat['name'], 
                        formatVND(double.tryParse(cat['spent'].toString()) ?? 0)
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Transactions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Cập nhật lại dữ liệu thủ công
                    fetchDashboardData();
                  },
                  child: const Text(
                    'Làm mới',
                    style: TextStyle(
                      color: Color(0xFF4F46E5),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Danh sách giao dịch thật từ SQL
            recentTransactions.isEmpty
            ? const Center(child: Text("Không có giao dịch nào"))
            : Column(
                children: recentTransactions.map((tx) {
                  bool isIncome = tx['type'] == 'income';
                  return _buildTransactionItem(
                    tx['title'],
                    tx['date'],
                    '${isIncome ? '+' : '-'} ${formatVND(double.tryParse(tx['amount'].toString()) ?? 0)}',
                    _getIconForCategory(tx['title']),
                    _hexToColor(tx['icon_color']),
                    isIncome,
                  );
                }).toList(),
            ),
            
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String title, String amount) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
        ),
        const SizedBox(width: 4),
        Text(
          amount,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1E293B)),
        ),
      ],
    );
  }

  Widget _buildTransactionItem(String title, String subtitle, String amount, IconData icon, Color iconColor, bool isIncome) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isIncome ? const Color(0xFF10B981) : const Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }
}

class DonutChartPainter extends CustomPainter {
  final List<dynamic> categories;
  DonutChartPainter(this.categories);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2);
    final strokeWidth = 26.0;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    // Tính tổng tiền
    double totalSpent = 0;
    for (var cat in categories) {
      totalSpent += double.tryParse(cat['spent'].toString()) ?? 0.0;
    }

    if (totalSpent == 0) return;

    double startAngle = -pi / 2;

    for (var cat in categories) {
      paint.color = Color(int.parse(cat['color'].substring(1, 7), radix: 16) + 0xFF000000);
      double sweep = (double.tryParse(cat['spent'].toString()) ?? 0.0) / totalSpent;
      final sweepAngle = sweep * 2 * pi;
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - (strokeWidth / 2)),
        startAngle + 0.06, 
        sweepAngle - 0.12, 
        false,
        paint,
      );
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

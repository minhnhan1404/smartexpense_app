import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:math';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smartexpense_app/api_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' show Platform;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:smartexpense_app/screens/add_transaction_screen.dart' as smartexpense_add;
import 'package:smartexpense_app/screens/momo_payment_screen.dart' as smartexpense_momo;
import 'package:smartexpense_app/screens/vnpay_payment_screen.dart' as smartexpense_vnpay;

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool isLoading = true;
  String errorMessage = '';

  String userName = '';
  double totalBalance = 0.0;
  List<dynamic> categoriesChart = [];
  List<dynamic> recentTransactions = [];
  List<dynamic> wallets = [];

  @override
  void initState() {
    super.initState();
    fetchDashboardData();
  }

  String formatVND(double amount) {
    return '${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.')} ₫';
  }

  Future<void> fetchDashboardData() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final name = prefs.getString('user_name') ?? 'User';

      final response = await http.get(
        Uri.parse(ApiConfig.getUrl('dashboard/app')),
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
              userName = name;
              totalBalance = double.tryParse(data['data']['total_balance'].toString()) ?? 0.0;
              wallets = data['data']['wallets'] ?? [];
              categoriesChart = data['data']['categories_chart'] ?? [];
              recentTransactions = data['data']['recent_transactions'] ?? [];
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
          errorMessage = 'Lỗi kết nối mạng. Vui lòng kiểm tra lại kết nối.';
          isLoading = false;
        });
      }
    }
  }

  Color _hexToColor(String code) {
    return Color(int.parse(code.substring(1, 7), radix: 16) + 0xFF000000);
  }

  IconData _getIconForCategory(String categoryName) {
    if (categoryName.toLowerCase().contains('food') || categoryName.toLowerCase().contains('ăn')) return Icons.restaurant;
    if (categoryName.toLowerCase().contains('shop') || categoryName.toLowerCase().contains('mua')) return Icons.shopping_bag;
    if (categoryName.toLowerCase().contains('trans') || categoryName.toLowerCase().contains('xe')) return Icons.directions_car;
    if (categoryName.toLowerCase().contains('util') || categoryName.toLowerCase().contains('điện')) return Icons.bolt;
    if (categoryName.toLowerCase().contains('health') || categoryName.toLowerCase().contains('thuốc')) return Icons.medical_services;
    if (categoryName.toLowerCase().contains('salary') || categoryName.toLowerCase().contains('lương')) return Icons.attach_money;
    return Icons.category;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // Màu nền xám nhạt hiện đại
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0F172A)))
          : errorMessage.isNotEmpty
              ? _buildErrorScreen()
              : _buildDashboardContent(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => const smartexpense_add.AddTransactionScreen(),
          ).then((value) => fetchDashboardData());
        },
        backgroundColor: const Color(0xFF10B981),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ).animate().scale(delay: 600.ms, duration: 400.ms, curve: Curves.easeOutBack),
    );
  }

  Widget _buildErrorScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded, color: Colors.redAccent, size: 60),
            const SizedBox(height: 16),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: fetchDashboardData,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử Lại'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardContent() {
    return RefreshIndicator(
      onRefresh: fetchDashboardData,
      color: const Color(0xFF0F172A),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 100), 
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header - Phong cách Card Ngân Hàng (Navy Premium)
            Container(
              width: double.infinity,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 20,
                bottom: 40,
                left: 24,
                right: 24,
              ),
              decoration: const BoxDecoration(
                color: Color(0xFF0F172A), // Màu xanh đen đậm, sang trọng
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Xin chào,',
                            style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w400),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            userName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
                        ),
                        child: const Icon(Icons.notifications_outlined, color: Colors.white, size: 24),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  // Thẻ số dư
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E293B), Color(0xFF334155)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Tổng tài sản',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Icon(Icons.account_balance_wallet, color: Colors.white.withOpacity(0.5), size: 20),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          formatVND(totalBalance),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 200.ms, duration: 600.ms).slideY(begin: 0.2, end: 0, curve: Curves.easeOutQuad),
                  const SizedBox(height: 24),
                  // Quick Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildQuickAction(
                        icon: Icons.account_balance_wallet, 
                        label: 'VNPay', 
                        color: const Color(0xFF005BAA),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const smartexpense_vnpay.VNPayPaymentScreen()),
                          ).then((_) => fetchDashboardData());
                        }
                      ),
                      _buildQuickAction(
                        icon: Icons.account_balance, 
                        label: 'Chuyển khoản', 
                        color: const Color(0xFF3B82F6),
                        onTap: () {}
                      ),
                      _buildQuickAction(
                        icon: Icons.history, 
                        label: 'Lịch sử', 
                        color: const Color(0xFFF59E0B),
                        onTap: () {}
                      ),
                    ],
                  ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0),
                ],
              ),
            ).animate().fadeIn(duration: 500.ms),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Biểu đồ chi tiêu (Solid Card)
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Chi tiêu tháng này',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Tháng ${DateTime.now().month}',
                                style: const TextStyle(
                                  color: Color(0xFF475569),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        
                        categoriesChart.isEmpty 
                        ? Center(
                            child: Column(
                              children: [
                                Icon(Icons.pie_chart_outline, size: 64, color: Colors.grey.shade300),
                                const SizedBox(height: 16),
                                Text("Chưa có giao dịch chi tiêu nào", style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
                              ],
                            ),
                          )
                        : Row(
                            children: [
                              SizedBox(
                                height: 120,
                                width: 120,
                                child: CustomPaint(
                                  painter: DonutChartPainter(categoriesChart),
                                ),
                              ).animate().scale(duration: 500.ms, delay: 200.ms, curve: Curves.easeOutBack),
                              const SizedBox(width: 24),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: categoriesChart.take(4).map((cat) {
                                    return _buildLegendItem(
                                      _hexToColor(cat['color']), 
                                      cat['name'], 
                                      formatVND(double.tryParse(cat['spent'].toString()) ?? 0)
                                    );
                                  }).toList(),
                                ).animate().fadeIn(duration: 500.ms, delay: 400.ms),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 300.ms, duration: 500.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuad),
                  const SizedBox(height: 32),

                  // Giao dịch gần đây
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Giao dịch gần đây',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      TextButton(
                        onPressed: fetchDashboardData,
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF2563EB), // Blue
                          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        child: const Text('Xem tất cả'),
                      ),
                    ],
                  ).animate().fadeIn(delay: 400.ms, duration: 500.ms),
                  const SizedBox(height: 8),

                  // Danh sách giao dịch
                  recentTransactions.isEmpty
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text("Chưa có giao dịch nào", style: TextStyle(color: Colors.grey.shade500, fontSize: 15)),
                        ],
                      ),
                    ).animate().fadeIn(delay: 500.ms)
                  : Column(
                      children: recentTransactions.asMap().entries.map((entry) {
                        int index = entry.key;
                        var tx = entry.value;
                        bool isIncome = tx['type'] == 'income';
                        return _buildTransactionItem(
                          tx['title'],
                          tx['date'],
                          '${isIncome ? '+' : '-'}${formatVND(double.tryParse(tx['amount'].toString()) ?? 0)}',
                          _getIconForCategory(tx['title']),
                          _hexToColor(tx['icon_color']),
                          isIncome,
                        ).animate().fadeIn(delay: (400 + (index * 100)).ms, duration: 400.ms).slideX(begin: 0.1, end: 0, curve: Curves.easeOut);
                      }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String title, String amount) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(color: Color(0xFF475569), fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          Text(
            amount,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A)),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(String title, String subtitle, String amount, IconData icon, Color iconColor, bool isIncome) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isIncome ? const Color(0xFF10B981) : const Color(0xFF0F172A),
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
    final strokeWidth = 20.0;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

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
        startAngle + 0.1, 
        sweepAngle - 0.2, 
        false,
        paint,
      );
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}


import 'package:flutter/material.dart';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

class BudgetsScreen extends StatefulWidget {
  const BudgetsScreen({super.key});

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> {
  bool isLoading = true;
  List<dynamic> jars = [];
  double unallocatedBalance = 0.0;
  double totalBudget = 0.0;
  double allocated = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchJars();
  }

  String getApiUrl(String path) {
    if (kIsWeb) return 'http://127.0.0.1/SmartExpense/public/api/$path';
    try {
      if (Platform.isAndroid) return 'http://10.0.2.2/SmartExpense/public/api/$path';
    } catch (e) {}
    return 'http://127.0.0.1/SmartExpense/public/api/$path';
  }

  Future<void> _fetchJars() async {
    setState(() => isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      // Lấy danh sách Jars
      final res = await http.get(Uri.parse(getApiUrl('jars')), headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });

      // Lấy unallocated balance từ Dashboard hoặc User API
      final resUser = await http.get(Uri.parse(getApiUrl('user')), headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });

      if (res.statusCode == 200 && resUser.statusCode == 200) {
        final data = json.decode(res.body);
        final userData = json.decode(resUser.body);
        
        double calcAllocated = 0.0;
        for (var jar in data) {
          calcAllocated += double.tryParse(jar['balance'].toString()) ?? 0.0;
        }

        setState(() {
          jars = data;
          unallocatedBalance = double.tryParse(userData['unallocated_balance']?.toString() ?? '0') ?? 0.0;
          allocated = calcAllocated;
          totalBudget = unallocatedBalance + allocated;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  String formatVND(double amount) {
    return '${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'\\B(?=(\\d{3})+(?!\\d))'), (match) => '.')}';
  }

  Color _hexToColor(String code) {
    if (code.isEmpty) return const Color(0xFF4F46E5);
    return Color(int.parse(code.substring(1, 7), radix: 16) + 0xFF000000);
  }

  IconData _getIconForCategory(String categoryName) {
    if (categoryName.toLowerCase().contains('food') || categoryName.toLowerCase().contains('ăn')) return Icons.restaurant;
    if (categoryName.toLowerCase().contains('shop') || categoryName.toLowerCase().contains('mua')) return Icons.shopping_bag;
    if (categoryName.toLowerCase().contains('trans') || categoryName.toLowerCase().contains('di chuyển')) return Icons.directions_car;
    if (categoryName.toLowerCase().contains('util')) return Icons.bolt;
    if (categoryName.toLowerCase().contains('health') || categoryName.toLowerCase().contains('giải trí')) return Icons.gamepad;
    return Icons.account_balance_wallet;
  }

  void _showAllocateDialog() {
    if (jars.isEmpty) return;
    
    String? selectedJarId = jars[0]['id'].toString();
    TextEditingController amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Phân bổ ngân sách', style: TextStyle(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Số dư chưa phân bổ: ${formatVND(unallocatedBalance)} đ', style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedJarId,
                    decoration: InputDecoration(
                      labelText: 'Chọn Hũ/Danh mục',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: jars.map((jar) {
                      return DropdownMenuItem<String>(
                        value: jar['id'].toString(),
                        child: Text(jar['name']),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setDialogState(() => selectedJarId = val);
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Số tiền',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (amountController.text.isEmpty) return;
                    Navigator.pop(context);
                    await _allocateFunds(selectedJarId!, double.parse(amountController.text));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Phân bổ', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          }
        );
      },
    );
  }

  Future<void> _allocateFunds(String jarId, double amount) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await http.post(
        Uri.parse(getApiUrl('jars/allocate')),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: {
          'category_id': jarId,
          'amount': amount.toString(),
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Phân bổ thành công!')));
        _fetchJars();
      } else {
        final data = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'] ?? 'Lỗi phân bổ')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lỗi kết nối máy chủ')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.only(top: 24.0, left: 24, right: 24, bottom: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'My Jars',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Manage your budget allocations',
                        style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: _fetchJars,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4F46E5),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: const Color(0xFF4F46E5).withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: const Icon(Icons.refresh, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),
            
            // Allocate Funds Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF4F46E5).withOpacity(0.3), blurRadius: 24, offset: const Offset(0, 8)),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: _showAllocateDialog,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.add, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Allocate Funds',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Total Budget Summary
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.1)),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF4F46E5).withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 4)),
                ],
              ),
              child: Row(
                children: [
                  _buildSummaryItem('Total Budget', formatVND(totalBudget), const Color(0xFF0F172A)),
                  Container(width: 1, height: 36, color: const Color(0xFF6366F1).withOpacity(0.15)),
                  _buildSummaryItem('Allocated', formatVND(allocated), const Color(0xFF4F46E5)),
                  Container(width: 1, height: 36, color: const Color(0xFF6366F1).withOpacity(0.15)),
                  _buildSummaryItem('Remaining', formatVND(unallocatedBalance), const Color(0xFF10B981)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // Jars Grid
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5)))
                  : jars.isEmpty
                      ? const Center(child: Text('Không có hũ nào. Hãy tạo thêm ở web.'))
                      : GridView.count(
                          padding: const EdgeInsets.only(left: 24, right: 24, bottom: 100),
                          crossAxisCount: 2,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          childAspectRatio: 0.85,
                          children: jars.map((jar) {
                            double balance = double.tryParse(jar['balance'].toString()) ?? 0;
                            double limit = double.tryParse(jar['budget_limit'].toString()) ?? 0;
                            if (limit == 0) limit = balance > 0 ? balance * 1.5 : 1000; // Fake limit for UI if 0
                            
                            double progress = limit > 0 ? balance / limit : 0;
                            if (progress > 1.0) progress = 1.0;

                            Color color = _hexToColor(jar['color']);
                            return _buildJarCard(
                              jar['name'],
                              formatVND(balance),
                              formatVND(limit),
                              progress,
                              color,
                              color.withOpacity(0.1),
                              _getIconForCategory(jar['name']),
                            );
                          }).toList(),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('$value đ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color, letterSpacing: -0.5)),
        ],
      ),
    );
  }

  Widget _buildJarCard(String title, String spent, String limit, double progress, Color iconColor, Color lightBg, IconData icon) {
    bool isOverBudget = progress >= 0.9;
    int pct = (progress * 100).round();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: lightBg,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isOverBudget ? const Color(0xFFFEF2F2) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$pct%',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isOverBudget ? const Color(0xFFEF4444) : const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$spent đ',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'of $limit đ',
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 10),
          // Progress Bar
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: pct > 0 ? pct : 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isOverBudget ? const Color(0xFFEF4444) : iconColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                Expanded(
                  flex: pct < 100 ? 100 - pct : 0,
                  child: const SizedBox(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

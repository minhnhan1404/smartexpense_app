import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:smartexpense_app/api_config.dart';
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

  Future<void> _fetchJars() async {
    setState(() => isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      // Lấy danh sách Jars
      final res = await http.get(Uri.parse(ApiConfig.getUrl('jars')), headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });

      // Lấy unallocated balance từ Dashboard hoặc User API
      final resUser = await http.get(Uri.parse(ApiConfig.getUrl('user')), headers: {
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

        if (mounted) {
          setState(() {
            jars = data;
            unallocatedBalance = double.tryParse(userData['unallocated_balance']?.toString() ?? '0') ?? 0.0;
            allocated = calcAllocated;
            totalBudget = unallocatedBalance + allocated;
            isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  String formatVND(double amount) {
    return '${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.')}';
  }

  Color _hexToColor(String code) {
    if (code.isEmpty) return const Color(0xFF0F172A);
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: const Text('Phân bổ ngân sách', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Chưa phân bổ', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                        Text('${formatVND(unallocatedBalance)} đ', style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 15)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: selectedJarId,
                    decoration: InputDecoration(
                      labelText: 'Chọn Danh mục / Hũ',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                      labelText: 'Số tiền (VNĐ)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  ),
                  child: const Text('Phân bổ', style: TextStyle(fontWeight: FontWeight.bold)),
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
        Uri.parse(ApiConfig.getUrl('jars/allocate')),
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Phân bổ thành công!')));
          _fetchJars();
        }
      } else {
        final data = json.decode(response.body);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'] ?? 'Lỗi phân bổ')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lỗi kết nối máy chủ')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // Màu xám nhạt hiện đại
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          'Ngân sách',
          style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF0F172A)),
            onPressed: _fetchJars,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Tổng quan ngân sách
            Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF0F172A).withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8)),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      _buildSummaryItem('Tổng ngân sách', formatVND(totalBudget), const Color(0xFF0F172A)),
                      Container(width: 1, height: 40, color: const Color(0xFFE2E8F0)),
                      _buildSummaryItem('Chưa phân bổ', formatVND(unallocatedBalance), const Color(0xFF10B981)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _showAllocateDialog,
                      icon: const Icon(Icons.add, size: 20),
                      label: const Text('Phân bổ tiền', style: TextStyle(fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A), // Navy Blue
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Lưới Ngân Sách
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF0F172A)))
                  : jars.isEmpty
                      ? const Center(child: Text('Chưa có danh mục nào.', style: TextStyle(color: Colors.grey)))
                      : GridView.builder(
                          padding: const EdgeInsets.only(left: 24, right: 24, bottom: 100),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.82,
                          ),
                          itemCount: jars.length,
                          itemBuilder: (context, index) {
                            var jar = jars[index];
                            double balance = double.tryParse(jar['balance'].toString()) ?? 0;
                            double limit = double.tryParse(jar['budget_limit'].toString()) ?? 0;
                            if (limit == 0) limit = balance > 0 ? balance * 1.5 : 1000000;
                            
                            double progress = limit > 0 ? balance / limit : 0;
                            if (progress > 1.0) progress = 1.0;

                            Color color = _hexToColor(jar['color']);
                            return _buildJarCard(
                              jar['name'],
                              formatVND(balance),
                              formatVND(limit),
                              progress,
                              color,
                              _getIconForCategory(jar['name']),
                            );
                          },
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Text('$value ₫', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }

  Widget _buildJarCard(String title, String spent, String limit, double progress, Color iconColor, IconData icon) {
    bool isOverBudget = progress >= 0.9;
    bool isWarning = progress >= 0.7 && progress < 0.9;
    int pct = (progress * 100).round();

    Color progressColor = isOverBudget ? const Color(0xFFEF4444) : (isWarning ? const Color(0xFFF59E0B) : const Color(0xFF10B981));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.04),
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
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: progressColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$pct%',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: progressColor,
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
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$spent ₫',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '/ $limit ₫',
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 12),
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
                      color: progressColor,
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


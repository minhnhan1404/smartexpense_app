import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smartexpense_app/api_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' show Platform;

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  bool isExpense = true;
  String amount = '0';
  int selectedCategoryIndex = 0;

  bool isLoading = true;
  List<dynamic> categories = [];
  List<dynamic> wallets = [];
  int selectedWalletIndex = 0;

  @override
  void initState() {
    super.initState();
    fetchData();
  }


  Future<void> fetchData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    
    try {
      // Get Wallets
      final walletRes = await http.get(Uri.parse(ApiConfig.getUrl('wallets')), headers: {
        'Accept': 'application/json', 'Authorization': 'Bearer $token',
      });
      // Get Categories (Jars)
      final categoryRes = await http.get(Uri.parse(ApiConfig.getUrl('categories')), headers: {
        'Accept': 'application/json', 'Authorization': 'Bearer $token',
      });

      if (walletRes.statusCode == 200 && categoryRes.statusCode == 200) {
        setState(() {
          wallets = json.decode(walletRes.body);
          // Jars API trả về mảng trực tiếp
          categories = json.decode(categoryRes.body);
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  void _onNumpadPressed(String value) {
    setState(() {
      if (value == 'C') {
        amount = '0';
      } else if (value == 'DEL') {
        if (amount.length > 1) {
          amount = amount.substring(0, amount.length - 1);
        } else {
          amount = '0';
        }
      } else {
        if (amount == '0') {
          amount = value;
        } else {
          amount += value;
        }
      }
    });
  }

  // Hàm định dạng tiền Việt Nam (VD: 3.000.000 đ)
  String formatVND(String amountStr) {
    if (amountStr.isEmpty) return '0 đ';
    double val = double.tryParse(amountStr) ?? 0;
    return '${val.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.')} đ';
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(
          color: Color(0xFFF8FAFC),
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: const Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5))),
      );
    }
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Nút gạt ngang ở trên cùng (Handle)
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 20),
            height: 5,
            width: 40,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          
          // Header title
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Add Transaction', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                  SizedBox(height: 4),
                  Text('Record a new income or expense', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                ],
              ),
            ),
          ),

          // Toggle Income / Expense
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => isExpense = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        gradient: isExpense ? const LinearGradient(colors: [Color(0xFF4F46E5), Color(0xFF6366F1)]) : null,
                        color: isExpense ? null : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: isExpense ? [
                          BoxShadow(color: const Color(0xFF4F46E5).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))
                        ] : [],
                      ),
                      child: Center(
                        child: Text(
                          '💸 Expense',
                          style: TextStyle(
                            color: isExpense ? Colors.white : const Color(0xFF94A3B8),
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => isExpense = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        gradient: !isExpense ? const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF34D399)]) : null,
                        color: !isExpense ? null : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: !isExpense ? [
                          BoxShadow(color: const Color(0xFF10B981).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))
                        ] : [],
                      ),
                      child: Center(
                        child: Text(
                          '💰 Income',
                          style: TextStyle(
                            color: !isExpense ? Colors.white : const Color(0xFF94A3B8),
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Vùng hiển thị số tiền khổng lồ
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.1)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4F46E5).withOpacity(0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text('AMOUNT', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), letterSpacing: 1.2, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(
                  formatVND(amount),
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w800,
                    color: isExpense ? const Color(0xFF4F46E5) : const Color(0xFF10B981),
                    letterSpacing: -1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: 48,
                  height: 3,
                  decoration: BoxDecoration(
                    color: isExpense ? const Color(0xFF4F46E5) : const Color(0xFF10B981),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Danh sách chọn Ví (Wallets)
          SizedBox(
            height: 50,
            child: wallets.isEmpty 
              ? const Center(child: Text("Không có ví nào"))
              : ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: wallets.length,
              itemBuilder: (context, index) {
                final wallet = wallets[index];
                final isSelected = index == selectedWalletIndex;
                final Color walletColor = Color(int.parse((wallet['color'] ?? '#4F46E5').substring(1, 7), radix: 16) + 0xFF000000);
                
                return GestureDetector(
                  onTap: () => setState(() => selectedWalletIndex = index),
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? walletColor : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isSelected ? walletColor : Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.account_balance_wallet, color: isSelected ? Colors.white : walletColor, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          wallet['name'],
                          style: TextStyle(
                            color: isSelected ? Colors.white : const Color(0xFF1E293B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('CATEGORY', style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600, letterSpacing: 1.2)),
            ),
          ),
          // Danh sách chọn danh mục (Chips) - Lọc theo isExpense
          SizedBox(
            height: 48,
            child: Builder(
              builder: (context) {
                final filteredCategories = categories.where((c) => (c['type'] == 'expense') == isExpense).toList();
                if (filteredCategories.isEmpty) {
                  return const Center(child: Text("No categories found"));
                }
                if (selectedCategoryIndex >= filteredCategories.length) selectedCategoryIndex = 0;
                
                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: filteredCategories.length,
                  itemBuilder: (context, index) {
                    final cat = filteredCategories[index];
                    final isSelected = index == selectedCategoryIndex;
                    final Color catColor = Color(int.parse((cat['color'] ?? '#4F46E5').substring(1, 7), radix: 16) + 0xFF000000);
                    
                    return GestureDetector(
                      onTap: () => setState(() => selectedCategoryIndex = index),
                      child: Container(
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected ? catColor.withOpacity(0.1) : Colors.white.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(color: isSelected ? catColor : Colors.transparent, width: 2),
                          boxShadow: [
                            if (isSelected) BoxShadow(color: catColor.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 2))
                            else BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 1)),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.category,
                              color: isSelected ? catColor : const Color(0xFF64748B),
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              cat['name'],
                              style: TextStyle(
                                color: isSelected ? catColor : const Color(0xFF64748B),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }
            ),
          ),
          const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // Bàn phím Numpad
          Container(
            padding: const EdgeInsets.only(top: 16, left: 24, right: 24, bottom: 24),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _buildNumpadRow(['1', '2', '3'])),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _buildNumpadRow(['4', '5', '6'])),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _buildNumpadRow(['7', '8', '9'])),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _buildNumpadRow(['000', '0', 'DEL'])),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Nút bấm lưu
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isExpense ? const [Color(0xFF4F46E5), Color(0xFF6366F1)] : const [Color(0xFF10B981), Color(0xFF34D399)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: isExpense ? const Color(0xFF4F46E5).withOpacity(0.35) : const Color(0xFF10B981).withOpacity(0.35),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () async {
                        if (amount == '0' || amount.isEmpty) return;
                        final filteredCategories = categories.where((c) => (c['type'] == 'expense') == isExpense).toList();
                        if (filteredCategories.isEmpty || wallets.isEmpty) return;

                        final prefs = await SharedPreferences.getInstance();
                        final token = prefs.getString('auth_token');
                        
                        try {
                          final res = await http.post(
                            Uri.parse(ApiConfig.getUrl('transactions')),
                            headers: {
                              'Accept': 'application/json',
                              'Authorization': 'Bearer $token',
                            },
                            body: {
                              'wallet_id': wallets[selectedWalletIndex]['id'].toString(),
                              'category_id': filteredCategories[selectedCategoryIndex]['id'].toString(),
                              'amount': amount,
                              'date': DateTime.now().toIso8601String().split('T')[0],
                              'description': 'Giao dịch từ App'
                            }
                          );
                          if (res.statusCode == 201) {
                            Navigator.pop(context); // Đóng màn hình thêm
                          } else {
                            // Báo lỗi (VD: số dư ko đủ)
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(json.decode(res.body)['message'] ?? 'Lỗi thêm giao dịch')));
                          }
                        } catch(e) {
                           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lỗi kết nối')));
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: Text(
                        'Add ${isExpense ? 'Expense' : 'Income'} • ${formatVND(amount)}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumpadRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: keys.map((key) {
        bool isDel = key == 'DEL';
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: InkWell(
              onTap: () => _onNumpadPressed(key),
              borderRadius: BorderRadius.circular(18),
              child: Container(
                height: 60,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isDel ? const Color(0xFFEEF2FF) : Colors.white.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: isDel
                    ? const Icon(Icons.backspace_outlined, size: 24, color: Color(0xFF4F46E5))
                    : Text(
                        key,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}


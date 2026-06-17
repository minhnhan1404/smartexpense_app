import 'package:flutter/material.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  bool isExpense = true;
  String amount = '0';
  int selectedCategoryIndex = 0;

  final List<Map<String, dynamic>> categories = [
    {'name': 'Food', 'icon': Icons.restaurant, 'color': const Color(0xFF4F46E5)},
    {'name': 'Shopping', 'icon': Icons.shopping_bag, 'color': const Color(0xFF10B981)},
    {'name': 'Transport', 'icon': Icons.directions_car, 'color': const Color(0xFFF59E0B)},
    {'name': 'Utilities', 'icon': Icons.bolt, 'color': const Color(0xFFEF4444)},
    {'name': 'Health', 'icon': Icons.medical_services, 'color': const Color(0xFF8B5CF6)},
  ];

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
    return '${val.toStringAsFixed(0).replaceAllMapped(RegExp(r'\\B(?=(\\d{3})+(?!\\d))'), (match) => '.')} đ';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
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
          
          // Toggle Income / Expense
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
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
                  child: GestureDetector(
                    onTap: () => setState(() => isExpense = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isExpense ? const Color(0xFF4F46E5) : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          'Expense',
                          style: TextStyle(
                            color: isExpense ? Colors.white : Colors.grey.shade600,
                            fontWeight: FontWeight.bold,
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
                        color: !isExpense ? const Color(0xFF10B981) : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          'Income',
                          style: TextStyle(
                            color: !isExpense ? Colors.white : Colors.grey.shade600,
                            fontWeight: FontWeight.bold,
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
          Text(
            'How much?',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            formatVND(amount),
            style: TextStyle(
              fontSize: 50, // Thu nhỏ một xíu để số dài không bị tràn
              fontWeight: FontWeight.bold,
              color: isExpense ? const Color(0xFF1E293B) : const Color(0xFF10B981),
            ),
          ),
          const SizedBox(height: 32),

          // Danh sách chọn danh mục (Chips)
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final cat = categories[index];
                final isSelected = index == selectedCategoryIndex;
                final Color catColor = cat['color'];
                
                return GestureDetector(
                  onTap: () => setState(() => selectedCategoryIndex = index),
                  child: Container(
                    margin: const EdgeInsets.only(right: 16),
                    width: 72,
                    decoration: BoxDecoration(
                      color: isSelected ? catColor : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          cat['icon'],
                          color: isSelected ? Colors.white : catColor,
                          size: 28,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          cat['name'],
                          style: TextStyle(
                            color: isSelected ? Colors.white : const Color(0xFF1E293B),
                            fontSize: 12,
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
          const Spacer(),

          // Bàn phím Numpad
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Column(
              children: [
                _buildNumpadRow(['1', '2', '3']),
                const SizedBox(height: 16),
                _buildNumpadRow(['4', '5', '6']),
                const SizedBox(height: 16),
                _buildNumpadRow(['7', '8', '9']),
                const SizedBox(height: 16),
                _buildNumpadRow(['.', '0', 'DEL']),
                const SizedBox(height: 24),
                
                // Nút bấm lưu
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Đóng màn hình thêm
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isExpense ? const Color(0xFF4F46E5) : const Color(0xFF10B981),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 8,
                    ),
                    child: const Text(
                      'Save Transaction',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
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
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: keys.map((key) {
        return InkWell(
          onTap: () => _onNumpadPressed(key),
          borderRadius: BorderRadius.circular(30),
          child: Container(
            width: 80,
            height: 60,
            alignment: Alignment.center,
            child: key == 'DEL'
                ? const Icon(Icons.backspace_outlined, size: 28, color: Color(0xFF1E293B))
                : Text(
                    key,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
          ),
        );
      }).toList(),
    );
  }
}

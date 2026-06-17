import 'package:flutter/material.dart';

class BudgetsScreen extends StatelessWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Expense Jars',
          style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          children: [
            const SizedBox(height: 10),
            // Nút Allocate Funds nổi bật
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.account_balance_wallet, color: Colors.white),
                label: const Text(
                  'Allocate Funds',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 8,
                  shadowColor: const Color(0xFF4F46E5).withOpacity(0.5),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Lưới Grid 2 cột cho các Hũ (Jars)
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.85,
                children: [
                  _buildJarCard('Food', '3.500.000 đ', '5.000.000 đ', 0.7, const Color(0xFF4F46E5), Icons.restaurant),
                  _buildJarCard('Shopping', '2.000.000 đ', '3.000.000 đ', 0.66, const Color(0xFF10B981), Icons.shopping_bag),
                  _buildJarCard('Transport', '1.200.000 đ', '1.500.000 đ', 0.8, const Color(0xFFF59E0B), Icons.directions_car),
                  _buildJarCard('Utilities', '900.000 đ', '2.000.000 đ', 0.45, const Color(0xFFEF4444), Icons.bolt),
                  _buildJarCard('Health', '500.000 đ', '1.000.000 đ', 0.5, const Color(0xFF8B5CF6), Icons.medical_services),
                  _buildJarCard('Savings', '10.000.000 đ', '10.000.000 đ', 1.0, const Color(0xFF0EA5E9), Icons.savings),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJarCard(String title, String spent, String limit, double progress, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.1), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const Spacer(),
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
            '$spent / $limit',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 12),
          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: color.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}

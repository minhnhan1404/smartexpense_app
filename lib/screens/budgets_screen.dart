import 'package:flutter/material.dart';

class BudgetsScreen extends StatelessWidget {
  const BudgetsScreen({super.key});

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
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4F46E5),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4F46E5).withOpacity(0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.more_horiz, color: Colors.white, size: 18),
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
                    BoxShadow(
                      color: const Color(0xFF4F46E5).withOpacity(0.3),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {},
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
                  BoxShadow(
                    color: const Color(0xFF4F46E5).withOpacity(0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  _buildSummaryItem('Total Budget', '24.150k', const Color(0xFF0F172A)),
                  Container(width: 1, height: 36, color: const Color(0xFF6366F1).withOpacity(0.15)),
                  _buildSummaryItem('Allocated', '18.650k', const Color(0xFF4F46E5)),
                  Container(width: 1, height: 36, color: const Color(0xFF6366F1).withOpacity(0.15)),
                  _buildSummaryItem('Remaining', '5.500k', const Color(0xFF10B981)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // Jars Grid
            Expanded(
              child: GridView.count(
                padding: const EdgeInsets.only(left: 24, right: 24, bottom: 100),
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 0.85,
                children: [
                  _buildJarCard('Food & Dining', '3.500k', '5.000k', 0.7, const Color(0xFF4F46E5), const Color(0xFFEEF2FF), Icons.restaurant),
                  _buildJarCard('Shopping', '2.000k', '3.000k', 0.66, const Color(0xFF10B981), const Color(0xFFECFDF5), Icons.shopping_bag),
                  _buildJarCard('Transport', '1.200k', '1.500k', 0.8, const Color(0xFFF59E0B), const Color(0xFFFFFBEB), Icons.directions_car),
                  _buildJarCard('Utilities', '1.800k', '2.000k', 0.9, const Color(0xFFEF4444), const Color(0xFFFEF2F2), Icons.bolt),
                  _buildJarCard('Health', '500k', '1.000k', 0.5, const Color(0xFF8B5CF6), const Color(0xFFF5F3FF), Icons.medical_services),
                  _buildJarCard('Savings', '10.000k', '10.000k', 1.0, const Color(0xFF0EA5E9), const Color(0xFFF0F9FF), Icons.savings),
                ],
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
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color, letterSpacing: -0.5)),
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
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            spent,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'of $limit',
            style: const TextStyle(
              fontSize: 11,
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
                  flex: pct,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isOverBudget ? const Color(0xFFEF4444) : iconColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                Expanded(
                  flex: 100 - pct,
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

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:smartexpense_app/api_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class MoMoPaymentScreen extends StatefulWidget {
  const MoMoPaymentScreen({super.key});

  @override
  State<MoMoPaymentScreen> createState() => _MoMoPaymentScreenState();
}

class _MoMoPaymentScreenState extends State<MoMoPaymentScreen> {
  final _amountController = TextEditingController();
  final _orderInfoController = TextEditingController();
  bool _isLoading = false;

  Future<void> _payWithMoMo() async {
    final amount = _amountController.text.replaceAll('.', '');
    final orderInfo = _orderInfoController.text.trim();

    if (amount.isEmpty || orderInfo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đủ số tiền và lý do chi tiêu!')),
      );
      return;
    }

    if (int.parse(amount) < 1000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Số tiền thanh toán MoMo phải lớn hơn hoặc bằng 1,000 VNĐ')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await http.post(
        Uri.parse(ApiConfig.getUrl('momo/payment')),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'amount': amount,
          'orderInfo': orderInfo,
        }),
      );

      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['payUrl'] != null) {
        final Uri payUri = Uri.parse(data['payUrl']);
        if (await canLaunchUrl(payUri)) {
          await launchUrl(payUri, mode: LaunchMode.externalApplication);
          // Return to previous screen after launching
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không thể mở ứng dụng MoMo!')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Lỗi tạo thanh toán MoMo')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lỗi kết nối máy chủ!')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Giả lập chi tiêu MoMo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFA50064), // MoMo Pink
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.qr_code_scanner, size: 80, color: Color(0xFFA50064)),
            const SizedBox(height: 24),
            const Text(
              'Tính năng này giúp bạn giả lập chi tiêu. Khi bạn thanh toán thành công qua MoMo, hệ thống sẽ tự động bắt từ khoá để phân loại (Ăn uống, Di chuyển, Mua sắm...) và ghi nhận vào lịch sử chi tiêu của bạn!',
              style: TextStyle(fontSize: 15, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Số tiền chi tiêu (VNĐ)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _orderInfoController,
              decoration: const InputDecoration(
                labelText: 'Bạn chi tiêu cho việc gì?',
                hintText: 'Ví dụ: Ăn phở gà',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.edit_note),
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _isLoading ? null : _payWithMoMo,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFA50064),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading 
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Thanh toán qua MoMo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

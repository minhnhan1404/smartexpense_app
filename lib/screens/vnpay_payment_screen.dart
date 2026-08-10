import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:smartexpense_app/api_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class VNPayPaymentScreen extends StatefulWidget {
  const VNPayPaymentScreen({super.key});

  @override
  State<VNPayPaymentScreen> createState() => _VNPayPaymentScreenState();
}

class _VNPayPaymentScreenState extends State<VNPayPaymentScreen> {
  final _amountController = TextEditingController();
  final _orderInfoController = TextEditingController();
  bool _isLoading = false;

  Future<void> _payWithVNPay() async {
    final amount = _amountController.text.replaceAll('.', '');
    final orderInfo = _orderInfoController.text.trim();

    if (amount.isEmpty || orderInfo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đủ số tiền và lý do chi tiêu!')),
      );
      return;
    }

    if (int.parse(amount) < 10000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Số tiền thanh toán VNPay phải lớn hơn hoặc bằng 10,000 VNĐ')),
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
        Uri.parse(ApiConfig.getUrl('vnpay/payment')),
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
        try {
          await launchUrl(payUri, mode: LaunchMode.externalApplication);
          // Return to previous screen after launching
          Navigator.pop(context, true);
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không thể mở URL VNPay!')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Lỗi tạo thanh toán VNPay')),
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
        title: const Text('Thanh toán qua VNPay', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF005BAA), // VNPay Blue
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.account_balance_wallet, size: 80, color: Color(0xFF005BAA)),
            const SizedBox(height: 24),
            const Text(
              'Nhập số tiền và nội dung, ứng dụng sẽ mở VNPay để bạn thanh toán. Giao dịch thành công sẽ tự động cập nhật vào app.',
              style: TextStyle(fontSize: 15, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Số tiền (VNĐ)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _orderInfoController,
              decoration: const InputDecoration(
                labelText: 'Nội dung chi tiêu',
                hintText: 'VD: Ăn lẩu Thái',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.edit_note),
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _isLoading ? null : _payWithVNPay,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF005BAA),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading 
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Thanh toán VNPay', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

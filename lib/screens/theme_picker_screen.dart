import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart'; // import appThemeColor

class ThemePickerScreen extends StatefulWidget {
  const ThemePickerScreen({super.key});

  @override
  State<ThemePickerScreen> createState() => _ThemePickerScreenState();
}

class _ThemePickerScreenState extends State<ThemePickerScreen> {
  late double _red;
  late double _green;
  late double _blue;

  @override
  void initState() {
    super.initState();
    Color currentColor = appThemeColor.value;
    _red = currentColor.red.toDouble();
    _green = currentColor.green.toDouble();
    _blue = currentColor.blue.toDouble();
  }

  void _updateColor() {
    Color newColor = Color.fromRGBO(_red.toInt(), _green.toInt(), _blue.toInt(), 1.0);
    appThemeColor.value = newColor;
  }

  Future<void> _saveTheme() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_color', appThemeColor.value.value);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã lưu màu giao diện thành công'), backgroundColor: Color(0xFF10B981)));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    Color previewColor = Color.fromRGBO(_red.toInt(), _green.toInt(), _blue.toInt(), 1.0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tùy chỉnh Giao diện (RGB)'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Màu sắc hiện tại:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                color: previewColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: previewColor.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: const Text(
                'SmartExpense',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 40),
            _buildColorSlider('Đỏ (Red)', _red, Colors.red, (val) {
              setState(() => _red = val);
              _updateColor();
            }),
            const SizedBox(height: 16),
            _buildColorSlider('Xanh lá (Green)', _green, Colors.green, (val) {
              setState(() => _green = val);
              _updateColor();
            }),
            const SizedBox(height: 16),
            _buildColorSlider('Xanh lam (Blue)', _blue, Colors.blue, (val) {
              setState(() => _blue = val);
              _updateColor();
            }),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _saveTheme,
                style: ElevatedButton.styleFrom(
                  backgroundColor: previewColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Lưu Giao Diện', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorSlider(String label, double value, Color color, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: ${value.toInt()}', style: const TextStyle(fontWeight: FontWeight.w600)),
        Slider(
          value: value,
          min: 0,
          max: 255,
          activeColor: color,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

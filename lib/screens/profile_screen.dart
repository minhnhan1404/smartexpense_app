import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:smartexpense_app/api_config.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform, File;
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String userName = 'Loading...';
  String userEmail = 'Loading...';
  String? avatarUrl;
  bool _isLoading = false;


  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('user_name') ?? 'Guest User';
      userEmail = prefs.getString('user_email') ?? 'guest@example.com';
    });

    final token = prefs.getString('auth_token');
    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse(ApiConfig.getUrl('user')),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        String? fixedAvatarUrl = data['avatar'];
        if (fixedAvatarUrl != null) {
          if (!fixedAvatarUrl.startsWith('http')) {
            String baseUrl = ApiConfig.getUrl('').replaceAll('/api/', '/');
            fixedAvatarUrl = baseUrl + fixedAvatarUrl;
          }
          if (!kIsWeb && Platform.isAndroid) {
            fixedAvatarUrl = fixedAvatarUrl.replaceAll('127.0.0.1', '10.0.2.2');
            fixedAvatarUrl = fixedAvatarUrl.replaceAll('localhost', '10.0.2.2');
          }
        }

        setState(() {
          userName = data['name'];
          userEmail = data['email'];
          avatarUrl = fixedAvatarUrl;
        });
        await prefs.setString('user_name', data['name']);
        await prefs.setString('user_email', data['email']);
      }
    } catch (e) {
      print('Error loading user: $e');
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);

    if (image == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      var request = http.MultipartRequest('POST', Uri.parse(ApiConfig.getUrl('user/avatar')));
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      if (kIsWeb) {
        request.files.add(http.MultipartFile.fromBytes('avatar', await image.readAsBytes(), filename: image.name));
      } else {
        request.files.add(await http.MultipartFile.fromPath('avatar', image.path));
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        String? fixedAvatarUrl = data['user']['avatar'];
        if (fixedAvatarUrl != null) {
          if (!fixedAvatarUrl.startsWith('http')) {
            String baseUrl = ApiConfig.getUrl('').replaceAll('/api/', '/');
            fixedAvatarUrl = baseUrl + fixedAvatarUrl;
          }
          if (!kIsWeb && Platform.isAndroid) {
            fixedAvatarUrl = fixedAvatarUrl.replaceAll('127.0.0.1', '10.0.2.2');
            fixedAvatarUrl = fixedAvatarUrl.replaceAll('localhost', '10.0.2.2');
          }
        }

        setState(() {
          avatarUrl = fixedAvatarUrl;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cập nhật ảnh đại diện thành công')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lỗi cập nhật ảnh đại diện')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không thể kết nối tới máy chủ')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    // Hiển thị hộp thoại xác nhận
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Log Out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      // Xóa toàn bộ dữ liệu trong bộ nhớ
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // Chuyển hướng về màn hình Đăng Nhập
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              // Avatar
              GestureDetector(
                onTap: _isLoading ? null : _pickAndUploadAvatar,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4F46E5).withOpacity(0.15),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: _isLoading 
                          ? const Center(child: CircularProgressIndicator()) 
                          : avatarUrl != null 
                            ? Image.network(avatarUrl!, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.person, size: 60, color: Color(0xFF4F46E5)))
                            : const Center(child: Icon(Icons.person, size: 60, color: Color(0xFF4F46E5))),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFF4F46E5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Name & Email
              Text(
                userName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                userEmail,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 40),

              // Settings List
              _buildSettingItem(Icons.person_outline, 'Account Settings', () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Account Settings'),
                    content: const Text('Tính năng thay đổi thông tin cá nhân đang được phát triển.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Đóng'))
                    ],
                  ),
                );
              }),
              _buildSettingItem(Icons.color_lens_outlined, 'Theme Selection', () {
                showModalBottomSheet(
                  context: context,
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                  builder: (context) => Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Chọn giao diện', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        ListTile(
                          leading: const Icon(Icons.light_mode, color: Colors.orange),
                          title: const Text('Chế độ Sáng (Light)'),
                          trailing: const Icon(Icons.check, color: Colors.green),
                          onTap: () => Navigator.pop(context),
                        ),
                        ListTile(
                          leading: const Icon(Icons.dark_mode, color: Colors.black87),
                          title: const Text('Chế độ Tối (Dark)'),
                          onTap: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tính năng Dark mode đang được hoàn thiện')));
                          },
                        ),
                      ],
                    ),
                  ),
                );
              }),
              _buildSettingItem(Icons.file_download_outlined, 'Export Data', () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dữ liệu của bạn đang được chuẩn bị xuất ra file Excel...')));
              }),
              
              const SizedBox(height: 24),
              // Log Out
              _buildSettingItem(Icons.logout, 'Log Out', _logout, isDestructive: true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingItem(IconData icon, String title, VoidCallback onTap, {bool isDestructive = false}) {
    final color = isDestructive ? const Color(0xFFEF4444) : const Color(0xFF1E293B);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDestructive ? color.withOpacity(0.1) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
        onTap: onTap,
      ),
    );
  }
}

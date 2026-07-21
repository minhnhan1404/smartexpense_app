import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:smartexpense_app/api_config.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform, File;
import 'login_screen.dart';
import 'edit_profile_screen.dart';
import 'theme_picker_screen.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

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

        if (mounted) {
          setState(() {
            userName = data['name'];
            userEmail = data['email'];
            avatarUrl = fixedAvatarUrl;
          });
          await prefs.setString('user_name', data['name']);
          await prefs.setString('user_email', data['email']);
        }
      }
    } catch (e) {
      if (kDebugMode) print('Error loading user: $e');
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

        if (mounted) {
          setState(() {
            avatarUrl = fixedAvatarUrl;
          });
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cập nhật ảnh đại diện thành công', style: TextStyle(color: Colors.white)), backgroundColor: Color(0xFF10B981)));
        }
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lỗi cập nhật ảnh đại diện', style: TextStyle(color: Colors.white)), backgroundColor: Color(0xFFEF4444)));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không thể kết nối tới máy chủ', style: TextStyle(color: Colors.white)), backgroundColor: Color(0xFFEF4444)));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _exportData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await http.get(
        Uri.parse(ApiConfig.getUrl('transactions/export')),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> transactions = json.decode(response.body);
        
        List<List<dynamic>> csvData = [
          ['Ngày', 'Mô tả', 'Danh mục', 'Loại', 'Số tiền (VNĐ)', 'Ví']
        ];

        for (var tx in transactions) {
          csvData.add([
            tx['date'],
            tx['description'] ?? tx['title'] ?? '',
            tx['category']?['name'] ?? '',
            tx['category']?['type'] == 'expense' ? 'Chi tiêu' : 'Thu nhập',
            tx['amount'],
            tx['wallet']?['name'] ?? ''
          ]);
        }

        String csv = const ListToCsvConverter().convert(csvData);
        final String dir = (await getApplicationDocumentsDirectory()).path;
        final String path = '$dir/smartexpense_export.csv';
        final File file = File(path);
        await file.writeAsString(csv);

        if (mounted) {
          Share.shareXFiles([XFile(path)], text: 'Dữ liệu thu chi SmartExpense');
        }
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lỗi xuất dữ liệu'), backgroundColor: Color(0xFFEF4444)));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không thể xuất dữ liệu lúc này'), backgroundColor: Color(0xFFEF4444)));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Đăng xuất', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F172A))),
        content: const Text('Bạn có chắc chắn muốn đăng xuất không?', style: TextStyle(color: Color(0xFF475569))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            ),
            child: const Text('Đăng xuất', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

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
      backgroundColor: const Color(0xFFF1F5F9), // Màu xám nhạt hiện đại
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          'Tài khoản',
          style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),
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
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0F172A).withOpacity(0.08),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: _isLoading 
                          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0F172A))) 
                          : avatarUrl != null 
                            ? Image.network(avatarUrl!, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.person, size: 60, color: Color(0xFF94A3B8)))
                            : const Center(child: Icon(Icons.person, size: 60, color: Color(0xFF94A3B8))),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // Name & Email
              Text(
                userName,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                userEmail,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 40),

              // Settings List (Grouped in a Card)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withOpacity(0.03),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildSettingItem(Icons.person_outline, 'Thông tin cá nhân', () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => EditProfileScreen(initialName: userName)),
                      );
                      if (result == true) {
                        _loadUserData();
                      }
                    }),
                    const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
                    _buildSettingItem(Icons.color_lens_outlined, 'Giao diện (Theme)', () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ThemePickerScreen()),
                      );
                    }),
                    const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
                    _buildSettingItem(Icons.cloud_download_outlined, 'Xuất dữ liệu (Export)', _exportData),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              // Log Out (Separate Card)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withOpacity(0.03),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: _buildSettingItem(Icons.logout, 'Đăng xuất', _logout, isDestructive: true),
              ),
              const SizedBox(height: 100), // Bottom padding for navbar
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingItem(IconData icon, String title, VoidCallback onTap, {bool isDestructive = false}) {
    final color = isDestructive ? const Color(0xFFEF4444) : const Color(0xFF0F172A);
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDestructive ? color.withOpacity(0.1) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

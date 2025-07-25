import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';

/// UserScreen: Tab "User" hiển thị thông tin cá nhân, avatar, thống kê, menu tài khoản
class UserScreen extends StatelessWidget {
  /// Nút debug: xem và sửa access_token
  Widget _debugTokenButton(BuildContext context) {
    // 2 nút debug đã được comment lại, khi cần test thì bỏ comment ra
    return const SizedBox.shrink();
    /*
    return Column(
      children: [
        ElevatedButton(
          onPressed: () async {
            final prefs = await SharedPreferences.getInstance();
            // Xem token hiện tại
            print('Access token: \\${prefs.getString('access_token')}');
            // Sửa token để test logout tự động
            await prefs.setString('access_token', 'token_sai_de_test');
            print('Đã sửa access_token thành token_sai_de_test');
          },
          child: const Text('Debug Token'),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () async {
            // Gọi fetchProfile và in ra kết quả
            final user = await UserService.fetchProfile(context);
            print('fetchProfile result: \\${user?.toString()}');
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    user != null
                        ? 'Fetch thành công!'
                        : 'Fetch thất bại hoặc đã logout',
                  ),
                ),
              );
            }
          },
          child: const Text('Test fetchProfile'),
        ),
      ],
    );
    */
  }

  final String userName;
  const UserScreen({super.key, required this.userName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            // Avatar và nút đổi ảnh
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const CircleAvatar(
                    radius: 48,
                    backgroundColor: Colors.white24,
                    backgroundImage: AssetImage(
                      'assets/images/avatar_placeholder.png',
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Tên người dùng
            Text(
              userName,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 24),
            // Thống kê cá nhân
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _UserStat(
                    icon: Icons.timer,
                    value: '10',
                    label: 'Total Time (h)',
                    color: Colors.blue,
                  ),
                  _UserStat(
                    icon: Icons.star,
                    value: '3/28',
                    label: 'Goals Achieved',
                    color: Colors.amber,
                  ),
                  _UserStat(
                    icon: Icons.emoji_events,
                    value: '5/15',
                    label: 'Badge Collected',
                    color: Colors.red,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            _SectionTitle(title: 'Tài khoản'),
            _UserMenuItem(icon: Icons.person, text: 'Chỉnh sửa tài khoản'),
            _UserMenuItem(
              icon: Icons.badge,
              text: 'Chỉnh sửa thông tin người dùng',
            ),
            const SizedBox(height: 16),
            _SectionTitle(title: 'General'),
            _UserMenuItem(icon: Icons.settings, text: 'Cài đặt ứng dụng'),
            _UserMenuItem(icon: Icons.subscriptions, text: 'Subscription'),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white12,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.logout, color: Color(0xFF8854FF)),
                      label: const Text(
                        'Đăng xuất',
                        style: TextStyle(
                          color: Color(0xFF8854FF),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      onPressed: () async {
                        await AuthService.logout(context);
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  _debugTokenButton(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  const _UserStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          child: Icon(icon, color: color),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white70,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
}

class _UserMenuItem extends StatelessWidget {
  final IconData icon;
  final String text;
  const _UserMenuItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF8854FF)),
      title: Text(text, style: const TextStyle(color: Colors.white)),
      trailing: const Icon(Icons.chevron_right, color: Colors.white54),
      onTap: () {},
    );
  }
}

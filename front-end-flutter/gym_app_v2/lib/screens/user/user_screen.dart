import 'package:flutter/material.dart';
import '../../core/logging/app_logger.dart';
import '../../core/extensions/color_extensions.dart';
import '../../widgets/app_button.dart';
import '../../widgets/animations/animated_appear.dart';
import '../../widgets/skeleton/skeleton_box.dart';
import 'package:flutter/services.dart';
// import 'package:health/health.dart';
import '../../services/log_out_service.dart';
import '../../services/user_service.dart';
import '../../models/user_model.dart';

/// UserScreen: Tab "User" hiển thị thông tin cá nhân, avatar, thống kê, menu tài khoản
class UserScreen extends StatefulWidget {
  const UserScreen({super.key});

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  UserModel? _user;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    final user = await UserService.fetchProfile(context);
    if (!mounted) return;
    if (user != null) {
      // In ra terminal khi fetchProfile thành công
      // ignore: avoid_print
      AppLogger.info(
        'fetchProfile thành công: ${user.name} (${user.email})',
        tag: 'UserScreen',
      );
    }
    setState(() {
      _user = user;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 24),
              AnimatedAppear(
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (_loading)
                        const SkeletonBox(
                          width: 96,
                          height: 96,
                          borderRadius: BorderRadius.all(Radius.circular(48)),
                        )
                      else
                        CircleAvatar(
                          radius: 48,
                          backgroundColor: Colors.white24,
                          backgroundImage:
                              _user?.profilePicture != null &&
                                  _user!.profilePicture!.isNotEmpty
                              ? NetworkImage(_user!.profilePicture!)
                              : null,
                        ),
                      if (!_loading)
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
              ),
              const SizedBox(height: 12),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _loading
                    ? const SkeletonBox(
                        key: ValueKey('name_skel'),
                        width: 140,
                        height: 18,
                        borderRadius: BorderRadius.all(Radius.circular(6)),
                      )
                    : Text(
                        _user?.name ?? '',
                        key: const ValueKey('name'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
              ),
              const SizedBox(height: 24),
              AnimatedAppear(
                delay: const Duration(milliseconds: 120),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: _loading
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            SkeletonBox(
                              width: 70,
                              height: 70,
                              borderRadius: BorderRadius.all(
                                Radius.circular(20),
                              ),
                            ),
                            SkeletonBox(
                              width: 70,
                              height: 70,
                              borderRadius: BorderRadius.all(
                                Radius.circular(20),
                              ),
                            ),
                            SkeletonBox(
                              width: 70,
                              height: 70,
                              borderRadius: BorderRadius.all(
                                Radius.circular(20),
                              ),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
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
              ),
              const SizedBox(height: 32),
              AnimatedAppear(
                delay: const Duration(milliseconds: 180),
                child: _SectionTitle(title: 'Tài khoản'),
              ),
              ..._buildMenuSection(
                loading: _loading,
                items: const [
                  _UserMenuItem(
                    icon: Icons.person,
                    text: 'Chỉnh sửa tài khoản',
                  ),
                  _UserMenuItem(
                    icon: Icons.badge,
                    text: 'Chỉnh sửa thông tin người dùng',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AnimatedAppear(
                delay: const Duration(milliseconds: 220),
                child: _SectionTitle(title: 'General'),
              ),
              ..._buildMenuSection(
                loading: _loading,
                items: const [
                  _UserMenuItem(
                    icon: Icons.subscriptions,
                    text: 'Subscription',
                  ),
                ],
              ),
              const Spacer(),
              AnimatedAppear(
                delay: const Duration(milliseconds: 260),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: _loading
                      ? const SkeletonBox(
                          width: double.infinity,
                          height: 48,
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        )
                      : AppButton.outline(
                          label: 'Đăng xuất',
                          size: AppButtonSize.medium,
                          fullWidth: true,
                          leadingIcon: Icons.logout,
                          onPressed: () async {
                            await LogoutService.logout(
                              context,
                              reason: 'user_manual_logout',
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildMenuSection({
    required bool loading,
    required List<_UserMenuItem> items,
  }) {
    if (loading) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Column(
            children: List.generate(
              items.length,
              (_) => const Padding(
                padding: EdgeInsets.symmetric(vertical: 4.0),
                child: SkeletonBox(
                  width: double.infinity,
                  height: 52,
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
            ),
          ),
        ),
      ];
    }
    return items;
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
          backgroundColor: color.withOpacityRatio(0.15),
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

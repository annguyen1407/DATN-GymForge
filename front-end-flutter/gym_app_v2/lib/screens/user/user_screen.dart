import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:firebase_storage/firebase_storage.dart';
// Removed mock Apple-like purchase UI (temporary simplification)
import '../../core/logging/app_logger.dart';
import '../../widgets/app_button.dart';
import '../../repositories/subscriptions_repository.dart';
import '../../models/subscription_plan_model.dart';
import '../../widgets/animations/animated_appear.dart';
import '../../widgets/skeleton/skeleton_box.dart';
import 'package:flutter/services.dart';
import '../../services/log_out_service.dart';
import '../../services/user_service.dart';
import '../../models/user_model.dart';
import 'user_info_screen.dart';
import '../../widgets/app_snack_bar.dart';

/// UserScreen: Tab "User" hiển thị thông tin cá nhân, avatar, thống kê, menu tài khoản
class UserScreen extends StatefulWidget {
  const UserScreen({super.key});

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  UserModel? _user;
  bool _loading = true;
  bool _uploadingAvatar = false;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  void _openAvatarPreview(String url) {
    showDialog(
      context: context,
      builder: (ctx) => GestureDetector(
        onTap: () => Navigator.pop(ctx),
        child: Container(
          color: Colors.black.withOpacity(0.9),
          alignment: Alignment.center,
          child: Hero(
            tag: 'user_avatar_preview',
            child: InteractiveViewer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(url, fit: BoxFit.cover),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _startAvatarPickFlow() async {
    if (_uploadingAvatar) return;
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return; // cancelled
    setState(() => _uploadingAvatar = true);
    try {
      final raw = await picked.readAsBytes();
      img.Image? decoded = img.decodeImage(raw);
      if (decoded == null) throw Exception('Không đọc được ảnh');
      final minSide = decoded.width < decoded.height
          ? decoded.width
          : decoded.height;
      final cropX = (decoded.width - minSide) ~/ 2;
      final cropY = (decoded.height - minSide) ~/ 2;
      decoded = img.copyCrop(
        decoded,
        x: cropX,
        y: cropY,
        width: minSide,
        height: minSide,
      );
      if (decoded.width > 512) {
        decoded = img.copyResize(decoded, width: 512, height: 512);
      }
      final jpg = img.encodeJpg(decoded, quality: 85);
      final userId = _user?.id ?? 'unknown';
      final ref = FirebaseStorage.instance.ref().child('avatars/$userId.jpg');
      await ref.putData(
        jpg,
        SettableMetadata(
          contentType: 'image/jpeg',
          cacheControl: 'public,max-age=604800',
        ),
      );
      final url = await ref.getDownloadURL();
      final ok = await UserService.updateProfile(context, {
        'profilePicture': url,
      });
      if (ok) {
        await _fetchProfile();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cập nhật avatar thành công')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cập nhật avatar thất bại')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
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
                        GestureDetector(
                          onTap: () {
                            if (_user?.profilePicture != null &&
                                _user!.profilePicture!.isNotEmpty) {
                              _openAvatarPreview(_user!.profilePicture!);
                            } else {
                              // If no avatar yet, trigger upload flow directly (will implement with icon tap later)
                            }
                          },
                          child: Hero(
                            tag: 'user_avatar_preview',
                            child: CircleAvatar(
                              radius: 48,
                              backgroundColor: Colors.white24,
                              backgroundImage:
                                  _user?.profilePicture != null &&
                                      _user!.profilePicture!.isNotEmpty
                                  ? NetworkImage(_user!.profilePicture!)
                                  : null,
                              child:
                                  (_user?.profilePicture == null ||
                                      _user!.profilePicture!.isEmpty)
                                  ? const Icon(
                                      Icons.person,
                                      color: Colors.white54,
                                      size: 40,
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      if (!_loading)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () {
                              _startAvatarPickFlow();
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              padding: const EdgeInsets.all(4),
                              child: Icon(
                                (_user?.profilePicture != null &&
                                        _user!.profilePicture!.isNotEmpty)
                                    ? Icons.edit
                                    : Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
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
              // Biography centered directly below username (if any)
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _loading
                    ? const SizedBox(height: 0, width: 0)
                    : (_user?.biography != null && _user!.biography!.isNotEmpty)
                    ? Padding(
                        key: const ValueKey('bio'),
                        padding: const EdgeInsets.only(top: 8.0),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 320),
                          child: Text(
                            _user!.biography!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              height: 1.35,
                            ),
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              const SizedBox(height: 28),
              AnimatedAppear(
                delay: const Duration(milliseconds: 140),
                child: _buildIdentitySection(),
              ),
              const SizedBox(height: 28),
              AnimatedAppear(
                delay: const Duration(milliseconds: 200),
                child: _SectionTitle(title: 'Tài khoản'),
              ),
              if (_loading)
                ..._buildMenuSection(
                  loading: true,
                  items: const [_UserMenuItem(text: 'Thông tin người dùng')],
                )
              else
                _UserMenuItem(
                  text: 'Thông tin người dùng',
                  onTap: () async {
                    if (_user == null) return;
                    final changed = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => UserInfoScreen(user: _user!),
                      ),
                    );
                    if (changed == true) {
                      _fetchProfile();
                    }
                  },
                ),
              const SizedBox(height: 16),
              AnimatedAppear(
                delay: const Duration(milliseconds: 220),
                child: _SectionTitle(title: 'General'),
              ),
              if (_loading)
                ..._buildMenuSection(
                  loading: true,
                  items: const [_UserMenuItem(text: 'Subscription')],
                )
              else if (_shouldShowSubscriptionButton())
                _UserMenuItem(
                  text: 'Nâng cấp Premium',
                  onTap: _openSubscriptionPlans,
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

  Widget _buildIdentitySection() {
    if (_loading) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            SkeletonBox(
              width: 90,
              height: 16,
              borderRadius: BorderRadius.all(Radius.circular(6)),
            ),
            SizedBox(height: 8),
            SkeletonBox(
              width: 160,
              height: 14,
              borderRadius: BorderRadius.all(Radius.circular(6)),
            ),
            SizedBox(height: 12),
            SkeletonBox(
              width: double.infinity,
              height: 46,
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ],
        ),
      );
    }
    final role = _user?.role ?? 'GYMER';
    final premium = _user?.premiumStatus == true;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: premium
                      ? const LinearGradient(
                          colors: [Color(0xFF6A35C8), Color(0xFF8854FF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: premium ? null : Colors.white12,
                  borderRadius: BorderRadius.circular(30),
                  border: premium
                      ? Border.all(color: Colors.white24, width: 1)
                      : null,
                ),
                child: Text(
                  premium ? 'Premium' : 'Miễn phí',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: .3,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  role,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool _shouldShowSubscriptionButton() {
    // Giả định role gymer đến từ backend (chưa có trong UserModel => tạm dự phòng bằng premiumStatus logic).
    // Nếu sau này có field role trong UserModel thì bổ sung kiểm tra: _user.role == 'GYMER'
    if (_user == null) return false;
    return !_user!.premiumStatus; // chỉ hiện khi chưa premium
  }

  Future<void> _openSubscriptionPlans() async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return const _SubscriptionPlansSheet();
      },
    );
    if (result == 'upgraded') {
      // Refetch profile to reflect new premium status (mock upgrade)
      _fetchProfile();
    }
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

// Stats removed per request

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
  final String text;
  final VoidCallback? onTap;
  const _UserMenuItem({required this.text, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(text, style: const TextStyle(color: Colors.white)),
      trailing: const Icon(Icons.chevron_right, color: Colors.white54),
      onTap: onTap ?? () {},
    );
  }
}

class _SubscriptionPlansSheet extends StatefulWidget {
  const _SubscriptionPlansSheet();

  @override
  State<_SubscriptionPlansSheet> createState() =>
      _SubscriptionPlansSheetState();
}

class _SubscriptionPlansSheetState extends State<_SubscriptionPlansSheet> {
  late Future<List<SubscriptionPlanModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = SubscriptionsRepository.instance.listPlans();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF12101A),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: Colors.white12, width: 1),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const Text(
                'Chọn gói Premium',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: FutureBuilder<List<SubscriptionPlanModel>>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return _errorState();
                    }
                    final plans = snapshot.data ?? [];
                    if (plans.isEmpty) {
                      return _emptyState();
                    }
                    return ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: plans.length,
                      itemBuilder: (ctx, i) => _PlanCard(plan: plans[i]),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _errorState() => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Text('Lỗi tải gói', style: TextStyle(color: Colors.white70)),
      const SizedBox(height: 12),
      AppButton.outline(
        label: 'Thử lại',
        onPressed: () {
          setState(() {
            _future = SubscriptionsRepository.instance.listPlans();
          });
        },
      ),
    ],
  );

  Widget _emptyState() => const Center(
    child: Text('Chưa có gói nào', style: TextStyle(color: Colors.white70)),
  );
}

class _PlanCard extends StatelessWidget {
  final SubscriptionPlanModel plan;
  const _PlanCard({required this.plan});

  String _formatPrice(int price, String currency) {
    final s = price.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final reverseIndex = s.length - i;
      buf.write(s[i]);
      if (reverseIndex > 1 && reverseIndex % 3 == 1) {
        buf.write('.');
      }
    }
    return '${buf.toString()} $currency';
  }

  Future<void> _performPurchase(BuildContext context) async {
    final repo = SubscriptionsRepository.instance;
    AppSnackBar.showInfo(context, 'Đang xử lý thanh toán...');
    final ok = await repo.purchase(
      planId: plan.id,
      method: 'MOMO',
      providerToken: 'string',
    );
    if (!context.mounted) return;
    if (ok) {
      AppSnackBar.showSuccess(context, 'Mua gói thành công');
      Navigator.pop(context, 'upgraded');
    } else {
      AppSnackBar.showError(context, 'Thanh toán thất bại');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF512DA8), Color(0xFF6A35C8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            offset: const Offset(0, 6),
            blurRadius: 16,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  plan.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.schedule, color: Colors.white70, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${plan.durationMonths} tháng',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _formatPrice(plan.price, plan.currency),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          AppButton.gradient(
            label: 'Chọn gói này',
            size: AppButtonSize.small,
            fullWidth: false,
            onPressed: () => _performPurchase(context),
          ),
        ],
      ),
    );
  }
}

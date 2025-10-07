import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../widgets/pill_tab_bar.dart';
import '../../widgets/appointment_card.dart';
import '../../repositories/appointments_repository.dart';
import '../../repositories/current_user_repository.dart';
import 'appointment_detail_screen.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _appointmentsRepo = AppointmentsRepository();
  final _currentUserRepo = CurrentUserRepository();

  List<AppointmentModel> _upcomingAppointments = [];
  List<AppointmentModel> _completedAppointments = [];
  List<AppointmentModel> _cancelledAppointments = [];

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchAppointments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _fetchAppointments() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final profile = await _currentUserRepo.fetchProfile();
      final roleEntity = await _currentUserRepo.fetchRoleEntity();

      List<AppointmentModel> appointments = [];

      if (profile?.role == 'COACH' && roleEntity is CoachByUserResult) {
        appointments = await _appointmentsRepo.fetchByCoach(roleEntity.id);
      } else if (profile?.role == 'GYMER' && roleEntity is GymerByUserResult) {
        appointments = await _appointmentsRepo.fetchByGymer(roleEntity.id);
      }

      // Phân loại cuộc hẹn theo trạng thái (yêu cầu mới):
      // - Sắp tới: PENDING hoặc CONFIRMED
      // - Hoàn thành: COMPLETED
      // - Hủy bỏ: CANCELED (phòng khi API dùng CANCELED) hoặc CANCELLED
      _upcomingAppointments = appointments.where((a) {
        final s = a.status.toUpperCase();
        return s == 'PENDING' || s == 'CONFIRMED';
      }).toList();
      // Sắp xếp: ưu tiên CONFIRMED trước rồi theo thời gian gần nhất
      _upcomingAppointments.sort((a, b) {
        final aConfirmed = a.status.toUpperCase() == 'CONFIRMED' ? 0 : 1;
        final bConfirmed = b.status.toUpperCase() == 'CONFIRMED' ? 0 : 1;
        if (aConfirmed != bConfirmed) {
          return aConfirmed - bConfirmed; // 0 trước 1
        }
        final aDate = a.date;
        final bDate = b.date;
        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1; // null xuống cuối
        if (bDate == null) return -1;
        return aDate.compareTo(bDate); // thời gian gần nhất lên trước
      });
      _completedAppointments = appointments.where((a) {
        final s = a.status.toUpperCase();
        return s == 'COMPLETED';
      }).toList();
      _cancelledAppointments = appointments.where((a) {
        final s = a.status.toUpperCase();
        return s == 'CANCELED' || s == 'CANCELLED';
      }).toList();

      setState(() {
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Không thể tải danh sách cuộc hẹn: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios,
              color: Colors.white,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Cuộc hẹn',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              onPressed: _fetchAppointments,
              icon: const Icon(Icons.refresh, color: Colors.white, size: 22),
            ),
          ],
          bottom: _buildTabBar(),
        ),
        body: _loading
            ? _buildLoadingState()
            : _error != null
            ? _buildErrorState()
            : _buildTabBarView(),
      ),
    );
  }

  PreferredSizeWidget _buildTabBar() {
    return PillTabBar(
      controller: _tabController,
      labels: const ['Sắp tới', 'Hoàn thành', 'Hủy bỏ'],
      horizontalPadding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      height: kTextTabBarHeight + 20,
      labelStyle: const TextStyle(
        fontSize: 14.5,
        fontWeight: FontWeight.w600,
        letterSpacing: .2,
      ),
      unselectedLabelStyle: const TextStyle(
        fontSize: 14.5,
        fontWeight: FontWeight.w500,
        letterSpacing: .1,
      ),
    );
  }

  Widget _buildTabBarView() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildAppointmentsList(_upcomingAppointments, 'upcoming'),
        _buildAppointmentsList(_completedAppointments, 'completed'),
        _buildAppointmentsList(_cancelledAppointments, 'cancelled'),
      ],
    );
  }

  Widget _buildAppointmentsList(
    List<AppointmentModel> appointments,
    String type,
  ) {
    if (appointments.isEmpty) {
      return _buildEmptyState(type);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: appointments.length,
      itemBuilder: (context, index) {
        final appt = appointments[index];
        return AppointmentCard(
          appointment: appt,
          type: type,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AppointmentDetailScreen(
                  appointmentId: appt.id,
                  initial: appt,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(String type) {
    String title = '';
    String subtitle = '';
    IconData icon = Icons.event_note;

    switch (type) {
      case 'upcoming':
        title = 'Chưa có cuộc hẹn nào';
        subtitle = 'Các cuộc hẹn sắp tới sẽ hiển thị tại đây';
        icon = Icons.upcoming;
        break;
      case 'completed':
        title = 'Chưa có cuộc hẹn hoàn thành';
        subtitle = 'Lịch sử các cuộc hẹn đã hoàn thành';
        icon = Icons.check_circle_outline;
        break;
      case 'cancelled':
        title = 'Chưa có cuộc hẹn nào bị hủy';
        subtitle = 'Các cuộc hẹn đã hủy sẽ hiển thị tại đây';
        icon = Icons.cancel_outlined;
        break;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(.1),
                    Colors.white.withOpacity(.05),
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withOpacity(.1),
                  width: 1,
                ),
              ),
              child: Icon(icon, color: Colors.white.withOpacity(.6), size: 36),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withOpacity(.6),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          height: 140,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.05),
            borderRadius: BorderRadius.circular(20),
          ),
        );
      },
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red.withOpacity(.7),
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              'Có lỗi xảy ra',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Không thể tải dữ liệu',
              style: TextStyle(
                color: Colors.white.withOpacity(.6),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: _fetchAppointments,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'Thử lại',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Các action (hủy / đổi lịch) đã được gỡ khỏi card theo yêu cầu UI tối giản.
  // Nếu cần thêm lại: triển khai tại đây và bổ sung callback sang AppointmentCard.
}

import 'package:flutter/material.dart';
import '../../core/extensions/color_extensions.dart';
import '../../widgets/workout_exercise_card.dart';
import 'workout_exercise_detail_screen.dart';
import '../../repositories/workout_plans_repository.dart';
import '../../widgets/app_snack_bar.dart';
import '../../widgets/app_button.dart';
import '../../widgets/plan_actions_menu.dart';
import '../../widgets/destructive_confirm_sheet.dart';
import '../../utils/date_utils.dart';

/// WorkoutDetailScreen: Màn hình chi tiết kế hoạch tập luyện khi click vào WorkoutCard
/// Hiển thị danh sách các ngày tập của một kế hoạch tập luyện
class WorkoutDetailScreen extends StatefulWidget {
  final String planId; // now required for real data
  final String image;
  final String title;
  final String? subtitle;
  final String? description;
  const WorkoutDetailScreen({
    required this.planId,
    required this.image,
    required this.title,
    this.subtitle,
    this.description,
    super.key,
  });
  @override
  State<WorkoutDetailScreen> createState() => _WorkoutDetailScreenState();
}

class _WorkoutDetailScreenState extends State<WorkoutDetailScreen> {
  int? selectedExerciseIndex;
  final _repo = WorkoutPlansRepository();
  Future<List<WorkoutDayModel>>? _futureDays;
  List<WorkoutDayModel> _days = [];
  bool _creating = false;
  // Local mutable fields for plan (edited via dialog)
  late String _planName;
  String? _planDescription;
  String? _planType; // FLEXIBILITY, STRENGTH, CARDIO, COMBINED
  bool _loadingPlanMeta = false;
  // bool _updatingPlanType = false; // no longer needed (read-only display)

  static const Map<String, String> _planTypeVN = {
    'STRENGTH': 'Sức mạnh',
    'FLEXIBILITY': 'Dẻo dai',
    'CARDIO': 'Sức bền',
    'COMBINED': 'Kết hợp',
  };

  String _planTypeLabel(String? v) =>
      v == null ? 'Chưa chọn' : (_planTypeVN[v] ?? v);

  Future<void> _openDayDetail(int idx) async {
    if (idx < 0 || idx >= _days.length) return;
    final day = _days[idx];
    final dateStr = day.date != null
        ? AppDateUtils.formatDdMMyyyy(day.date!)
        : AppDateUtils.formatDdMMyyyy(DateTime.now().add(Duration(days: idx)));
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkoutExerciseDetailScreen(
          workoutDayId: day.id,
          workoutPlanId: widget.planId,
          dayNumber: day.dayNumber ?? idx + 1,
          dayTitle: 'Ngày ${day.dayNumber ?? idx + 1}',
          date: dateStr,
          calories: '200 calories',
          backgroundImage: widget.image,
        ),
      ),
    );
    if (!mounted) return;
    if (result is Map) {
      final preserveId = result['id'] as String?;
      bool shouldRefetch = false;
      if (result['deleted'] == true) {
        shouldRefetch = true;
      }
      if (result['updatedDate'] != null || result['updatedDateIso'] != null) {
        shouldRefetch = true;
        if (preserveId != null) {
          final idxLocal = _days.indexWhere((d) => d.id == preserveId);
          if (idxLocal != -1) {
            DateTime? parsed;
            final iso = result['updatedDateIso'] as String?;
            if (iso != null) {
              parsed = DateTime.tryParse(iso);
              if (parsed != null) {
                parsed = AppDateUtils.normalizeToLocalDate(parsed);
              }
            }
            if (parsed == null) {
              parsed = AppDateUtils.parseIsoOrDisplay(
                result['updatedDate'] as String?,
              );
            }
            if (parsed != null) {
              final original = _days[idxLocal];
              _days[idxLocal] = WorkoutDayModel(
                id: original.id,
                workoutPlanId: original.workoutPlanId,
                dayNumber: original.dayNumber,
                date: parsed,
              );
              setState(() {}); // Optimistic hiển thị ngay
            }
          }
        }
      }
      if (shouldRefetch) {
        await _refetchAndPreserve(preserveId: preserveId);
      }
    } else {
      // Edge case: pop không trả map (gesture iOS...) -> vẫn refetch để đồng bộ
      await _refetchAndPreserve();
    }
  }

  @override
  void initState() {
    super.initState();
    _planName = widget.title;
    _planDescription = widget.description;
    _futureDays = _fetchDays();
    _loadPlanMeta();
  }

  Future<void> _loadPlanMeta() async {
    if (_loadingPlanMeta) return;
    setState(() => _loadingPlanMeta = true);
    try {
      final plan = await _repo.getPlan(widget.planId);
      if (!mounted) return;
      if (plan != null) {
        setState(() {
          _planType = plan.planType != 'UNKNOWN' ? plan.planType : _planType;
          // Only override name/description if they weren't provided (defensive)
          if (_planName.isEmpty) _planName = plan.name;
          if (_planDescription == null || _planDescription!.isEmpty) {
            _planDescription = plan.description;
          }
        });
      }
    } catch (_) {
      // silent; could add logging/snackbar if desired
    } finally {
      if (mounted) setState(() => _loadingPlanMeta = false);
    }
  }

  // Removed interactive plan type picker; display now read-only.

  Future<List<WorkoutDayModel>> _fetchDays() async {
    try {
      final days = await _repo.getPlanDays(widget.planId);
      if (!mounted) return [];
      setState(() {
        _days = days;
        if (_days.isNotEmpty &&
            (selectedExerciseIndex == null ||
                selectedExerciseIndex! >= _days.length)) {
          selectedExerciseIndex = 0;
        }
        _futureDays = Future.value(
          days,
        ); // cập nhật future để FutureBuilder rebuild nếu cần
      });
      return days;
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Lỗi tải ngày tập (mock mode?): $e');
      }
      return [];
    }
  }

  Future<void> _openEditPlanDialog() async {
    // Pre-fill values
    final nameController = TextEditingController(text: _planName);
    final descController = TextEditingController(text: _planDescription ?? '');
    String? selectedType = _planType; // keep previous choice if set

    final result = await showDialog<_EditPlanResult>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final formKey = GlobalKey<FormState>();
        bool saving = false;
        // remove expandType (using overlay menu instead)
        const Map<String, Color> typeColors = {
          'STRENGTH': Colors.pinkAccent,
          'FLEXIBILITY': Color(0xFF26A69A),
          'CARDIO': Color(0xFFFF9800),
          'COMBINED': Color(0xFF9C27B0),
        };
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Material(
                  color: Colors.transparent,
                  elevation: 18,
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF1F1F1F), Color(0xFF141414)],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.07),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.65),
                          blurRadius: 28,
                          offset: const Offset(0, 18),
                        ),
                        BoxShadow(
                          color: Colors.pinkAccent.withOpacity(0.1),
                          blurRadius: 36,
                          spreadRadius: -4,
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(26, 26, 26, 18),
                      child: Form(
                        key: formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Expanded(
                                  child: Text(
                                    'Chỉnh sửa kế hoạch',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: .3,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.white54,
                                  ),
                                  splashRadius: 22,
                                  onPressed: saving
                                      ? null
                                      : () => Navigator.pop(context),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: nameController,
                              enabled: !saving,
                              decoration: _fieldDecoration('Tên kế hoạch'),
                              style: const TextStyle(color: Colors.white),
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Không được để trống'
                                  : null,
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                            ),
                            const SizedBox(height: 18),
                            Text(
                              'Loại kế hoạch',
                              style: TextStyle(
                                color: Colors.white.withOpacity(.9),
                                fontSize: 13,
                                letterSpacing: .2,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 10),
                            // Compact selector that opens an overlay menu (no dialog height change)
                            _PlanTypeCompactSelector(
                              selectedType: selectedType,
                              typeColors: typeColors,
                              labelBuilder: _planTypeLabel,
                              enabled: !saving,
                              onPick: (t) =>
                                  setStateDialog(() => selectedType = t),
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: descController,
                              enabled: !saving,
                              maxLines: 4,
                              decoration: _fieldDecoration('Mô tả'),
                              style: const TextStyle(color: Colors.white),
                            ),
                            const SizedBox(height: 30),
                            Row(
                              children: [
                                Expanded(
                                  child: AppButton.outline(
                                    label: 'Huỷ',
                                    size: AppButtonSize.medium,
                                    onPressed: saving
                                        ? null
                                        : () => Navigator.pop(context),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: AppButton.primary(
                                    label: 'Lưu',
                                    size: AppButtonSize.medium,
                                    loading: saving,
                                    onPressed: saving
                                        ? null
                                        : () async {
                                            if (!formKey.currentState!
                                                .validate())
                                              return;
                                            setStateDialog(() => saving = true);
                                            final patched = await _repo
                                                .updatePlan(
                                                  widget.planId,
                                                  name: nameController.text
                                                      .trim(),
                                                  description: descController
                                                      .text
                                                      .trim(),
                                                  planType: selectedType,
                                                );
                                            setStateDialog(
                                              () => saving = false,
                                            );
                                            if (patched != null) {
                                              Navigator.pop(
                                                context,
                                                _EditPlanResult(
                                                  nameController.text.trim(),
                                                  descController.text
                                                          .trim()
                                                          .isEmpty
                                                      ? null
                                                      : descController.text
                                                            .trim(),
                                                  selectedType,
                                                ),
                                              );
                                            } else {
                                              AppSnackBar.showError(
                                                context,
                                                'Cập nhật thất bại',
                                              );
                                            }
                                          },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() {
        _planName = result.name;
        _planDescription = result.description;
        _planType = result.planType;
      });
      if (mounted) {
        AppSnackBar.showSuccess(context, 'Đã cập nhật kế hoạch');
      }
    }
  }

  InputDecoration _fieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      filled: true,
      fillColor: const Color(0xFF1E1E1E),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.pinkAccent, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  Future<void> _refetchAndPreserve({String? preserveId}) async {
    final prevId = preserveId;
    final prevSelected = selectedExerciseIndex;
    final days = await _fetchDays();
    if (!mounted) return;
    if (days.isEmpty) {
      setState(() => selectedExerciseIndex = null);
      return;
    }
    if (prevId != null) {
      final idx = _days.indexWhere((d) => d.id == prevId);
      if (idx != -1) {
        setState(() => selectedExerciseIndex = idx);
        return;
      }
    }
    if (prevSelected != null && prevSelected < _days.length) {
      setState(() => selectedExerciseIndex = prevSelected);
    }
  }

  Future<void> _addDay() async {
    if (_creating) return;
    setState(() => _creating = true);
    try {
      final nextNumber = _days.isEmpty
          ? 1
          : (_days
                    .where((d) => d.dayNumber != null)
                    .map((d) => d.dayNumber!)
                    .fold<int>(0, (p, c) => c > p ? c : p) +
                1);
      final created = await _repo.createDay(
        widget.planId,
        dayNumber: nextNumber,
        date: DateTime.now().add(Duration(days: nextNumber - 1)),
      );
      if (created != null) {
        _days.add(created);
        _days.sort((a, b) => (a.dayNumber ?? 0).compareTo(b.dayNumber ?? 0));
        selectedExerciseIndex = _days.length - 1;
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Lỗi tạo ngày: $e');
      }
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // Header với hình nền - chiều cao cố định
          SizedBox(
            height: 250,
            width: double.infinity,
            child: Stack(
              children: [
                // Hình nền
                Positioned.fill(
                  child: widget.image.isNotEmpty
                      ? Image.asset(
                          widget.image,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(color: Colors.deepPurple[300]),
                        )
                      : Container(color: Colors.deepPurple[300]),
                ),
                // Overlay gradient
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.compatOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ),
                // App bar buttons
                Positioned(
                  top: MediaQuery.of(context).padding.top,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      PlanActionsMenu(
                        onAction: (action) async {
                          switch (action) {
                            case PlanAction.edit:
                              await _openEditPlanDialog();
                              break;
                            case PlanAction.delete:
                              final confirmed = await showModalBottomSheet<bool>(
                                context: context,
                                backgroundColor: Colors.transparent,
                                builder: (ctx) => DestructiveConfirmSheet(
                                  title: 'Xoá kế hoạch',
                                  message:
                                      'Bạn chắc chắn muốn xoá kế hoạch này? Hành động không thể hoàn tác.',
                                  confirmLabel: 'Xoá',
                                  onConfirm: () => Navigator.pop(ctx, true),
                                ),
                              );
                              if (confirmed == true) {
                                final deleted = await _repo.deletePlan(
                                  widget.planId,
                                );
                                if (!mounted) return;
                                if (deleted != null) {
                                  AppSnackBar.showSuccess(
                                    context,
                                    'Đã xoá kế hoạch',
                                  );
                                  Navigator.pop(context, {
                                    'deleted': true,
                                    'id': deleted.id,
                                    'name': deleted.name,
                                  });
                                } else {
                                  AppSnackBar.showError(
                                    context,
                                    'Xoá thất bại',
                                  );
                                }
                              }
                              break;
                          }
                        },
                      ),
                    ],
                  ),
                ),
                // Title + type chip overlayed near bottom
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 14,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _planName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          height: 1.15,
                          letterSpacing: .3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: Colors.pinkAccent.withOpacity(.55),
                                width: 1,
                              ),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  const Color(0xFF2A2A2A),
                                  Colors.pinkAccent.withOpacity(.18),
                                ],
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.auto_graph,
                                  size: 15,
                                  color: Colors.white70,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  _planTypeLabel(_planType),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (widget.subtitle != null) ...[
                            const SizedBox(width: 10),
                            Row(
                              children: [
                                const Icon(
                                  Icons.person,
                                  color: Colors.white70,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  widget.subtitle!,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Nội dung chi tiết - phần còn lại của màn hình
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  // Thông tin thời lượng và buổi tập
                  FutureBuilder<List<WorkoutDayModel>>(
                    future: _futureDays,
                    builder: (context, snapshot) {
                      final len = _days.length;
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      }
                      return Row(
                        children: [
                          const Icon(
                            Icons.schedule,
                            color: Colors.orange,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$len ngày',
                            style: const TextStyle(
                              color: Colors.orange,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  if (widget.description != null) ...[
                    const SizedBox(height: 20),
                    Text(
                      (_planDescription ?? widget.description)!,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  // Danh sách ngày tập trong khung cố định
                  if (_days.isNotEmpty) ...[
                    const Text(
                      'Lịch trình tập luyện',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Container có chiều cao cố định với scroll riêng
                    Container(
                      height: 320, // Tăng chiều cao một chút
                      decoration: BoxDecoration(
                        color: Colors.grey[900]?.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.grey[700]!,
                          width: 0.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          // Header của danh sách
                          Container(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_month,
                                  color: Colors.orange,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${_days.length} ngày tập',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${_days.length} ngày (chưa có trạng thái)',
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Divider
                          Container(height: 0.5, color: Colors.grey[700]),
                          // Danh sách có thể scroll
                          Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.all(12),
                              itemCount: _days.length,
                              itemBuilder: (context, index) {
                                final day = _days[index];
                                return WorkoutExerciseCard(
                                  exerciseNumber: index + 1,
                                  title: 'Ngày ${day.dayNumber ?? index + 1}',
                                  description: day.date != null
                                      ? AppDateUtils.formatDdMMyyyy(day.date!)
                                      : 'Không có ngày',
                                  isActive:
                                      selectedExerciseIndex ==
                                      index, // Sử dụng selectedIndex
                                  isCompleted: false,
                                  onTap: () {
                                    // Chỉ select ngày tập, không navigate
                                    setState(() {
                                      selectedExerciseIndex = index;
                                    });
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                  // Thêm ngày tập luyện button
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: AppButton.outline(
                      label: _creating ? 'Đang tạo...' : 'Thêm ngày tập luyện',
                      size: AppButtonSize.medium,
                      loading: _creating,
                      leadingIcon: _creating ? null : Icons.add,
                      onPressed: _creating ? null : _addDay,
                    ),
                  ),
                  // Bắt đầu luyện tập button
                  AppButton.primary(
                    label:
                        selectedExerciseIndex != null &&
                            selectedExerciseIndex! < _days.length
                        ? 'Bắt đầu Ngày ${_days[selectedExerciseIndex!].dayNumber ?? selectedExerciseIndex! + 1}'
                        : 'Chọn ngày tập để bắt đầu',
                    size: AppButtonSize.large,
                    onPressed:
                        selectedExerciseIndex != null &&
                            selectedExerciseIndex! < _days.length
                        ? () {
                            final idx = selectedExerciseIndex!;
                            _openDayDetail(idx);
                          }
                        : null,
                    leadingIcon:
                        selectedExerciseIndex != null &&
                            selectedExerciseIndex! < _days.length
                        ? Icons.fitness_center
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // (Local helpers _getWorkoutDate & _formatDisplayDate removed – centralized in AppDateUtils)
}

class _EditPlanResult {
  final String name;
  final String? description;
  final String? planType;
  _EditPlanResult(this.name, this.description, this.planType);
}

class _PlanTypeCompactSelector extends StatefulWidget {
  final String? selectedType;
  final Map<String, Color> typeColors;
  final String Function(String?) labelBuilder;
  final bool enabled;
  final ValueChanged<String> onPick;
  const _PlanTypeCompactSelector({
    required this.selectedType,
    required this.typeColors,
    required this.labelBuilder,
    required this.enabled,
    required this.onPick,
  });

  @override
  State<_PlanTypeCompactSelector> createState() =>
      _PlanTypeCompactSelectorState();
}

class _PlanTypeCompactSelectorState extends State<_PlanTypeCompactSelector> {
  final LayerLink _link = LayerLink();
  OverlayEntry? _entry;
  bool get _open => _entry != null;
  static const _types = ['FLEXIBILITY', 'STRENGTH', 'CARDIO', 'COMBINED'];

  void _toggle() {
    if (!widget.enabled) return;
    if (_open) {
      _close();
    } else {
      _openMenu();
    }
  }

  void _openMenu() {
    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox?;
    final size = renderBox?.size ?? const Size(0, 0);
    _entry = OverlayEntry(
      builder: (ctx) {
        return Positioned(
          width: size.width,
          child: CompositedTransformFollower(
            link: _link,
            showWhenUnlinked: false,
            offset: Offset(0, size.height + 8),
            child: Material(
              color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1F1F1F),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(.08),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(.6),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final t in _types)
                      _TypeMenuItem(
                        active: t == widget.selectedType,
                        label: widget.labelBuilder(t),
                        color: widget.typeColors[t] ?? Colors.pinkAccent,
                        onTap: () {
                          widget.onPick(t);
                          _close();
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
    overlay.insert(_entry!);
  }

  void _close() {
    _entry?.remove();
    _entry = null;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.selectedType != null
        ? (widget.typeColors[widget.selectedType] ?? Colors.pinkAccent)
        : Colors.pinkAccent;
    return CompositedTransformTarget(
      link: _link,
      child: GestureDetector(
        onTap: _toggle,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.selectedType == null
                  ? Colors.white.withOpacity(.18)
                  : activeColor.withOpacity(.85),
              width: 1.05,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [const Color(0xFF242424), activeColor.withOpacity(.18)],
            ),
          ),
          child: Row(
            children: [
              Icon(
                _open ? Icons.expand_less : Icons.expand_more,
                color: Colors.white70,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.selectedType == null
                      ? 'Chọn loại kế hoạch'
                      : widget.labelBuilder(widget.selectedType),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (widget.selectedType != null)
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: activeColor.withOpacity(.9),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypeMenuItem extends StatelessWidget {
  final bool active;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _TypeMenuItem({
    required this.active,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: active ? color.withOpacity(.15) : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(
              active ? Icons.radio_button_checked : Icons.radio_button_off,
              color: active ? color : Colors.white38,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: active ? Colors.white : Colors.white.withOpacity(.8),
                  fontSize: 13.6,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            if (active) Icon(Icons.check, color: color, size: 18),
          ],
        ),
      ),
    );
  }
}

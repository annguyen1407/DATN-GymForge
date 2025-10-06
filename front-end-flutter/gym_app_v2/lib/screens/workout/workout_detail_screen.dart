import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import '../../core/extensions/color_extensions.dart';
import '../../widgets/workout_exercise_card.dart';
import 'workout_exercise_detail_screen.dart';
import '../../repositories/workout_plans_repository.dart';
import '../../widgets/app_snack_bar.dart';
import '../../widgets/app_button.dart';
import '../../widgets/plan_actions_menu.dart';
import '../../widgets/destructive_confirm_sheet.dart';
import '../../utils/date_utils.dart';
import '../../widgets/plan_type_badge.dart';
import '../../services/storage_service.dart';

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

class _WorkoutDetailScreenState extends State<WorkoutDetailScreen>
    with TickerProviderStateMixin {
  int? selectedExerciseIndex;
  final _repo = WorkoutPlansRepository();
  Future<List<WorkoutDayModel>>? _futureDays;
  List<WorkoutDayModel> _days = [];
  bool _creating = false;
  int _initialDaysCount = 0;
  bool _daysDirty = false; // set true if days length changes
  // Local mutable fields for plan (edited via dialog)
  late String _planName;
  String? _planDescription;
  String? _planType; // FLEXIBILITY, STRENGTH, CARDIO, COMBINED
  String? _planImageUrl; // current remote picture url
  bool _loadingPlanMeta = false;
  // Description expansion state
  bool _descExpanded = false;
  static const int _descPreviewMaxLines = 4;
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
    // Nếu day.date null => không tự sinh ngày (trước đây cộng offset gây hiển thị sai).
    // Truyền chuỗi rỗng để màn chi tiết hiển thị 'Chưa có ngày'.
    final dateStr = day.date != null
        ? AppDateUtils.formatDdMMyyyy(day.date!)
        : '';
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
            parsed ??= AppDateUtils.parseIsoOrDisplay(
              result['updatedDate'] as String?,
            );
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
        if (!mounted) return; // context safety
        setState(() {
          _planType = plan.planType != 'UNKNOWN' ? plan.planType : _planType;
          _planImageUrl = plan.picture ?? _planImageUrl;
          // Only override name/description if they weren't provided (defensive)
          if (_planName.isEmpty) {
            _planName = plan.name;
          }
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
        if (_initialDaysCount == 0) {
          _initialDaysCount = days.length; // capture baseline
        } else if (days.length != _initialDaysCount) {
          _daysDirty = true; // length changed after baseline
        }
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

  Future<File?> _processPickedImage(XFile xfile) async {
    try {
      final original = File(xfile.path);
      final bytes = await original.readAsBytes();
      final decoded = img.decodeImage(bytes);
      final isGif = xfile.name.toLowerCase().endsWith('.gif');
      if (decoded == null || isGif) {
        return original; // keep original for gif or failed decode
      }
      const targetMaxSide = 640;
      const targetMaxBytes = 180 * 1024;
      const minQuality = 45;
      const initialQuality = 78;
      img.Image processed = decoded;
      if (decoded.width > targetMaxSide || decoded.height > targetMaxSide) {
        processed = img.copyResize(
          decoded,
          width: decoded.width >= decoded.height ? targetMaxSide : null,
          height: decoded.height > decoded.width ? targetMaxSide : null,
          interpolation: img.Interpolation.cubic,
        );
      }
      int q = initialQuality;
      var outBytes = img.encodeJpg(processed, quality: q);
      while (outBytes.length > targetMaxBytes && q > minQuality) {
        q -= q > 65 ? 8 : 5;
        if (q < minQuality) q = minQuality;
        outBytes = img.encodeJpg(processed, quality: q);
      }
      final tmp = await getTemporaryDirectory();
      final f = File(
        '${tmp.path}/edit_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await f.writeAsBytes(outBytes, flush: true);
      return f;
    } catch (_) {
      return File(xfile.path);
    }
  }

  Future<void> _openEditPlanDialog() async {
    // Pre-fill values
    final nameController = TextEditingController(text: _planName);
    final descController = TextEditingController(text: _planDescription ?? '');
    String? selectedType = _planType; // keep previous choice if set
    String? workingImageUrl = _planImageUrl; // remote URL (may be removed)
    File? newLocalImage; // picked & processed file (pending upload)
    bool removingImage = false; // user chose to remove existing image

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
            InputDecoration editInput(String hint, {Widget? prefixIcon}) =>
                InputDecoration(
                  hintText: hint,
                  filled: true,
                  fillColor: const Color(0xFF1E1E1E),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  prefixIcon: prefixIcon,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  hintStyle: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w400,
                  ),
                );
            return LayoutBuilder(
              builder: (context, constraints) {
                final viewInsets = MediaQuery.of(context).viewInsets.bottom;
                return AnimatedPadding(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  padding: EdgeInsets.only(bottom: viewInsets * 0.6),
                  child: Center(
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
                              color: Colors.white.withOpacityRatio(0.07),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacityRatio(0.65),
                                blurRadius: 28,
                                offset: const Offset(0, 18),
                              ),
                              BoxShadow(
                                color: Colors.pinkAccent.withOpacityRatio(0.1),
                                blurRadius: 36,
                                spreadRadius: -4,
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(26, 26, 26, 18),
                            child: Form(
                              key: formKey,
                              child: SingleChildScrollView(
                                physics: const BouncingScrollPhysics(),
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
                                      decoration: editInput(
                                        'Tên kế hoạch',
                                        prefixIcon: const Icon(
                                          Icons.dataset,
                                          color: Colors.white70,
                                          size: 20,
                                        ),
                                      ),
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                      validator: (v) =>
                                          (v == null || v.trim().isEmpty)
                                          ? 'Không được để trống'
                                          : null,
                                      autovalidateMode:
                                          AutovalidateMode.onUserInteraction,
                                      textInputAction: TextInputAction.next,
                                    ),
                                    const SizedBox(height: 18),
                                    Text(
                                      'Loại kế hoạch',
                                      style: TextStyle(
                                        color: Colors.white.withOpacityRatio(
                                          .9,
                                        ),
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
                                      onPick: (t) => setStateDialog(
                                        () => selectedType = t,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    TextFormField(
                                      controller: descController,
                                      enabled: !saving,
                                      maxLines: 1,
                                      textInputAction: TextInputAction.done,
                                      keyboardType: TextInputType.text,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.deny(
                                          RegExp(r'\n'),
                                        ),
                                      ],
                                      onFieldSubmitted: (_) =>
                                          FocusScope.of(context).unfocus(),
                                      onEditingComplete: () =>
                                          FocusScope.of(context).unfocus(),
                                      decoration: editInput(
                                        'Mô tả (tuỳ chọn)',
                                        prefixIcon: const Icon(
                                          Icons.notes,
                                          color: Colors.white70,
                                          size: 20,
                                        ),
                                      ),
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    // Move image block here (bottom before actions)
                                    Text(
                                      'Ảnh minh hoạ',
                                      style: TextStyle(
                                        color: Colors.white.withOpacityRatio(
                                          .9,
                                        ),
                                        fontSize: 13,
                                        letterSpacing: .2,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.pinkAccent,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 10,
                                            ),
                                          ),
                                          icon: const Icon(
                                            Icons.photo_library,
                                            size: 18,
                                          ),
                                          label: Text(
                                            newLocalImage != null
                                                ? 'Đổi ảnh'
                                                : (workingImageUrl != null &&
                                                      !removingImage)
                                                ? 'Thay ảnh'
                                                : 'Chọn ảnh',
                                          ),
                                          onPressed: saving
                                              ? null
                                              : () async {
                                                  final picker = ImagePicker();
                                                  final xfile = await picker
                                                      .pickImage(
                                                        source:
                                                            ImageSource.gallery,
                                                        maxWidth: 2000,
                                                        imageQuality: 100,
                                                      );
                                                  if (xfile == null) return;
                                                  final processed =
                                                      await _processPickedImage(
                                                        xfile,
                                                      );
                                                  setStateDialog(() {
                                                    newLocalImage = processed;
                                                    removingImage = false;
                                                  });
                                                },
                                        ),
                                        const SizedBox(width: 12),
                                        if ((workingImageUrl != null ||
                                                newLocalImage != null) &&
                                            !removingImage)
                                          TextButton.icon(
                                            onPressed: saving
                                                ? null
                                                : () {
                                                    setStateDialog(() {
                                                      removingImage = true;
                                                      newLocalImage = null;
                                                      workingImageUrl = null;
                                                    });
                                                  },
                                            icon: const Icon(
                                              Icons.delete_forever,
                                              size: 18,
                                              color: Colors.redAccent,
                                            ),
                                            label: const Text(
                                              'Gỡ ảnh',
                                              style: TextStyle(
                                                color: Colors.redAccent,
                                              ),
                                            ),
                                          ),
                                        if (removingImage)
                                          const Text(
                                            'Sẽ xoá ảnh',
                                            style: TextStyle(
                                              color: Colors.orangeAccent,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    if (!removingImage &&
                                        (newLocalImage != null ||
                                            workingImageUrl != null))
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(14),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: Colors.white
                                                  .withOpacityRatio(.15),
                                              width: 1,
                                            ),
                                          ),
                                          child: newLocalImage != null
                                              ? Image.file(
                                                  newLocalImage!,
                                                  height: 140,
                                                  width: double.infinity,
                                                  fit: BoxFit.cover,
                                                )
                                              : Image.network(
                                                  workingImageUrl!,
                                                  height: 140,
                                                  width: double.infinity,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, __, ___) =>
                                                      Container(
                                                        height: 140,
                                                        alignment:
                                                            Alignment.center,
                                                        color: Colors.grey[800],
                                                        child: const Icon(
                                                          Icons.broken_image,
                                                          color: Colors.white54,
                                                        ),
                                                      ),
                                                ),
                                        ),
                                      ),
                                    if (newLocalImage != null || removingImage)
                                      const SizedBox(height: 6),
                                    if (newLocalImage != null)
                                      Text(
                                        'Sẽ upload ảnh mới khi Lưu',
                                        style: TextStyle(
                                          color: Colors.white.withOpacityRatio(
                                            .55,
                                          ),
                                          fontSize: 11,
                                        ),
                                      ),
                                    if (removingImage &&
                                        workingImageUrl == null)
                                      Text(
                                        'Ảnh sẽ bị xoá khi Lưu',
                                        style: TextStyle(
                                          color: Colors.orangeAccent
                                              .withOpacity(.9),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    const SizedBox(height: 26),
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
                                                    final navigator =
                                                        Navigator.of(context);
                                                    final scaffoldMessenger =
                                                        ScaffoldMessenger.of(
                                                          context,
                                                        );
                                                    if (!formKey.currentState!
                                                        .validate()) {
                                                      return;
                                                    }
                                                    setStateDialog(
                                                      () => saving = true,
                                                    );
                                                    String? finalPictureUrl =
                                                        _planImageUrl; // start from current
                                                    // Handle removal or replacement
                                                    if (newLocalImage != null) {
                                                      // Replace: delete old first if exists
                                                      if (_planImageUrl !=
                                                              null &&
                                                          _planImageUrl!
                                                              .startsWith(
                                                                'http',
                                                              )) {
                                                        await StorageService
                                                            .instance
                                                            .deleteByUrl(
                                                              _planImageUrl!,
                                                            );
                                                      }
                                                      final uploaded =
                                                          await StorageService
                                                              .instance
                                                              .uploadFile(
                                                                file:
                                                                    newLocalImage!,
                                                                folder:
                                                                    'workout-plans',
                                                              );
                                                      if (uploaded != null) {
                                                        finalPictureUrl =
                                                            uploaded;
                                                      } else {
                                                        // Upload failed -> keep old if any
                                                      }
                                                    } else if (removingImage &&
                                                        _planImageUrl != null) {
                                                      // Delete existing image
                                                      if (_planImageUrl!
                                                          .startsWith('http')) {
                                                        await StorageService
                                                            .instance
                                                            .deleteByUrl(
                                                              _planImageUrl!,
                                                            );
                                                      }
                                                      finalPictureUrl = null;
                                                    }
                                                    final patched = await _repo
                                                        .updatePlan(
                                                          widget.planId,
                                                          name: nameController
                                                              .text
                                                              .trim(),
                                                          description:
                                                              descController
                                                                  .text
                                                                  .trim(),
                                                          planType:
                                                              selectedType,
                                                          picture:
                                                              finalPictureUrl,
                                                        );
                                                    setStateDialog(
                                                      () => saving = false,
                                                    );
                                                    if (!mounted) return;
                                                    if (patched != null) {
                                                      navigator.pop(
                                                        _EditPlanResult(
                                                          nameController.text
                                                              .trim(),
                                                          descController.text
                                                                  .trim()
                                                                  .isEmpty
                                                              ? null
                                                              : descController
                                                                    .text
                                                                    .trim(),
                                                          selectedType,
                                                          finalPictureUrl,
                                                        ),
                                                      );
                                                    } else {
                                                      AppSnackBar.showError(
                                                        scaffoldMessenger
                                                            .context,
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
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );

    if (!mounted) return;
    if (result != null) {
      final success = result;
      setState(() {
        _planName = success.name;
        _planDescription = success.description;
        _planType = success.planType;
        _planImageUrl = success.picture;
      });
      AppSnackBar.showSuccess(context, 'Đã cập nhật kế hoạch');
      // Refetch from server to ensure latest authoritative data and relationships
      try {
        await _loadPlanMeta();
        // Days usually unaffected by meta edit, but safe to refresh silently
        await _fetchDays();
      } catch (_) {
        // ignore refresh errors
      }
    }
  }

  // Old _fieldDecoration removed (merged into inline editInput style for unified UI)

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
        if (_days.length != _initialDaysCount) {
          _daysDirty = true;
        }
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Lỗi tạo ngày: $e');
      }
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  Future<bool> _handlePop() async {
    if (_daysDirty) {
      Navigator.pop(context, {
        'updatedDays': _days.length,
        'planId': widget.planId,
      });
    } else {
      Navigator.pop(context);
    }
    return false; // we've handled pop
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _handlePop();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        bottomNavigationBar: _buildBottomActionsBar(),
        body: RefreshIndicator(
          color: Colors.pinkAccent,
          backgroundColor: Colors.black,
          onRefresh: _handleRefresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 230,
                  width: double.infinity,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: _buildHeaderImage(_planImageUrl ?? widget.image),
                      ),
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withOpacity(0.55), // darken top
                                Colors.black.withOpacity(0.10), // mid fade
                                Colors.black.withOpacity(0.75), // strong bottom
                              ],
                              stops: const [0.0, 0.55, 1.0],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: MediaQuery.of(context).padding.top,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                              ),
                              onPressed: _handlePop,
                            ),
                            PlanActionsMenu(
                              onAction: (action) async {
                                switch (action) {
                                  case PlanAction.edit:
                                    await _openEditPlanDialog();
                                    break;
                                  case PlanAction.delete:
                                    final currentContext = context; // capture
                                    final confirmed = await showModalBottomSheet<bool>(
                                      context: currentContext,
                                      backgroundColor: Colors.transparent,
                                      builder: (ctx) => DestructiveConfirmSheet(
                                        title: 'Xoá kế hoạch',
                                        message:
                                            'Bạn chắc chắn muốn xoá kế hoạch này? Hành động không thể hoàn tác.',
                                        confirmLabel: 'Xoá',
                                        onConfirm: () =>
                                            Navigator.pop(ctx, true),
                                      ),
                                    );
                                    if (!mounted || confirmed != true) return;
                                    try {
                                      final deleted = await _repo.deletePlan(
                                        widget.planId,
                                      );
                                      if (!mounted) return;
                                      if (deleted != null) {
                                        // Delete remote image after successful plan deletion
                                        if (deleted.picture != null &&
                                            deleted.picture!.startsWith(
                                              'http',
                                            )) {
                                          await StorageService.instance
                                              .deleteByUrl(deleted.picture!);
                                        }
                                        AppSnackBar.showSuccess(
                                          currentContext,
                                          'Đã xoá kế hoạch',
                                        );
                                        Navigator.of(currentContext).pop({
                                          'deleted': true,
                                          'id': deleted.id,
                                          'name': deleted.name,
                                        });
                                      } else {
                                        AppSnackBar.showError(
                                          currentContext,
                                          'Xoá thất bại',
                                        );
                                      }
                                    } catch (e) {
                                      if (!mounted) return;
                                      AppSnackBar.showError(
                                        currentContext,
                                        'Lỗi xoá: $e',
                                      );
                                    }
                                    break;
                                }
                              },
                            ),
                          ],
                        ),
                      ),
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
                                PlanTypeBadge(planType: _planType),
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
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      FutureBuilder<List<WorkoutDayModel>>(
                        future: _futureDays,
                        builder: (context, snapshot) {
                          final len = _days.length;
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.0),
                              child: SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
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
                      _buildDescriptionSection(),
                      const SizedBox(height: 24),
                      _buildSummaryRow(),
                      const SizedBox(height: 24),
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
                        Container(
                          height: 340,
                          decoration: BoxDecoration(
                            color: Colors.grey[900]?.withOpacityRatio(0.2),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.grey[700]!,
                              width: 0.5,
                            ),
                          ),
                          child: Column(
                            children: [
                              _buildDaysHeader(),
                              Container(height: 0.5, color: Colors.grey[700]),
                              Expanded(
                                child: ListView.builder(
                                  padding: const EdgeInsets.all(12),
                                  itemCount: _days.length,
                                  itemBuilder: (context, index) {
                                    final day = _days[index];
                                    final completed =
                                        (day.status == 'COMPLETED') ||
                                        day.completedAt != null;
                                    String desc;
                                    if (completed) {
                                      final doneDate =
                                          day.completedAt ?? day.date;
                                      final dateStr = doneDate != null
                                          ? AppDateUtils.formatDdMMyyyy(
                                              doneDate,
                                            )
                                          : '';
                                      desc = dateStr.isNotEmpty
                                          ? 'Đã hoàn thành ngày $dateStr'
                                          : 'Đã hoàn thành';
                                    } else if (day.date != null) {
                                      desc = AppDateUtils.formatDdMMyyyy(
                                        day.date!,
                                      );
                                    } else if (day.status == 'PENDING') {
                                      desc = 'Chưa đặt ngày';
                                    } else {
                                      desc = 'Không có ngày';
                                    }
                                    return WorkoutExerciseCard(
                                      exerciseNumber: index + 1,
                                      title:
                                          'Ngày ${day.dayNumber ?? index + 1}',
                                      description: desc,
                                      isActive: selectedExerciseIndex == index,
                                      isCompleted: completed,
                                      onTap: () {
                                        setState(
                                          () => selectedExerciseIndex = index,
                                        );
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
                      const SizedBox(
                        height: 80,
                      ), // space for bottom bar overlay
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // (Local helpers _getWorkoutDate & _formatDisplayDate removed – centralized in AppDateUtils)

  Future<void> _handleRefresh() async {
    await Future.wait([_fetchDays(), _loadPlanMeta()]);
  }

  Widget _buildSummaryRow() {
    if (_days.isEmpty) return const SizedBox.shrink();
    final completed = _days
        .where((d) => d.status == 'COMPLETED' || d.completedAt != null)
        .length;
    return Row(
      children: [
        const Icon(Icons.insights, color: Colors.pinkAccent, size: 18),
        const SizedBox(width: 6),
        Text(
          '$completed/${_days.length} ngày hoàn thành',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        if (completed > 0)
          Text(
            '${((completed / _days.length) * 100).toStringAsFixed(0)}%',
            style: const TextStyle(
              color: Colors.pinkAccent,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }

  Widget _buildDescriptionSection() {
    final raw = _planDescription?.trim().isNotEmpty == true
        ? _planDescription!.trim()
        : (widget.description?.trim() ?? '');
    if (raw.isEmpty) return const SizedBox.shrink();

    // Decide if needs expansion (heuristic: more than X chars or contains newline)
    final needsExpand = raw.length > 180 || raw.contains('\n');

    Widget textWidget = Text(
      raw,
      key: ValueKey(_descExpanded),
      style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
      maxLines: _descExpanded ? null : _descPreviewMaxLines,
      overflow: _descExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
    );

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOutCubic,
            alignment: Alignment.topCenter,
            child: textWidget,
          ),
          if (needsExpand)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: GestureDetector(
                onTap: () => setState(() => _descExpanded = !_descExpanded),
                behavior: HitTestBehavior.opaque,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _descExpanded ? 'Thu gọn' : 'Xem thêm',
                      style: TextStyle(
                        color: Colors.pinkAccent.withOpacityRatio(.9),
                        fontSize: 13.2,
                        fontWeight: FontWeight.w600,
                        letterSpacing: .2,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _descExpanded ? Icons.expand_less : Icons.expand_more,
                      size: 18,
                      color: Colors.pinkAccent.withOpacityRatio(.9),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDaysHeader() {
    final completed = _days
        .where((d) => d.status == 'COMPLETED' || d.completedAt != null)
        .length;
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(Icons.calendar_month, color: Colors.orange, size: 20),
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
          if (completed > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.green.withOpacity(0.4),
                  width: 0.7,
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, size: 14, color: Colors.green),
                  const SizedBox(width: 4),
                  Text(
                    '$completed hoàn thành',
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomActionsBar() {
    final canStart =
        selectedExerciseIndex != null && selectedExerciseIndex! < _days.length;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: const Color(0xFF121212).withOpacityRatio(.96),
          border: Border(
            top: BorderSide(
              color: Colors.white.withOpacityRatio(.08),
              width: 0.6,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacityRatio(.6),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: AppButton.outline(
                label: _creating ? 'Đang tạo...' : 'Thêm ngày',
                size: AppButtonSize.medium,
                loading: _creating,
                leadingIcon: _creating ? null : Icons.add,
                onPressed: _creating ? null : _addDay,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: AppButton.primary(
                label: canStart
                    ? 'Bắt đầu Ngày ${_days[selectedExerciseIndex!].dayNumber ?? selectedExerciseIndex! + 1}'
                    : 'Chọn ngày tập',
                size: AppButtonSize.medium,
                leadingIcon: canStart ? Icons.fitness_center : null,
                onPressed: canStart
                    ? () {
                        final idx = selectedExerciseIndex!;
                        _openDayDetail(idx);
                      }
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension on _WorkoutDetailScreenState {
  Widget _buildHeaderImage(String src) {
    if (src.isEmpty) {
      return Container(color: Colors.deepPurple[300]);
    }
    final isNetwork = src.startsWith('http://') || src.startsWith('https://');
    if (isNetwork) {
      return Image.network(
        src,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Stack(
            fit: StackFit.expand,
            children: [
              Container(color: Colors.deepPurple[200]),
              const Center(
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ],
          );
        },
        errorBuilder: (context, error, stackTrace) =>
            Container(color: Colors.deepPurple[300]),
      );
    }
    // Assume asset path fallback
    return Image.asset(
      src,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) =>
          Container(color: Colors.deepPurple[300]),
    );
  }
}

class _EditPlanResult {
  final String name;
  final String? description;
  final String? planType;
  final String? picture;
  _EditPlanResult(this.name, this.description, this.planType, this.picture);
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
                    color: Colors.white.withOpacityRatio(.08),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacityRatio(.6),
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
    if (_entry != null) {
      try {
        _entry?.remove();
      } catch (_) {
        // ignore removal errors
      }
      _entry = null;
      // Only trigger rebuild if still mounted AND not in dispose phase
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    // Avoid calling setState during dispose; just remove overlay directly
    if (_entry != null) {
      try {
        _entry?.remove();
      } catch (_) {}
      _entry = null;
    }
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
                  ? Colors.white.withOpacityRatio(.18)
                  : activeColor.withOpacityRatio(.85),
              width: 1.05,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF242424),
                activeColor.withOpacityRatio(.18),
              ],
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
                    color: activeColor.withOpacityRatio(.9),
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
          color: active ? color.withOpacityRatio(.15) : Colors.transparent,
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
                  color: active
                      ? Colors.white
                      : Colors.white.withOpacityRatio(.8),
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

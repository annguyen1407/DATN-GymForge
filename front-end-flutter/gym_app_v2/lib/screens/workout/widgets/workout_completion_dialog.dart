import 'package:flutter/material.dart';
import '../../../utils/workout_completion.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/exercise_card.dart';

/// Widget hiển thị dialog hoàn thành buổi tập và thống kê tập luyện
///
/// Sử dụng widget này để hiển thị kết quả và thống kê sau khi hoàn thành một buổi tập.
/// Widget này hỗ trợ việc hiển thị các thông tin như:
/// - Tỉ lệ hoàn thành tập luyện
/// - Thông tin về volume và sets
/// - Chi tiết từng bài tập đã thực hiện
/// - Trạng thái upload logs (nếu có)
class WorkoutCompletionDialog extends StatefulWidget {
  /// Danh sách các bài tập đã lên kế hoạch
  final List<ExerciseItem> exercises;

  /// Dữ liệu tập luyện thực tế đã log
  /// Key: index của bài tập, Value: danh sách các set đã hoàn thành
  /// Mỗi set là một Map với các key: 'set', 'reps', 'weight', 'time'
  final Map<int, List<Map<String, dynamic>>> workoutData;

  /// Tham số tính toán tỉ lệ hoàn thành
  /// Mặc định sẽ sử dụng:
  /// - repValue: 1 (giá trị cho mỗi rep khi không có weight)
  /// - allowOver100: false (giới hạn tối đa 100%)
  /// - maxIntensityMultiplier: 1.2 (cường độ tối đa so với kế hoạch)
  /// - hybridAlpha: 0.8 (trọng số cho volume trong công thức hybrid)
  final WorkoutCompletionCalculatorParams? params;

  /// Callback khi người dùng nhấn nút hoàn thành
  /// Thường được sử dụng để upload logs và điều hướng
  final Future<void> Function()? onComplete;

  /// Flag đánh dấu trạng thái đang upload logs
  /// Khi true, nút hoàn thành sẽ bị disable và hiển thị trạng thái đang upload
  final bool isUploading;

  /// Thông báo trạng thái upload
  /// Hiển thị cùng với loading indicator khi đang upload
  final String uploadStatus;

  /// Nhãn hiển thị trên nút hoàn thành (mặc định: "Lưu và hoàn thành")
  final String? completeButtonLabel;

  const WorkoutCompletionDialog({
    Key? key,
    required this.exercises,
    required this.workoutData,
    this.params,
    this.onComplete,
    this.isUploading = false,
    this.uploadStatus = '',
    this.completeButtonLabel,
  }) : super(key: key);

  @override
  State<WorkoutCompletionDialog> createState() =>
      _WorkoutCompletionDialogState();
}

class _WorkoutCompletionDialogState extends State<WorkoutCompletionDialog> {
  late final WorkoutCompletionResult completion;

  /// Lưu kết quả tính % hoàn thành cho từng bài tập
  final Map<int, WorkoutCompletionResult> _exerciseCompletionResults = {};

  @override
  void initState() {
    super.initState();
    // Tính toán tỉ lệ hoàn thành ngay khi widget được khởi tạo
    final params =
        widget.params ??
        const WorkoutCompletionCalculatorParams(
          repValue: 1, // có thể chỉnh theo bodyweight user trong tương lai
          allowOver100: false,
          maxIntensityMultiplier: 1.2,
          hybridAlpha: 0.8,
        );

    // Tính toán % hoàn thành cho toàn bộ buổi tập
    completion = computeWorkoutCompletion(
      plannedExercises: widget.exercises,
      workoutData: widget.workoutData,
      params: params,
    );

    // Tính toán % hoàn thành cho từng bài tập
    _calculateExerciseCompletions(params);
  }

  /// Tính toán % hoàn thành cho từng bài tập riêng biệt
  void _calculateExerciseCompletions(WorkoutCompletionCalculatorParams params) {
    // Duyệt qua từng bài tập đã lập kế hoạch
    for (int i = 0; i < widget.exercises.length; i++) {
      // Tạo danh sách chỉ chứa bài tập hiện tại
      final singleExercise = [widget.exercises[i]];

      // Tạo dữ liệu tập luyện chỉ cho bài tập hiện tại
      final Map<int, List<Map<String, dynamic>>> singleExerciseData = {};

      // Nếu có dữ liệu log của bài tập này, thêm vào
      if (widget.workoutData.containsKey(i)) {
        // Đặt ở index 0 vì danh sách singleExercise chỉ có 1 phần tử
        singleExerciseData[0] = widget.workoutData[i]!;
      }

      // Tính toán % hoàn thành cho bài tập riêng lẻ
      final result = computeWorkoutCompletion(
        plannedExercises: singleExercise,
        workoutData: singleExerciseData,
        params: params,
      );

      // Lưu kết quả cho bài tập có index i
      _exerciseCompletionResults[i] = result;
    }
  }

  /// Format thời gian thành chuỗi hiển thị
  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins}:${secs.toString().padLeft(2, '0')}';
  }

  Widget _buildStatLine(String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label:',
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.grey[900],
      title: const Row(
        children: [
          Icon(Icons.celebration, color: Colors.orange, size: 28),
          SizedBox(width: 12),
          Text(
            'Hoàn thành!',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Chúc mừng! Bạn đã hoàn thành buổi tập luyện.',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 12),
            // Summary metrics
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[850],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'TỔNG THỂ BUỔI TẬP',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Dòng % hoàn thành chính
                  Text(
                    '${completion.hybridPercent.toStringAsFixed(1)}% hoàn thành',
                    style: TextStyle(
                      color: completion.hybridPercent >= 80
                          ? Colors.green.shade400
                          : (completion.hybridPercent >= 50
                                ? Colors.orange
                                : Colors.red.shade400),
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Thanh progress tổng
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: (completion.hybridPercent / 100).clamp(0.0, 1.0),
                      minHeight: 10,
                      backgroundColor: Colors.grey.shade700,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        completion.hybridPercent >= 80
                            ? Colors.green.shade500
                            : (completion.hybridPercent >= 50
                                  ? Colors.orange
                                  : Colors.red.shade400),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Các dòng thông tin đơn giản
                  Wrap(
                    spacing: 18,
                    runSpacing: 6,
                    children: [
                      _buildStatLine(
                        'Volume',
                        '${completion.volumePercent.toStringAsFixed(1)}%',
                      ),
                      _buildStatLine(
                        'Sets',
                        '${completion.setsPercent.toStringAsFixed(1)}%',
                      ),
                      _buildStatLine(
                        'Load',
                        '${completion.achievedLoad.toStringAsFixed(1)}/${completion.targetLoad.toStringAsFixed(1)}',
                      ),
                      _buildStatLine(
                        'Sets hoàn thành',
                        '${completion.totalSetsDone}/${completion.totalSetsPlanned}',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Row(
              children: [
                Icon(Icons.fitness_center, size: 16, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  'THỐNG KÊ TỪNG BÀI TẬP',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const Divider(color: Colors.white24, height: 24, thickness: 0.5),
            ...widget.exercises.asMap().entries.map((entry) {
              final exerciseIndex = entry.key;
              final exercise = entry.value;
              final exerciseData = widget.workoutData[exerciseIndex] ?? [];

              // Lấy kết quả % hoàn thành của bài tập này
              final exerciseCompletion =
                  _exerciseCompletionResults[exerciseIndex];
              final completionPercent =
                  exerciseCompletion?.hybridPercent.toStringAsFixed(1) ?? '0.0';

              // Xây dựng indicator cho % hoàn thành
              final progressValue =
                  (exerciseCompletion?.hybridPercent ?? 0) / 100;
              final color = progressValue >= 0.8
                  ? Colors.green.shade600
                  : (progressValue >= 0.5
                        ? Colors.orange
                        : Colors.red.shade400);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            exercise.name,
                            style: const TextStyle(
                              color: Colors.orange,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$completionPercent%',
                            style: TextStyle(
                              color: color,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Hiển thị progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progressValue,
                        backgroundColor: Colors.grey.shade700,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        minHeight: 4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Chi tiết volume và sets
                    if (exerciseCompletion != null && exerciseData.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          'Volume: ${exerciseCompletion.volumePercent.toStringAsFixed(1)}% | Sets: ${exerciseCompletion.totalSetsDone}/${exerciseCompletion.totalSetsPlanned}',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    if (exerciseData.isNotEmpty) ...[
                      ...exerciseData.map((setData) {
                        return Padding(
                          padding: const EdgeInsets.only(left: 8, top: 2),
                          child: Text(
                            'Hiệp ${setData['set']}: ${setData['reps']} reps, ${setData['weight']}kg, ${_formatTime(setData['time'] ?? 0)}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        );
                      }),
                    ] else
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          'Không có set nào được ghi nhận',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
      actions: [
        if (widget.isUploading)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.uploadStatus,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        AppButton.primary(
          label: widget.isUploading
              ? 'Đang lưu...'
              : widget.completeButtonLabel ?? 'Lưu và hoàn thành',
          size: AppButtonSize.medium,
          fullWidth: false,
          onPressed: widget.isUploading
              ? null
              : () async {
                  final navigator = Navigator.of(context);
                  if (widget.onComplete != null) {
                    await widget.onComplete!();
                  }
                  if (!mounted) return;
                  navigator.pop(); // close dialog
                },
        ),
      ],
    );
  }
}

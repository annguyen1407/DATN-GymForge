import 'package:flutter/material.dart';
import '../../widgets/exercise_hero_header.dart';
import '../../models/exercise_model.dart';
import '../../core/utils/text_normalizer.dart';
import '../../repositories/exercise_log_repository.dart';

/// New log exercise detail screen (lightweight):
/// - Receives workoutExerciseLogId (id của bản ghi log bài tập)
/// - Shows unified ExerciseHeroHeader
/// - Sections: intro/instruction (gọn), sets, summary
class ExerciseLogDetailScreen extends StatefulWidget {
  final String workoutExerciseLogId;
  final String? exerciseName;
  final List<String> muscleGroups;
  final String? videoAsset;
  final ExerciseModel? exerciseModel;

  const ExerciseLogDetailScreen({
    super.key,
    required this.workoutExerciseLogId,
    this.exerciseName,
    this.muscleGroups = const [],
    this.videoAsset,
    this.exerciseModel,
  });

  @override
  State<ExerciseLogDetailScreen> createState() =>
      _ExerciseLogDetailScreenState();
}

class _ExerciseLogDetailScreenState extends State<ExerciseLogDetailScreen> {
  final _repo = ExerciseLogRepository(baseUrl: '');
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _sets = [];

  @override
  void initState() {
    super.initState();
    _loadSets();
  }

  Future<void> _loadSets() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final data = await _repo.getSetsForWorkoutExerciseLog(
      widget.workoutExerciseLogId,
    );
    if (!mounted) return;
    setState(() {
      _sets = data;
      _loading = false;
    });
  }

  int get _totalTimeSeconds {
    int sum = 0;
    for (final s in _sets) {
      if (s['times'] is num) sum += (s['times'] as num).toInt();
    }
    return sum;
  }

  String _fmtTime(int secs) {
    if (secs <= 0) return '0s';
    final m = secs ~/ 60;
    final s = secs % 60;
    if (m == 0) return '${s}s';
    if (s == 0) return '${m}m';
    return '${m}m ${s}s';
  }

  bool _introExpanded = false;
  bool _instrExpanded = false;

  Widget _buildIntroInstruction(ExerciseModel? model) {
    if (model == null) return const SizedBox.shrink();
    final intro = model.description?.normalizedMultiline().trim();
    final instr = model.instruction?.normalizedMultiline().trim();
    final hasIntro = intro != null && intro.isNotEmpty;
    final hasInstr = instr != null && instr.isNotEmpty;
    if (!hasIntro && !hasInstr) return const SizedBox.shrink();
    const titleStyle = TextStyle(
      color: Colors.white,
      fontSize: 15,
      fontWeight: FontWeight.w600,
      letterSpacing: .2,
    );
    const bodyStyle = TextStyle(
      color: Colors.white70,
      fontSize: 13.5,
      height: 1.45,
      fontWeight: FontWeight.w400,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasIntro)
          _collapsibleSection(
            label: 'Giới thiệu',
            text: intro,
            expanded: _introExpanded,
            onToggle: () => setState(() => _introExpanded = !_introExpanded),
            titleStyle: titleStyle,
            bodyStyle: bodyStyle,
          ),
        if (hasInstr) ...[
          if (hasIntro) const SizedBox(height: 12),
          _collapsibleSection(
            label: 'Hướng dẫn',
            text: instr,
            expanded: _instrExpanded,
            onToggle: () => setState(() => _instrExpanded = !_instrExpanded),
            titleStyle: titleStyle,
            bodyStyle: bodyStyle,
          ),
        ],
      ],
    );
  }

  Widget _collapsibleSection({
    required String label,
    required String text,
    required bool expanded,
    required VoidCallback onToggle,
    required TextStyle titleStyle,
    required TextStyle bodyStyle,
  }) {
    const threshold = 180;
    final isLong = text.length > threshold;
    final maxLines = (isLong && !expanded) ? 4 : null;
    final header = Align(
      alignment: Alignment.centerLeft,
      child: Text(label, style: titleStyle),
    );
    final body = Text(
      text,
      style: bodyStyle,
      maxLines: maxLines,
      overflow: (isLong && !expanded)
          ? TextOverflow.ellipsis
          : TextOverflow.visible,
    );
    final moreButton = isLong
        ? Padding(
            padding: const EdgeInsets.only(top: 6),
            child: InkWell(
              onTap: onToggle,
              borderRadius: BorderRadius.circular(6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    expanded ? 'Thu gọn' : 'Xem thêm',
                    style: const TextStyle(
                      color: Color(0xFFFF4E74),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    expanded ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                    color: const Color(0xFFFF4E74),
                  ),
                ],
              ),
            ),
          )
        : const SizedBox.shrink();
    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [header, const SizedBox(height: 4), body, moreButton],
    );
    if (!isLong) return column;
    return AnimatedSize(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeInOut,
      child: column,
    );
  }

  @override
  Widget build(BuildContext context) {
    final model = widget.exerciseModel;
    final name = model?.name ?? widget.exerciseName ?? 'Bài tập';
    final groups = model?.muscleGroupNames ?? widget.muscleGroups;
    // Determine media sources:
    // videoUrl: YouTube link handled internally by ExerciseHeroHeader
    // backgroundImage: only use provided asset if no video url
    final videoUrl = model?.videoUrl;
    final backgroundImage = (videoUrl == null || videoUrl.isEmpty)
        ? widget.videoAsset
        : null;
    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: ExerciseHeroHeader(
              title: name,
              muscleGroups: groups,
              onBack: () => Navigator.pop(context),
              videoUrl: videoUrl,
              backgroundImage: backgroundImage,
              action: IconButton(
                onPressed: _loadSets,
                icon: const Icon(Icons.refresh, color: Colors.white),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildIntroInstruction(model),
                  const SizedBox(height: 24),
                  _buildSetsSection(),
                  const SizedBox(height: 28),
                  _buildSummarySection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSetsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(text: 'Các set'),
        const SizedBox(height: 10),
        if (_loading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else if (_error != null)
          _errorCard(_error!)
        else if (_sets.isEmpty)
          _placeholderCard('Chưa có set nào được log.')
        else
          _setsTable(),
      ],
    );
  }

  Widget _setsTable() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(.08), width: 1),
      ),
      child: Column(
        children: [
          _tableHeader(),
          const Divider(height: 1, color: Colors.white12),
          for (final s in _sets) _tableRow(s),
        ],
      ),
    );
  }

  Widget _tableHeader() {
    const hd = TextStyle(
      color: Colors.white70,
      fontSize: 13,
      fontWeight: FontWeight.w600,
      letterSpacing: .4,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          const SizedBox(width: 36, child: Text('#', style: hd)),
          _flexCell('Reps', hd),
          _flexCell('Time', hd),
          _flexCell('Weight', hd),
          _flexCell('Cal', hd),
        ],
      ),
    );
  }

  Widget _tableRow(Map<String, dynamic> s) {
    final int setNum = (s['setNumber'] is num)
        ? (s['setNumber'] as num).toInt()
        : 0;
    final int reps = (s['reps'] is num) ? (s['reps'] as num).toInt() : 0;
    final int times = (s['times'] is num) ? (s['times'] as num).toInt() : 0;
    final num weight = (s['weight'] is num) ? (s['weight'] as num) : 0;
    final num cal = (s['caloriesBurned'] is num)
        ? (s['caloriesBurned'] as num)
        : 0;
    const style = TextStyle(
      color: Colors.white,
      fontSize: 14,
      fontWeight: FontWeight.w500,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          SizedBox(width: 36, child: Text(setNum.toString(), style: style)),
          _flexCell(reps.toString(), style),
          _flexCell(_fmtTime(times), style),
          _flexCell(weight.toString(), style),
          _flexCell(cal.toString(), style),
        ],
      ),
    );
  }

  Widget _flexCell(String text, TextStyle style) => Expanded(
    child: Text(text, style: style, textAlign: TextAlign.center),
  );

  Widget _buildSummarySection() {
    if (_sets.isEmpty) return const SizedBox.shrink();
    // Compute total calories if available per set
    num totalCal = 0;
    for (final s in _sets) {
      if (s['caloriesBurned'] is num) totalCal += (s['caloriesBurned'] as num);
    }
    final time = _fmtTime(_totalTimeSeconds);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(text: 'Tổng kết'),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF141414),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(.08), width: 1),
          ),
          child: Row(
            children: [
              _summaryItemWithIcon(
                label: 'Cal burned',
                value: totalCal.toStringAsFixed(0),
                icon: Icons.local_fire_department,
                iconColor: const Color.fromARGB(255, 255, 61, 61),
              ),
              const SizedBox(width: 18),
              _summaryItem('Time', time),
              const SizedBox(width: 18),
              _summaryItem('Sets', _sets.length.toString()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _summaryItemWithIcon({
    required String label,
    required String value,
    required IconData icon,
    Color iconColor = Colors.white,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 16),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: .2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: .2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, String value) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: .2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: .2,
          ),
        ),
      ],
    ),
  );

  Widget _errorCard(String msg) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFF2A1B1B),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: const Color(0xFFFF4E74).withOpacity(.4),
        width: 1,
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Lỗi',
          style: TextStyle(
            color: Color(0xFFFF4E74),
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          msg,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 10),
        TextButton.icon(
          onPressed: _loadSets,
          icon: const Icon(Icons.refresh, size: 16),
          label: const Text('Thử lại'),
        ),
      ],
    ),
  );
}

Widget _placeholderCard(String text) => Container(
  width: double.infinity,
  margin: const EdgeInsets.only(top: 12),
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: const Color(0xFF141414),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: Colors.white.withOpacity(.08), width: 1),
  ),
  child: Text(
    text,
    style: const TextStyle(
      color: Colors.white60,
      fontSize: 13,
      height: 1.4,
      fontWeight: FontWeight.w400,
    ),
  ),
);

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle({required this.text});
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
      ),
    );
  }
}

// Removed expandable text widget as we're using a more compact display now

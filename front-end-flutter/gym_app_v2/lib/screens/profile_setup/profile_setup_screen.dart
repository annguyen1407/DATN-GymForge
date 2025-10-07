import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import '../../widgets/animations/animated_appear.dart';
import '../../core/logging/app_logger.dart';
import '../../widgets/app_button.dart';
import '../../services/user_service.dart';
import '../../widgets/app_snack_bar.dart';
import '../../widgets/date/app_date_picker.dart';
import '../../services/storage_service.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  int _currentStep = 0; // 0..7
  static const int _totalSteps = 8; // avatar + 6 data steps + one rep max

  // Controllers (address + body indexes)
  final _provinceController = TextEditingController();
  final _cityController = TextEditingController();
  final _districtController = TextEditingController();
  final _addressController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _oneRmController = TextEditingController(); // new one rep max

  DateTime? _selectedDob;
  String? _selectedGender; // MALE / FEMALE
  int _intensity = 5; // 1..7 buổi/tuần
  String? _selectedGoal; // mapped via _goalMap

  // Avatar (local processed file + deferred upload url)
  File? _pickedAvatarFile;
  bool _uploadingAvatar = false;
  String? _uploadedAvatarUrl; // set only after upload on save
  bool _saving = false; // loading spinner for final save

  // Map tiếng Việt <-> enum backend
  final Map<String, String> _goalMap = const {
    'Giảm cân': 'LOSE_WEIGHT',
    'Tăng cơ': 'BUILD_MUSCLE',
    'Tăng cân ': 'BULKING',
    'Giảm mỡ giữ cơ': 'CUTTING',
    'Tăng sức mạnh': 'STRENGTH_TRAINING',
    'Tăng sức bền': 'ENDURANCE',
    'Khoẻ mạnh cân đối': 'GENERAL_FITNESS',
    'Tăng độ dẻo dai': 'FLEXIBILITY',
    'Duy trì cân nặng': 'WEIGHT_MAINTENANCE',
    'Thành tích thể thao': 'ATHLETIC_PERFORMANCE',
  };
  List<String> get _goalOptions => _goalMap.keys.toList();

  void _showError(String message) => AppSnackBar.showError(context, message);

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        // Avatar optional
        return true;
      case 1: // Địa chỉ
        if (_provinceController.text.trim().isEmpty ||
            _cityController.text.trim().isEmpty ||
            _districtController.text.trim().isEmpty ||
            _addressController.text.trim().isEmpty) {
          _showError('Vui lòng nhập đầy đủ địa chỉ.');
          return false;
        }
        return true;
      case 2: // Ngày sinh
        if (_selectedDob == null) {
          _showError('Vui lòng chọn ngày sinh.');
          return false;
        }
        return true;
      case 3: // Giới tính
        if (_selectedGender == null) {
          _showError('Vui lòng chọn giới tính.');
          return false;
        }
        return true;
      case 4: // Chỉ số cơ thể
        if (_weightController.text.trim().isEmpty ||
            _heightController.text.trim().isEmpty) {
          _showError('Vui lòng nhập chỉ số cơ thể.');
          return false;
        }
        return true;
      case 5: // Cường độ
        if (_intensity < 1) {
          _showError('Vui lòng chọn cường độ tập luyện.');
          return false;
        }
        return true;
      case 6: // Mục tiêu
        if (_selectedGoal == null) {
          _showError('Vui lòng chọn mục tiêu.');
          return false;
        }
        return true;
      case 7: // One Rep Max (optional but encourage value >0?)
        final raw = _oneRmController.text.trim();
        if (raw.isEmpty) {
          // Optional field -> allow skip
          return true;
        }
        final v = double.tryParse(raw);
        if (v == null || v <= 0) {
          _showError(
            'Giá trị One Rep Max phải là số dương hoặc để trống để bỏ qua.',
          );
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  void _nextStep() {
    if (!_validateCurrentStep()) return;
    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      Navigator.of(context).pushReplacementNamed('/welcome-profile-setup');
    }
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildAvatarStep();
      case 1:
        return _buildAddressStep();
      case 2:
        return _buildDobStep();
      case 3:
        return _buildGenderStep();
      case 4:
        return _buildBodyIndexStep();
      case 5:
        return _buildIntensityStep();
      case 6:
        return _buildGoalStep();
      case 7:
        return _buildOneRmStep();
      default:
        return const SizedBox();
    }
  }

  Widget _buildAvatarStep() {
    final hasLocal = _pickedAvatarFile != null;
    return LayoutBuilder(
      builder: (context, constraints) {
        final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
        return SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: bottomInset > 0 ? bottomInset + 12 : 0,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  const Text(
                    'Chọn ảnh đại diện của bạn',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Ảnh giúp cá nhân hoá trải nghiệm (có thể bỏ qua).',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(.6),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 28),
                  GestureDetector(
                    onTap: _uploadingAvatar
                        ? null
                        : () async {
                            await _pickAndProcessAvatar();
                          },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 260),
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        // Remove pink border & icon highlight as requested
                        color: hasLocal ? null : const Color(0xFF222222),
                      ),
                      clipBehavior: Clip.hardEdge,
                      child: hasLocal
                          ? Image.file(_pickedAvatarFile!, fit: BoxFit.cover)
                          : Icon(
                              Icons.person_outline,
                              color: Colors.white.withOpacity(.55),
                              size: 60,
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    hasLocal
                        ? 'Ảnh đã chọn • sẽ upload khi Lưu'
                        : 'Chưa chọn ảnh',
                    style: TextStyle(
                      color: Colors.white.withOpacity(hasLocal ? .7 : .45),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: AppButton.outline(
                      label: hasLocal
                          ? (_uploadingAvatar
                                ? 'Đang xử lý...'
                                : 'Chọn ảnh khác')
                          : 'Chọn ảnh từ thư viện',
                      onPressed: _uploadingAvatar
                          ? null
                          : () async {
                              await _pickAndProcessAvatar();
                            },
                      size: AppButtonSize.medium,
                    ),
                  ),
                  if (hasLocal) ...[
                    const SizedBox(height: 10),
                    TextButton.icon(
                      onPressed: _uploadingAvatar
                          ? null
                          : () {
                              setState(() {
                                _pickedAvatarFile = null;
                                _uploadedAvatarUrl = null;
                              });
                            },
                      icon: const Icon(
                        Icons.delete_forever,
                        color: Colors.redAccent,
                      ),
                      label: const Text(
                        'Gỡ ảnh',
                        style: TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  ],
                  const Spacer(),
                  _buildNextButton(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _provinceController.dispose();
    _cityController.dispose();
    _districtController.dispose();
    _addressController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _oneRmController.dispose();
    super.dispose();
  }

  Widget _buildAddressStep() {
    InputDecoration deco(String hint) => InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white54),
      filled: true,
      fillColor: Colors.grey[850],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
        return SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: bottomInset > 0 ? bottomInset + 12 : 0,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  const Text(
                    'Bạn sống ở đâu?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _provinceController,
                    style: const TextStyle(color: Colors.white),
                    decoration: deco('Tỉnh/Thành phố'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _districtController,
                    style: const TextStyle(color: Colors.white),
                    decoration: deco('Quận/Huyện'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _cityController,
                    style: const TextStyle(color: Colors.white),
                    decoration: deco('Phường/Xã/Thị trấn'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _addressController,
                    style: const TextStyle(color: Colors.white),
                    decoration: deco('Số nhà, tên đường'),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Đừng lo lắng, dữ liệu cá nhân của bạn sẽ được giữ riêng tư và sẽ không được chia sẻ cho bên thứ 3',
                    style: TextStyle(color: Colors.white38, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const Spacer(),
                  _buildNextButton(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDobStep() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
        return SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: bottomInset > 0 ? bottomInset + 12 : 0,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  const Text(
                    'Ngày sinh bạn là gì?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: () async {
                      final picked = await AppDatePicker.show(
                        context,
                        initialDate: _selectedDob ?? DateTime(2000, 1, 1),
                        firstDate: DateTime(1950),
                        lastDate: DateTime.now(),
                        title: '',
                        hideTitle: true,
                        confirmLabel: 'Lưu',
                        cancelLabel: 'Huỷ',
                        showTodayShortcut: true,
                      );
                      if (picked != null) setState(() => _selectedDob = picked);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 18,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[850],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.cake, color: Colors.white54),
                          const SizedBox(width: 12),
                          Text(
                            _selectedDob != null
                                ? '${_selectedDob!.day}/${_selectedDob!.month}/${_selectedDob!.year}'
                                : 'DD/MM/YYYY',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Đừng lo lắng, dữ liệu cá nhân của bạn sẽ được giữ riêng tư và sẽ không được chia sẻ cho bên thứ 3',
                    style: TextStyle(color: Colors.white38, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const Spacer(),
                  _buildNextButton(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGenderStep() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
        return SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: bottomInset > 0 ? bottomInset + 12 : 0,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  const Text(
                    'Bạn thuộc bên nào?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _genderOption('MALE', 'Nam', Icons.male),
                      const SizedBox(width: 24),
                      _genderOption('FEMALE', 'Nữ', Icons.female),
                    ],
                  ),
                  const Spacer(),
                  _buildNextButton(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _genderOption(String value, String label, IconData icon) {
    final selected = _selectedGender == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedGender = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 32),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF8854FF) : Colors.grey[850],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? const Color(0xFF8854FF) : Colors.white24,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBodyIndexStep() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
        return SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: bottomInset > 0 ? bottomInset + 12 : 0,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  const Text(
                    'Chỉ số cơ thể của bạn là gì?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _weightController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Cân nặng (kg)',
                      hintStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: Colors.grey[850],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _heightController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Chiều cao (cm)',
                      hintStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: Colors.grey[850],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Đừng lo lắng, dữ liệu cá nhân của bạn sẽ được giữ riêng tư và sẽ không được chia sẻ cho bên thứ 3',
                    style: TextStyle(color: Colors.white38, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const Spacer(),
                  _buildNextButton(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildIntensityStep() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
        return SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: bottomInset > 0 ? bottomInset + 12 : 0,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  const Text(
                    'Trung bình mỗi tuần bạn tập luyện với cường độ thế nào?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Slider(
                    value: _intensity.toDouble(),
                    min: 1,
                    max: 7,
                    divisions: 6,
                    label: '$_intensity',
                    activeColor: const Color(0xFF8854FF),
                    onChanged: (v) => setState(() => _intensity = v.round()),
                  ),
                  Text(
                    '$_intensity buổi/tuần',
                    style: const TextStyle(color: Colors.white),
                  ),
                  const Spacer(),
                  _buildNextButton(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGoalStep() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
        return SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: bottomInset > 0 ? bottomInset + 12 : 0,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  const Text(
                    'Hãy cho chúng tôi biết mục tiêu của bạn',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _goalOptions
                        .map(
                          (goal) => ChoiceChip(
                            label: Text(
                              goal,
                              style: const TextStyle(color: Colors.white),
                            ),
                            selected: _selectedGoal == goal,
                            backgroundColor: Colors.grey[850],
                            selectedColor: const Color(0xFF8854FF),
                            onSelected: (selected) {
                              setState(() {
                                _selectedGoal = selected ? goal : null;
                              });
                            },
                          ),
                        )
                        .toList(),
                  ),
                  const Spacer(),
                  _buildNextButton(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOneRmStep() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
        return SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: bottomInset > 0 ? bottomInset + 12 : 0,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'One Rep Max của bạn',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'One Rep Max (1RM) là mức tạ tối đa bạn có thể nâng được trong 1 lần lặp hoàn chỉnh với kỹ thuật đúng.\n'
                    'Chúng tôi dùng chỉ số này để cá nhân hoá cường độ bài tập.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(.70),
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 22),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[850],
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white24, width: 1),
                    ),
                    child: TextField(
                      controller: _oneRmController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'One Rep Max (kg)',
                        labelStyle: TextStyle(color: Colors.white54),
                        border: InputBorder.none,
                        hintText: 'Ví dụ: 80',
                        hintStyle: TextStyle(color: Colors.white30),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF3A1C71),
                          Color(0xFF602D89),
                          Color(0xFF8E54E9),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: const [
                            Icon(
                              Icons.info_outline,
                              color: Colors.white,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Gợi ý nhanh ước tính 1RM',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Nếu bạn chưa test trực tiếp, có thể ước tính: 1RM ≈ (Trọng lượng * Số reps * 0.0333) + Trọng lượng.\nVí dụ bạn nâng 60kg được 8 reps ⇒ 1RM ≈ (60 * 8 * 0.0333) + 60 ≈ 76kg.',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            height: 1.35,
                          ),
                          textAlign: TextAlign.left,
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  _buildSaveButton(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNextButton() {
    return AppButton.primary(
      label: 'Tiếp tục',
      onPressed: _nextStep,
      size: AppButtonSize.large,
      fullWidth: true,
    );
  }

  Widget _buildSaveButton() {
    return AppButton.gradient(
      label: _saving ? 'Đang lưu...' : 'Lưu',
      loading: _saving,
      onPressed: _saving
          ? null
          : () async {
              if (!_validateCurrentStep()) return; // validation (1RM optional)
              setState(() => _saving = true);
              try {
                if (_pickedAvatarFile != null && _uploadedAvatarUrl == null) {
                  await _uploadAvatarToFirebase();
                }
                final address =
                    '${_addressController.text}, ${_cityController.text}, ${_districtController.text}, ${_provinceController.text}';
                String? expType;
                if (_intensity >= 1 && _intensity <= 3) {
                  expType = "Beginner";
                } else if (_intensity >= 4 && _intensity <= 5) {
                  expType = "Intermediate";
                } else if (_intensity >= 6 && _intensity <= 7) {
                  expType = "Advanced";
                }
                String? sexValue = _selectedGender;
                if (sexValue != null) {
                  sexValue = sexValue.toUpperCase() == 'MALE'
                      ? 'MALE'
                      : (sexValue.toUpperCase() == 'FEMALE' ? 'FEMALE' : null);
                }
                final rawOneRm = _oneRmController.text.trim();
                final oneRm = rawOneRm.isEmpty
                    ? null
                    : double.tryParse(
                        rawOneRm,
                      ); // null nếu rỗng hoặc parse fail
                final body = <String, dynamic>{
                  "dateOfBirth": _selectedDob != null
                      ? _selectedDob!.toIso8601String().split('T')[0]
                      : null,
                  "sex": sexValue,
                  "address": address,
                  "weight": double.tryParse(_weightController.text),
                  "height": int.tryParse(_heightController.text),
                  "goal": _selectedGoal != null
                      ? _goalMap[_selectedGoal!]
                      : null,
                  "expType": expType,
                  "profilePicture": _uploadedAvatarUrl,
                };
                if (oneRm != null) {
                  body['oneRm'] = oneRm; // updated key naming
                }
                AppLogger.debug(
                  'PATCH profile body: $body',
                  tag: 'ProfileSetup',
                );
                final success = await UserService.updateProfile(context, body);
                if (!mounted) return;
                AppLogger.info(
                  'PATCH profile result: $success',
                  tag: 'ProfileSetup',
                );
                if (success) {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/main',
                    (route) => false,
                  );
                } else {
                  _showError('Cập nhật thất bại hoặc token hết hạn!');
                }
              } catch (e) {
                if (mounted) {
                  _showError('Lỗi lưu hồ sơ: $e');
                }
              } finally {
                if (mounted) setState(() => _saving = false);
              }
            },
      size: AppButtonSize.large,
      fullWidth: true,
    );
  }

  Future<void> _pickAndProcessAvatar() async {
    try {
      final picker = ImagePicker();
      final xfile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1800,
        imageQuality: 100,
      );
      if (xfile == null) return;
      final processed = await _resizeAndCompressAvatar(File(xfile.path));
      setState(() {
        _pickedAvatarFile = processed;
        _uploadedAvatarUrl = null; // reset; will upload later on save
      });
    } catch (e) {
      if (!mounted) return;
      _showError('Không chọn được ảnh: $e');
    }
  }

  Future<File> _resizeAndCompressAvatar(File file) async {
    try {
      final origBytes = await file.readAsBytes();
      final decoded = img.decodeImage(origBytes);
      if (decoded == null) return file;

      // Center square crop
      final minSide = decoded.width < decoded.height
          ? decoded.width
          : decoded.height;
      final cropped = img.copyCrop(
        decoded,
        x: (decoded.width - minSide) ~/ 2,
        y: (decoded.height - minSide) ~/ 2,
        width: minSide,
        height: minSide,
      );

      // Adaptive target size: smaller output if original small.
      int targetSide;
      if (minSide >= 1200) {
        targetSide = 384; // large original -> mid size
      } else if (minSide >= 800) {
        targetSide = 320;
      } else if (minSide >= 500) {
        targetSide = 256;
      } else {
        targetSide = minSide < 192 ? minSide : 192; // keep small or cap
      }
      final resized = img.copyResize(
        cropped,
        width: targetSide,
        height: targetSide,
        interpolation: img.Interpolation.average,
      );

      // Adaptive byte target by tier (smaller side -> smaller budget)
      int maxBytes;
      if (targetSide >= 360) {
        maxBytes = 120 * 1024;
      } else if (targetSide >= 256) {
        maxBytes = 95 * 1024;
      } else if (targetSide >= 192) {
        maxBytes = 80 * 1024;
      } else {
        maxBytes = 60 * 1024;
      }

      int quality = 86;
      const int minQ = 52;
      var out = img.encodeJpg(resized, quality: quality);
      while (out.length > maxBytes && quality > minQ) {
        quality -= quality > 72 ? 9 : 5;
        if (quality < minQ) quality = minQ;
        out = img.encodeJpg(resized, quality: quality);
      }

      final tmp = await getTemporaryDirectory();
      final f = File(
        '${tmp.path}/avatar_${DateTime.now().millisecondsSinceEpoch}_${targetSide}sq_q$quality.jpg',
      );
      await f.writeAsBytes(out, flush: true);
      return f;
    } catch (_) {
      return file; // fallback original if processing fails
    }
  }

  Future<void> _uploadAvatarToFirebase() async {
    if (_pickedAvatarFile == null) return;
    setState(() => _uploadingAvatar = true);
    try {
      final url = await StorageService.instance.uploadFile(
        file: _pickedAvatarFile!,
        folder: 'avatars',
      );
      if (mounted) {
        setState(() => _uploadedAvatarUrl = url);
      }
    } catch (e) {
      if (mounted) {
        _showError('Upload avatar thất bại');
      }
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: _currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: _prevStep,
              )
            : null,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
          child: Column(
            children: [
              AnimatedAppear(
                dy: 10,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 360),
                      transitionBuilder: (child, anim) => FadeTransition(
                        opacity: anim,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.2),
                            end: Offset.zero,
                          ).animate(anim),
                          child: child,
                        ),
                      ),
                      child: Text(
                        'bước ${_currentStep + 1}/$_totalSteps',
                        key: ValueKey(_currentStep),
                        style: const TextStyle(
                          color: Color(0xFF8854FF),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 420),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position:
                          Tween<Offset>(
                            begin: const Offset(0.05, 0),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: anim,
                              curve: Curves.easeOutCubic,
                            ),
                          ),
                      child: child,
                    ),
                  ),
                  child: KeyedSubtree(
                    key: ValueKey('step_$_currentStep'),
                    child: AnimatedAppear(
                      key: ValueKey('appear_$_currentStep'),
                      dy: 16,
                      child: _buildStepContent(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

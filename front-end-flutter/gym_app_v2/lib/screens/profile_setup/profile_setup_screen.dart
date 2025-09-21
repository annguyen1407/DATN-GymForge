import 'package:flutter/material.dart';
import '../../core/logging/app_logger.dart';
import '../../widgets/app_button.dart';
import '../../services/user_service.dart';
import '../../widgets/app_snack_bar.dart';
import '../../widgets/date/app_date_picker.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  static const int _totalSteps = 7;

  // Các controller và biến lưu trữ dữ liệu từng bước
  // Đã bỏ bước nhập tên
  final TextEditingController _provinceController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _districtController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  DateTime? _selectedDob;
  String? _selectedGender; // 'MALE' or 'FEMALE'
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  int _intensity = 5;
  String? _selectedGoal;
  // Map tiếng Việt <-> enum backend
  final Map<String, String> _goalMap = {
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
  int? _selectedAvatarIndex;

  void _showError(String message) => AppSnackBar.showError(context, message);

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        // Cho phép bỏ qua chọn avatar ở bước 1
        break;
      case 1:
        if (_provinceController.text.trim().isEmpty ||
            _cityController.text.trim().isEmpty ||
            _districtController.text.trim().isEmpty ||
            _addressController.text.trim().isEmpty) {
          _showError('Vui lòng nhập đầy đủ địa chỉ.');
          return false;
        }
        break;
      case 3:
        if (_selectedDob == null) {
          _showError('Vui lòng chọn ngày sinh.');
          return false;
        }
        break;
      case 4:
        if (_selectedGender == null) {
          _showError('Vui lòng chọn giới tính.');
          return false;
        }
        break;
      case 5:
        if (_weightController.text.trim().isEmpty ||
            _heightController.text.trim().isEmpty) {
          _showError('Vui lòng nhập đầy đủ chỉ số cơ thể.');
          return false;
        }
        break;
      case 6:
        if (_intensity < 1) {
          _showError('Vui lòng chọn cường độ tập luyện.');
          return false;
        }
        break;
      case 7:
        if (_selectedGoal == null) {
          _showError('Vui lòng chọn mục tiêu.');
          return false;
        }
        break;
    }
    return true;
  }

  void _nextStep() {
    if (!_validateCurrentStep()) return;
    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.ease,
      );
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.ease,
      );
    } else {
      // Nếu đang ở bước 1, quay lại màn hình welcome profile setup
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
      default:
        return const SizedBox();
    }
  }

  Widget _buildAvatarStep() {
    final avatarAssets = [
      'assets/avatar1.png',
      'assets/avatar2.png',
      'assets/avatar3.png',
      'assets/avatar4.png',
      'assets/avatar5.png',
      'assets/avatar6.png',
    ];
    return Column(
      children: [
        const Text(
          'Chọn ảnh đại diện của bạn',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: List.generate(
            avatarAssets.length,
            (i) => GestureDetector(
              onTap: () => setState(() => _selectedAvatarIndex = i),
              child: CircleAvatar(
                radius: 36,
                backgroundColor: _selectedAvatarIndex == i
                    ? const Color(0xFF8854FF)
                    : Colors.white24,
                child: CircleAvatar(
                  radius: 32,
                  backgroundImage: AssetImage(avatarAssets[i]),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Upload avatar button (outline style)
        SizedBox(
          width: double.infinity,
          child: AppButton.outline(
            label: 'Hoặc thêm ảnh của bạn',
            onPressed: () {
              // TODO: Thêm chức năng upload ảnh
            },
            size: AppButtonSize.medium,
          ),
        ),
        const Spacer(),
        _buildNextButton(),
      ],
    );
  }

  Widget _buildAddressStep() {
    return Column(
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
          decoration: InputDecoration(
            hintText: 'Tỉnh/Thành phố',
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
          controller: _districtController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Quận/Huyện',
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
          controller: _cityController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Phường/Xã/Thị trấn',
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
          controller: _addressController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Số nhà, tên đường',
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
    );
  }

  Widget _buildDobStep() {
    return Column(
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
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
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
                  style: const TextStyle(color: Colors.white, fontSize: 16),
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
    );
  }

  Widget _buildGenderStep() {
    return Column(
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
    return Column(
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
    );
  }

  Widget _buildIntensityStep() {
    return Column(
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
    );
  }

  Widget _buildGoalStep() {
    return Column(
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
        _buildSaveButton(),
      ],
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
      label: 'Lưu',
      onPressed: () async {
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
        final body = {
          "dateOfBirth": _selectedDob != null
              ? _selectedDob!.toIso8601String().split('T')[0]
              : null,
          "sex": sexValue,
          "address": address,
          "weight": double.tryParse(_weightController.text),
          "height": int.tryParse(_heightController.text),
          "goal": _selectedGoal != null ? _goalMap[_selectedGoal!] : null,
          "expType": expType,
          "profilePicture": null, // luôn truyền null cho avatar
        };
        AppLogger.debug('PATCH profile body: $body', tag: 'ProfileSetup');
        final success = await UserService.updateProfile(context, body);
        if (!mounted) return; // context may be disposed
        AppLogger.info('PATCH profile result: $success', tag: 'ProfileSetup');
        if (success) {
          Navigator.pushNamedAndRemoveUntil(context, '/main', (route) => false);
        } else {
          _showError('Cập nhật thất bại hoặc token hết hạn!');
        }
      },
      size: AppButtonSize.large,
      fullWidth: true,
    );
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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'bước ${_currentStep + 1}/$_totalSteps',
                    style: const TextStyle(
                      color: Color(0xFF8854FF),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _totalSteps,
                  itemBuilder: (context, index) => _buildStepContent(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

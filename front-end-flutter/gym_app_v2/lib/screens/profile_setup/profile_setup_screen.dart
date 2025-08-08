import 'package:flutter/material.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  static const int _totalSteps = 8;

  // Các controller và biến lưu trữ dữ liệu từng bước
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _provinceController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _districtController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  DateTime? _selectedDob;
  String? _selectedGender; // 'MALE' or 'FEMALE'
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _oneRmController = TextEditingController();
  int _intensity = 5;
  final List<String> _selectedGoals = [];
  final List<String> _goalOptions = [
    'Kiểm soát cân nặng',
    'Tăng năng lượng hàng ngày',
    'Tăng khối lượng và kích thước cơ',
    'Thử các bài tập mới',
    'Tập luyện riêng tư',
    'Giữ gìn sức khỏe hàng ngày',
  ];
  int? _selectedAvatarIndex;

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        // Cho phép bỏ qua chọn avatar ở bước 1
        break;
      case 1:
        if (_lastNameController.text.trim().isEmpty ||
            _firstNameController.text.trim().isEmpty) {
          _showError('Vui lòng nhập đầy đủ họ và tên.');
          return false;
        }
        break;
      case 2:
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
            _heightController.text.trim().isEmpty ||
            _oneRmController.text.trim().isEmpty) {
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
        if (_selectedGoals.isEmpty) {
          _showError('Vui lòng chọn ít nhất 1 mục tiêu.');
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
        return _buildNameStep();
      case 2:
        return _buildAddressStep();
      case 3:
        return _buildDobStep();
      case 4:
        return _buildGenderStep();
      case 5:
        return _buildBodyIndexStep();
      case 6:
        return _buildIntensityStep();
      case 7:
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
        OutlinedButton.icon(
          onPressed: () {
            // TODO: Thêm chức năng upload ảnh
          },
          icon: const Icon(Icons.add_a_photo, color: Colors.white),
          label: const Text(
            'Hoặc thêm ảnh của bạn',
            style: TextStyle(color: Colors.white),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.white24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const Spacer(),
        _buildNextButton(),
      ],
    );
  }

  Widget _buildNameStep() {
    return Column(
      children: [
        const Text(
          'Bạn tên là gì?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _lastNameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Họ',
                  hintStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.grey[850],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _firstNameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Tên',
                  hintStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.grey[850],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ],
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
            hintText: 'Tỉnh',
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
            hintText: 'Thành phố',
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
            hintText: 'Quận / Huyện',
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
            hintText: 'Địa chỉ',
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
            final picked = await showDatePicker(
              context: context,
              initialDate: _selectedDob ?? DateTime(2000, 1, 1),
              firstDate: DateTime(1950),
              lastDate: DateTime.now(),
              builder: (context, child) => Theme(
                data: ThemeData.dark().copyWith(
                  colorScheme: const ColorScheme.dark(
                    primary: Color(0xFF8854FF),
                    onPrimary: Colors.white,
                    surface: Colors.black,
                    onSurface: Colors.white,
                  ),
                  dialogTheme: DialogThemeData(
                    backgroundColor: Colors.grey[900],
                  ),
                ),
                child: child!,
              ),
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
                      : 'Chọn ngày sinh',
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
        TextField(
          controller: _oneRmController,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Mức tạ tối đa, 1RM (kg)',
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
                (goal) => FilterChip(
                  label: Text(
                    goal,
                    style: const TextStyle(color: Colors.white),
                  ),
                  selected: _selectedGoals.contains(goal),
                  backgroundColor: Colors.grey[850],
                  selectedColor: const Color(0xFF8854FF),
                  checkmarkColor: Colors.white,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedGoals.add(goal);
                      } else {
                        _selectedGoals.remove(goal);
                      }
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
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF8854FF),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: _nextStep,
        child: const Text(
          'Tiếp tục',
          style: TextStyle(fontSize: 18, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF8854FF),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: () {
          // TODO: Lưu thông tin user qua API nếu cần
          Navigator.pushNamedAndRemoveUntil(context, '/main', (route) => false);
        },
        child: const Text(
          'Lưu',
          style: TextStyle(fontSize: 18, color: Colors.white),
        ),
      ),
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

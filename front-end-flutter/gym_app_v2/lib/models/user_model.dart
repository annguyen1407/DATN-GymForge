class UserModel {
  final String id;
  final String name;
  final String email;
  final String? profilePicture;
  final String? dateOfBirth;
  final String? address;
  final String? phoneNumber;
  final bool premiumStatus;
  final String? sex;
  final String? biography;
  final String? role; // e.g. GYMER / COACH / ADMIN
  final double? weight; // latest weight snapshot (kg)
  final int? height; // cm
  final double? oneRm; // optional

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.profilePicture,
    this.dateOfBirth,
    this.address,
    this.phoneNumber,
    required this.premiumStatus,
    this.sex,
    this.biography,
    this.role,
    this.weight,
    this.height,
    this.oneRm,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      profilePicture: json['profilePicture'],
      dateOfBirth: json['dateOfBirth'],
      address: json['address'],
      phoneNumber: json['phoneNumber'],
      premiumStatus: json['premiumStatus'] ?? false,
      sex: json['sex'],
      biography: json['biography'],
      role: json['role'],
      weight: (json['weight'] is num)
          ? (json['weight'] as num).toDouble()
          : null,
      height: json['height'] is num ? (json['height'] as num).toInt() : null,
      oneRm: (json['oneRm'] is num)
          ? (json['oneRm'] as num).toDouble()
          : (json['oneRM'] is num) // backward compatibility if older key used
          ? (json['oneRM'] as num).toDouble()
          : null,
    );
  }
}

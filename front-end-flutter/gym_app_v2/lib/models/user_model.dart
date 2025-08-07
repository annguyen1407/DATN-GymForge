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
    );
  }
}

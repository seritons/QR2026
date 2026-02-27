// lib/app/models/core_models.dart
import 'social_models.dart';
// =====================
// USER MODEL
// =====================
class UserModel {
  final String id;
  final String firstName; // isim
  final String lastName;  // soyisim
  final String email;
  final UserRelationBusiness relationBusiness;

  const UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.relationBusiness,
  });

  String get fullName => '$firstName $lastName'.trim();

  Map<String, dynamic> toJson() => {
    'id': id,
    'firstName': firstName,
    'lastName': lastName,
    'email': email,
  };

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['id'] ?? '').toString(),
      firstName: (json['firstName'] ?? '').toString(),
      lastName: (json['lastName'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      relationBusiness:  stringToRelation(json['relation'].toString())
    );
  }
}

enum UserRelationBusiness {
  owner,stuff,manager
}

UserRelationBusiness stringToRelation(String s) {
  if (s == "owner") return .owner;
  if (s == "stuff") return .stuff;
  return .manager;
}

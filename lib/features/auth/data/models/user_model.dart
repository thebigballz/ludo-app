import 'dart:convert';

class UserModel {
  final int id;
  final String name;
  final String phone;
  final String? email;
  final String kycStatus;
  final String? avatar;
  final Map<String, dynamic>? wallet;

  const UserModel({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    required this.kycStatus,
    this.avatar,
    this.wallet,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id:        json['id'],
      name:      json['name'],
      phone:     json['phone'],
      email:     json['email'],
      kycStatus: json['kyc_status'],
      avatar:    json['avatar'],
      wallet:    json['wallet'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id':         id,
      'name':       name,
      'phone':      phone,
      'email':      email,
      'kyc_status': kycStatus,
      'avatar':     avatar,
      'wallet':     wallet,
    };
  }

  String toJsonString() => jsonEncode(toJson());

  static UserModel fromJsonString(String jsonString) {
    return UserModel.fromJson(jsonDecode(jsonString));
  }

  double get balance {
    final raw = wallet?['balance'];
    if (raw == null) return 0.0;
    return double.tryParse(raw.toString()) ?? 0.0;
  }
}
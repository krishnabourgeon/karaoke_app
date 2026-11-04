// To parse this JSON data, do
//
//     final verifyOtpModel = verifyOtpModelFromJson(jsonString);

import 'dart:convert';

VerifyOtpModel verifyOtpModelFromJson(String str) => VerifyOtpModel.fromJson(json.decode(str));

String verifyOtpModelToJson(VerifyOtpModel data) => json.encode(data.toJson());

class VerifyOtpModel {
    String message;
    bool isNewUser;
    String tokenType;
    String accessToken;
    User user;

    VerifyOtpModel({
        required this.message,
        required this.isNewUser,
        required this.tokenType,
        required this.accessToken,
        required this.user,
    });

    factory VerifyOtpModel.fromJson(Map<String, dynamic> json) => VerifyOtpModel(
        message: json["message"],
        isNewUser: json["is_new_user"],
        tokenType: json["token_type"],
        accessToken: json["access_token"],
        user: User.fromJson(json["user"]),
    );

    Map<String, dynamic> toJson() => {
        "message": message,
        "is_new_user": isNewUser,
        "token_type": tokenType,
        "access_token": accessToken,
        "user": user.toJson(),
    };
}

class User {
    int id;
    String name;
    String phoneNumber;
    String role;
    int points;
    bool isActive;
    DateTime createdAt;
    DateTime updatedAt;

    User({
        required this.id,
        required this.name,
        required this.phoneNumber,
        required this.role,
        required this.points,
        required this.isActive,
        required this.createdAt,
        required this.updatedAt,
    });

    factory User.fromJson(Map<String, dynamic> json) => User(
        id: json["id"],
        name: json["name"],
        phoneNumber: json["phone_number"],
        role: json["role"],
        points: json["points"],
        isActive: json["is_active"],
        createdAt: DateTime.parse(json["created_at"]),
        updatedAt: DateTime.parse(json["updated_at"]),
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "phone_number": phoneNumber,
        "role": role,
        "points": points,
        "is_active": isActive,
        "created_at": createdAt.toIso8601String(),
        "updated_at": updatedAt.toIso8601String(),
    };
}

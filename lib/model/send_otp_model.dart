// To parse this JSON data, do
//
//     final sendOtpModel = sendOtpModelFromJson(jsonString);

import 'dart:convert';

SendOtpModel sendOtpModelFromJson(String str) => SendOtpModel.fromJson(json.decode(str));

String sendOtpModelToJson(SendOtpModel data) => json.encode(data.toJson());

class SendOtpModel {
    String message;
    int expiresIn;
    bool isNewUser;
    String otp;

    SendOtpModel({
        required this.message,
        required this.expiresIn,
        required this.isNewUser,
        required this.otp,
    });

    factory SendOtpModel.fromJson(Map<String, dynamic> json) => SendOtpModel(
        message: json["message"],
        expiresIn: json["expires_in"],
        isNewUser: json["is_new_user"],
        otp: json["otp"],
    );

    Map<String, dynamic> toJson() => {
        "message": message,
        "expires_in": expiresIn,
        "is_new_user": isNewUser,
        "otp": otp,
    };
}

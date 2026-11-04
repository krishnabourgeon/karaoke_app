import 'package:flutter/cupertino.dart';
import 'package:karaoke_app/model/send_otp_model.dart';
import 'package:karaoke_app/model/verify_otp_model.dart';
import 'package:karaoke_app/service/provider_helper_class.dart';
import 'package:karaoke_app/service/shared_preference_helper.dart';
import 'package:karaoke_app/service/validation_helper.dart';


class AuthProvider extends ChangeNotifier with ProviderHelperClass {
  TextEditingController loginUsernameController = TextEditingController();
  TextEditingController loginPasswordController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController punnyamCodeController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();
  TextEditingController pinCodeController = TextEditingController();
  String? errorToast;
  String? userNameValidationMessage;
  String? nameValidationMessage;
  String? emailValidationMessage;
  String? punnyamCodeValidationMessage;
  String? passwordValidationMessage;
  String? confirmPasswordValidationMessage;
  bool isLoginFormValidated = false;
  bool isRegisterFormValidated = false;
  bool isRememberCredentials = true;

    Future<void> sendOtp({Function? onSuccess, Function? onFailure}) async {
    updateLoadState(LoaderState.loading);
    var res = await serviceConfig.sendOtp(
        phonenumber: phoneController.text,
        name: nameController.text);
    if (res.isValue) {
      SendOtpModel sendOtpModel = res.asValue!.value;
      // if (isRememberCredentials) {
      //   await SharedPreferenceHelper.saveToken(sendOtpModel.token ?? '');

      //   //  await SharedPreferenceHelper.savesetting(loginResponseModel. ?? '');
      // }
      if (onSuccess != null) onSuccess();
      updateLoadState(LoaderState.loaded);
    } else {
      errorToast = 'Otp sending failed';
      if (onFailure != null) onFailure();
      updateLoadState(LoaderState.loaded);
    }
    notifyListeners();
  }

  Future<void> verifyOtp({Function? onSuccess, Function? onFailure}) async {
    updateLoadState(LoaderState.loading);
    var res = await serviceConfig.verifyOtp(
      phonenumber: phoneController.text,
      otp: pinCodeController.text,
      name: nameController.text
    );
    if (res.isValue) {
      VerifyOtpModel verifyOtpModel = res.asValue!.value;
      if (isRememberCredentials) {
        await SharedPreferenceHelper.saveToken(verifyOtpModel.accessToken);
        // await SharedPreferenceHelper.saveUser(verifyOtpModel.user);
      }
      if (onSuccess != null) onSuccess();
      updateLoadState(LoaderState.loaded);
    } else {
      errorToast = 'Otp verification failed';
      if (onFailure != null) onFailure();
      updateLoadState(LoaderState.loaded);
    }
    notifyListeners();
  }



  updateValidationMessages(
      {required ValidationTypes validationType,
      required String validationMessage}) {
    switch (validationType) {
      case ValidationTypes.name:
        if (validationMessage.isNotEmpty) {
          nameValidationMessage = validationMessage;
        } else {
          nameValidationMessage = null;
        }

        break;

      case ValidationTypes.email:
        if (validationMessage.isNotEmpty) {
          emailValidationMessage = validationMessage;
        } else {
          emailValidationMessage = null;
        }
        break;
      case ValidationTypes.punnyamCode:
        if (validationMessage.isNotEmpty) {
          punnyamCodeValidationMessage = validationMessage;
        } else {
          punnyamCodeValidationMessage = null;
        }
        break;
      case ValidationTypes.password:
        if (validationMessage.isNotEmpty) {
          passwordValidationMessage = validationMessage;
        } else {
          passwordValidationMessage = null;
        }
        break;
      case ValidationTypes.confirmPassword:
        if (validationMessage.isNotEmpty) {
          confirmPasswordValidationMessage = validationMessage;
        } else {
          confirmPasswordValidationMessage = null;
        }
        break;
      case ValidationTypes.userName:
        if (validationMessage.isNotEmpty) {
          userNameValidationMessage = validationMessage;
        } else {
          userNameValidationMessage = null;
        }
        break;
      default:
        break;

    }
    updateLoginFormState();
    updateRegisterFormState();
    notifyListeners();
  }

  updateLoginFormState() {
    if (loginUsernameController.text.isNotEmpty &&
        loginPasswordController.text.isNotEmpty &&
        userNameValidationMessage == null) {
      isLoginFormValidated = true;
    } else {
      isLoginFormValidated = false;
    }
    debugPrint('is login form validated $isLoginFormValidated');
    notifyListeners();
  }

  updateRegisterFormState() {
    if (nameController.text.isNotEmpty &&
        emailController.text.isNotEmpty &&
        punnyamCodeController.text.isNotEmpty &&
        passwordController.text.isNotEmpty &&
        confirmPasswordController.text.isNotEmpty &&
        nameValidationMessage == null &&
        emailValidationMessage == null &&
        punnyamCodeValidationMessage == null &&
        passwordValidationMessage == null &&
        confirmPasswordValidationMessage == null) {
      isRegisterFormValidated = true;
    } else {
      isRegisterFormValidated = false;
    }
    notifyListeners();
  }

  updateRememberMeValue(bool value) {
    isRememberCredentials = value;
    notifyListeners();
  }

  clearValues() {
    nameController.clear();
    emailController.clear();
    punnyamCodeController.clear();
    passwordController.clear();
    confirmPasswordController.clear();
    loginUsernameController.clear();
    loginPasswordController.clear();
    nameValidationMessage = null;
    emailValidationMessage = null;
    punnyamCodeValidationMessage = null;
    passwordValidationMessage = null;
    confirmPasswordValidationMessage = null;
    userNameValidationMessage = null;
    notifyListeners();
  }

  @override
  void updateLoadState(LoaderState state) {
    loaderState = state;
    notifyListeners();
  }
}

import 'package:flutter/foundation.dart';
import 'package:async/async.dart';
import 'package:karaoke_app/model/get_songs_model.dart';
import 'package:karaoke_app/model/masters_model.dart';
import 'package:karaoke_app/model/search_model.dart';
import 'package:karaoke_app/model/upload_karaoke.dart';
import 'package:karaoke_app/model/verify_otp_model.dart';
import 'package:karaoke_app/service/base_client.dart';
import 'package:karaoke_app/model/error_response_model.dart';
import 'package:karaoke_app/model/send_otp_model.dart';


class ServiceConfig {

  Future<Result> sendOtp({
    String? phonenumber,
    String? name,
  }) async {
    Result res = await BaseClient.post('send-otp?phone_number=$phonenumber&name=$name');

    if (res.isError) {
      return Result.error(
        ErrorResponseModel(
          errorMessage: 'Oops...! Registration failed',
        ),
      );
    } 
    final response = res.asValue!.value;
    debugPrint('Send OTP response: $response');
    SendOtpModel sendOtpModel = SendOtpModel.fromJson(response);
    return Result.value(sendOtpModel);
  }


  Future<Result> verifyOtp({
    String? phonenumber,
    String? name,
    String? otp,
  }) async {
    Result res = await BaseClient.post('verify-otp?phone_number=$phonenumber&name=$name&otp=$otp');  
    if(res.isError){
      return  Result.error(
        ErrorResponseModel(
          errorMessage: 'Oops...! Invalid OTP'
        )
      );
    }
    final response = res.asValue!.value;
    debugPrint('Verify OTP response: $response');
    VerifyOtpModel verifyOtpModel = VerifyOtpModel.fromJson(response);
    return Result.value(verifyOtpModel);
  }

  Future<Result> getMasters() async{
    Result res = await BaseClient.get('masters');
    if(res.isError){
      return Result.error(
        ErrorResponseModel(
          errorMessage: 'Oops...! Something went wrong'
        )
      );
    }
    final response = res.asValue!.value;
    debugPrint('Masters response: $response');
    MastersModel mastersModel = MastersModel.fromJson(response);
    return Result.value(mastersModel);
  }


  Future<Result> uploadKaraoke({
    required String title,
    required String languageid,
    required String genreid,
    required String vibeid,
    required String duration,
    required String audio,
    required String video,
    void Function(int sent, int total)? onProgress,
  }) async {

    Result res = await BaseClient.multipartPost('songs',
    onProgress: onProgress,
    fields: {
      'title': title,
      'language_id': languageid,
      'genre_id': genreid,
      'vibe_id': vibeid,
      'duration': duration
    },
    files: {
      if (audio.isNotEmpty) 'audio': audio,
      if (video.isNotEmpty) 'video': video,
    }
    );
    if(res.isError){
      return Result.error(
        ErrorResponseModel(
          errorMessage: 'Oops...! Something went wrong'
        )
      );
    }
    final response = res.asValue!.value;
    debugPrint('Upload Karaoke response: $response');
    UploadKaraoke uploadKaraoke = UploadKaraoke.fromJson(response);
    return (uploadKaraoke.status)
    ? Result.value(uploadKaraoke)
    : Result.error(uploadKaraoke.message);
  }

  Future<Result> getSongs({int page = 1}) async{
    Result res = await BaseClient.get('songs', map: {'page': '$page'});
    if(res.isError){
      return Result.error(
        ErrorResponseModel(
          errorMessage: 'Oops...! Something went wrong'
        )
      );
    }
    final response = res.asValue!.value;
    debugPrint('Get Songs response: $response');
    GetSongsModel getSongsModel = GetSongsModel.fromJson(response);
    return Result.value(getSongsModel);
  }


  Future<Result> searchSongs({
    required String search,
    required String vibeid,
    required String languageid,
    required String genreid,
  }) async {
    Result res = await BaseClient.get('songs?search=$search&vibe_id=$vibeid&language_id=$languageid&genre_id=$genreid');
    if(res.isError){
      return Result.error(
        ErrorResponseModel(
          errorMessage: 'Oops...! Something went wrong'
        )
      );
    }
    final response = res.asValue!.value;
    debugPrint('Search Song response: $response');
    SearchModel searchModel = SearchModel.fromJson(response);
    return (searchModel.status)
    ? Result.value(searchModel)
    : Result.error(searchModel);
  }

 

}

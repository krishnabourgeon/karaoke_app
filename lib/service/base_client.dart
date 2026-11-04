import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:karaoke_app/service/app_config.dart';
import 'package:karaoke_app/service/helpers.dart';
import 'package:karaoke_app/service/shared_preference_helper.dart';
import 'app_exceptions.dart';
import 'package:async/async.dart';

class BaseClient {
  static final BaseClient _instance = BaseClient._internal();
  factory BaseClient() => _instance;
  BaseClient._internal();
  static const int timeDuration = 20;
  static const int uploadTimeDuration = 300; 
  static Future<String> get token async {
    return AppConfig.accessToken == null
        ? await SharedPreferenceHelper.getToken()
        : AppConfig.accessToken!;
  }

  static const String _appJson = 'application/json';
  static Map<String, String> commonHeaders = {
    'Content-Type': 'application/json',
    //HttpHeaders.contentTypeHeader: 'application/json',
  };
  //GET METHOD
  static Future<dynamic> get(String api, {Map<String, String>? map}) async {
    String bearerToken = await token;
    String queryString = Uri(queryParameters: map ?? {}).query;
    var uri;
    if (map != null) {
      uri = Uri.parse('${AppConfig.baseUrl}$api?$queryString');
    } else {
      uri = Uri.parse(AppConfig.baseUrl + api);
    }
    bool check = await isInternetAvailable(enableToast: false);
    if (!check) throw NoInternetException(uri.toString());
    if (check) {
      try {
        var response = await http.get(
          uri,
          headers: {
            HttpHeaders.contentTypeHeader: _appJson,
            HttpHeaders.authorizationHeader: 'Bearer $bearerToken'
          },
        ).timeout(const Duration(seconds: timeDuration));
        return _processResponse(response);
      } on SocketException {
        throw NoInternetException(uri.toString());
      } on TimeoutException {
        throw ApiNotRespondingException(
            'API not responded in time', uri.toString());
      }
    }
  }

  //POST METHOD
  static Future<dynamic> post(String api, {dynamic body}) async {
    String bearerToken = await token;

    var uri = Uri.parse(AppConfig.baseUrl + api);
    bool check = await isInternetAvailable(enableToast: false);
    if (!check) throw NoInternetException(uri.toString());
    if (check) {
      try {
        var response = await http
            .post(
              uri,
              headers: {
                HttpHeaders.contentTypeHeader: _appJson,
                HttpHeaders.authorizationHeader: 'Bearer $bearerToken'
              },
              body: body != null ? json.encode(body) : null,
            )
            .timeout(const Duration(seconds: timeDuration));
        // print(response.statusCode);
        // print(response.body);
        return _processResponse(response);
      } on SocketException {
        throw NoInternetException(uri.toString());
      } on TimeoutException {
        throw ApiNotRespondingException(
            'API not responded in time', uri.toString());
      }
    }
  }

  // MULTIPART POST METHOD
  /// [onProgress] gets the bytes sent so far and the total request size.
static Future<dynamic> multipartPost(
  String api, {
  required Map<String, String> fields,
  Map<String, String>? files,
  void Function(int sent, int total)? onProgress,
}) async {
  String bearerToken = await token;

  var uri = Uri.parse(AppConfig.baseUrl + api);

  bool check = await isInternetAvailable(enableToast: false);
  if (!check) throw NoInternetException(uri.toString());

  // Timings, to see whether the network or the server is the slow part.
  final clock = Stopwatch()..start();
  Duration? sentAt;

  try {
    var request = _ProgressMultipartRequest('POST', uri, (sent, total) {
      if (sent >= total && sentAt == null) {
        sentAt = clock.elapsed;
        debugPrint('[upload] file sent: ${_mb(total)} in ${_secs(sentAt!)}'
            ' (${_mbps(total, sentAt!)})');
      }
      onProgress?.call(sent, total);
    });

    request.headers.addAll({
      HttpHeaders.authorizationHeader: 'Bearer $bearerToken',
    });

    request.fields.addAll(fields);

    // if (files != null) {
    //   for (final entry in files.entries) {
    //     request.files.add(
    //       await http.MultipartFile.fromPath(
    //         entry.key,
    //         entry.value,
    //       ),
    //     );
    //   }
    // }

    if (files != null) {
      for (final entry in files.entries) {
        if (entry.value.isEmpty) continue;
        request.files.add(
          await http.MultipartFile.fromPath(
            entry.key,
            entry.value,
          ),
        );
      }
    }

    // var streamedResponse = await request.send().timeout(
    //   const Duration(seconds: timeDuration),
    // );

    // var response = await http.Response.fromStream(streamedResponse);

    var streamedResponse = await request.send().timeout(
      const Duration(seconds: uploadTimeDuration),
    );

    var response = await http.Response.fromStream(streamedResponse).timeout(
      const Duration(seconds: uploadTimeDuration),
    );

    final total = clock.elapsed;
    debugPrint('[upload] server replied ${response.statusCode} after '
        '${_secs(total - (sentAt ?? Duration.zero))} of waiting; '
        'total ${_secs(total)}');

    return _processResponse(response);
  } on SocketException {
    throw NoInternetException(uri.toString());
  } on TimeoutException {
    throw ApiNotRespondingException(
      'API not responded in time',
      uri.toString(),
    );
  }
}



  static dynamic _processResponse(http.Response response) {
    print(response.body);
    print(response.statusCode);
    switch (response.statusCode) {
      case 200:
        // var responseJson = utf8.decode(response.bodyBytes);
        return Result.value(jsonDecode(response.body));
      case 201:
        // var responseJson = utf8.decode(response.bodyBytes);
        return Result.value(jsonDecode(response.body));
      case 400:
        throw BadRequestException(
            utf8.decode(response.bodyBytes), response.request!.url.toString());
      case 401:
      case 403:
        return Result.value(jsonDecode(response.body));
      case 422:
        throw BadRequestException(
            utf8.decode(response.bodyBytes), response.request!.url.toString());
      case 500:
      default:
        throw FetchDataException(
            'Error occured with code : ${response.statusCode}',
            response.request!.url.toString());
    }
  }

  static Future<bool> isInternetAvailable({bool enableToast = true}) async {
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        return true;
      } else {
        if (enableToast) Helpers.successToast("No Internet");
        return false;
      }
    } on SocketException catch (_) {
      if (enableToast) Helpers.successToast("No Internet");
      return false;
    }
  }
}

String _mb(int bytes) => '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
String _secs(Duration d) => '${(d.inMilliseconds / 1000).toStringAsFixed(1)} s';
String _mbps(int bytes, Duration d) => d.inMilliseconds == 0
    ? '-'
    : '${(bytes * 8 / 1000000 / (d.inMilliseconds / 1000)).toStringAsFixed(2)} Mbps';

/// A multipart request that reports how many bytes have been sent.
///
/// Bytes are counted as they are handed to the socket, so the count runs
/// slightly ahead of what the server has received, but for files of a few
/// MB and up it tracks the real upload closely.
class _ProgressMultipartRequest extends http.MultipartRequest {
  final void Function(int sent, int total) onProgress;

  _ProgressMultipartRequest(super.method, super.url, this.onProgress);

  @override
  http.ByteStream finalize() {
    final stream = super.finalize();
    final total = contentLength;
    var sent = 0;
    return http.ByteStream(stream.transform(
      StreamTransformer<List<int>, List<int>>.fromHandlers(
        handleData: (chunk, sink) {
          sent += chunk.length;
          onProgress(sent, total);
          sink.add(chunk);
        },
      ),
    ));
  }
}

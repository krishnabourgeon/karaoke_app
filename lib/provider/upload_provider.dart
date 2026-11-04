import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:karaoke_app/model/get_songs_model.dart';
import 'package:karaoke_app/model/masters_model.dart';
import 'package:karaoke_app/model/search_model.dart';
import 'package:karaoke_app/model/upload_karaoke.dart';
import 'package:karaoke_app/service/app_exceptions.dart';
import 'package:karaoke_app/service/provider_helper_class.dart';
import 'package:karaoke_app/view/common_widgets/common_functions.dart';
import 'package:karaoke_app/view/common_widgets/track.dart';
import 'package:karaoke_app/view/library_store.dart';

class UploadProvider extends ChangeNotifier with ProviderHelperClass {

List<Language>languagesList=[];
List<Genre>genresList=[];
List<Genre>vibesList=[];

SongUpload? songupload;
String? uploadError;
/// 0.0–1.0 while a file is being sent, null when no upload is running.
/// At 1.0 the file is sent and the app is waiting for the server.
double? uploadProgress;

List<SongList>songList=[];
bool songsLoading = false;
String? songsError;
bool songsLoadingMore = false;
int _songsPage = 1;
int _songsLastPage = 1;
bool get songsHasMore => _songsPage < _songsLastPage;

List<SongSearch> songSearchList=[];
bool searchLoading = false;
String? searchError;


  Future<void> getMasters() async{
    final network = await CommonFunctions.checkInternetConnection();
    if (network) {
      //if (isEnableBtnLoader) updateBtnLoader(true);
      try {
        var res = await serviceConfig.getMasters();
        if (res.isValue) {
          MastersModel? mastersResponse = res.asValue!.value;
          if (mastersResponse != null) {
            updateMasters(mastersResponse);
          }
          updateBtnLoader(false);
          updateLoadState(LoaderState.loaded);
        } else {
          updateBtnLoader(false);
          updateLoadState(LoaderState.loaded);
        }
      } catch (e) {
        debugPrint('exception in masters: $e');
        updateLoadState(LoaderState.loaded);
      }
    }
  }


  Future<bool> uploadKaraoke({
    required String title,
    required String languageid,
    required String genreid,
    required String vibeid,
    required String duration,
    required String audio,
    required String video
  }) async{
    uploadError = null;
    final network = await CommonFunctions.checkInternetConnection();
    if(!network){
      uploadError = 'No internet connection';
      return false;
    }
    uploadProgress = 0;
    notifyListeners();
    try{
      var res = await serviceConfig.uploadKaraoke(title: title, languageid: languageid, genreid: genreid, vibeid: vibeid, duration: duration, audio: audio, video: video, onProgress: _setUploadProgress);
      uploadProgress = null;
      updateBtnLoader(false);
      updateLoadState(LoaderState.loaded);
      if(res.isValue){
        updateUpload(res.asValue!.value);
        return true;
      }
      final err = res.asError!.error;
      uploadError = err is String ? err : 'Upload failed. Please try again.';
      return false;
    } on AppException catch(e) {
      debugPrint('exception in upload: ${e.message}');
      uploadError = _messageFrom(e);
      uploadProgress = null;
      updateLoadState(LoaderState.loaded);
      return false;
    } catch(e) {
      debugPrint('exception in upload: $e');
      uploadError = 'Upload failed. Please try again.';
      uploadProgress = null;
      updateLoadState(LoaderState.loaded);
      return false;
    }
  }

  /// Called for every chunk sent; only rebuilds when the whole percent
  /// changes, so a large file does not trigger thousands of rebuilds.
  void _setUploadProgress(int sent, int total) {
    if (total <= 0) return;
    final next = sent / total;
    if (uploadProgress != null &&
        (next * 100).floor() == (uploadProgress! * 100).floor()) {
      return;
    }
    uploadProgress = next;
    notifyListeners();
  }




  /// Loads the first page of songs and hands it to LibraryStore, which every
  /// screen (dashboard, search, library, record picker) reads from.
  /// Later pages are added by [loadMoreSongs].
  Future<void> getSongs() async{
    songsLoading = true;
    songsError = null;
    notifyListeners();
    final network = await CommonFunctions.checkInternetConnection();
    if (!network) {
      songsLoading = false;
      songsError = 'No internet connection';
      notifyListeners();
      return;
    }
    try {
      var res = await serviceConfig.getSongs(page: 1);
      if (res.isValue) {
        updateSong(res.asValue!.value);
      } else {
        songsError = 'Could not load songs. Pull down to try again.';
      }
    } catch (e) {
      debugPrint('exception in songs: $e');
      songsError = 'Could not load songs. Pull down to try again.';
    }
    songsLoading = false;
    notifyListeners();
  }

  /// Appends the next page of songs. Does nothing when a load is already
  /// running or the last page has been reached.
  Future<void> loadMoreSongs() async{
    if (songsLoading || songsLoadingMore || !songsHasMore) return;
    songsLoadingMore = true;
    notifyListeners();
    try {
      var res = await serviceConfig.getSongs(page: _songsPage + 1);
      if (res.isValue) {
        updateSong(res.asValue!.value, append: true);
      }
    } catch (e) {
      // Leave the page number as it is, so scrolling again retries it.
      debugPrint('exception in more songs: $e');
    }
    songsLoadingMore = false;
    notifyListeners();
  }



  Future<void> searchSongs({
    required String search,
    required String vibeid,
    required String languageid,
    required String genreid,
  }) async{
    final network = await CommonFunctions.checkInternetConnection();
    if (!network) {
      searchError = 'No internet connection';
      searchLoading = false;
      notifyListeners();
      return;
    }
    searchLoading = true;
    searchError = null;
    notifyListeners();
    try {
      var res = await serviceConfig.searchSongs(
        search: search,
        vibeid: vibeid,
        languageid: languageid,
        genreid: genreid
      );
      if (res.isValue) {
        SearchModel? searchResponse = res.asValue!.value;
        if (searchResponse != null) {
          updateSearch(searchResponse);
        } 
        updateBtnLoader(false);
        updateLoadState(LoaderState.loaded);
      } else {
        updateBtnLoader(false);
        updateLoadState(LoaderState.loaded);
      }
    } catch (e) {
      debugPrint('exception in masters: $e');
      updateLoadState(LoaderState.loaded);
    }
  }

  /// Pulls "message" out of the API's JSON error body, e.g.
  /// {"status":false,"message":"The duration must be at least 1.", ...}
  String _messageFrom(AppException e) {
    if (e is ApiNotRespondingException) {
      return 'The server took too long to respond. Please try again.';
    }
    try {
      final body = jsonDecode(e.message ?? '');
      if (body is Map && body['message'] is String) return body['message'];
    } catch (_) {}
    return 'Upload failed. Please try again.';
  }

  updateMasters(MastersModel? mastersResponse) {
    languagesList=mastersResponse?.languages??[];
    genresList=mastersResponse?.genres??[];
    vibesList=mastersResponse?.vibes??[];
    notifyListeners();
  }

  updateUpload(UploadKaraoke? uploadKaraoke){
    songupload = uploadKaraoke?.song;
    notifyListeners();
  }

  updateSong(GetSongsModel? getSongResponse, {bool append = false}){
    final page = getSongResponse?.songs ?? [];
    if (append) {
      // Skip songs already in the list, in case one was added while paging.
      final seen = songList.map((s) => s.id).toSet();
      songList = [...songList, ...page.where((s) => !seen.contains(s.id))];
    } else {
      songList = page;
    }
    _songsPage = getSongResponse?.pagination.currentPage ?? 1;
    _songsLastPage = getSongResponse?.pagination.lastPage ?? 1;
    LibraryStore.instance.setSongs(songList.map(Track.fromSong).toList());
    notifyListeners();
  }

  updateSearch(SearchModel searchModel){
    songSearchList = searchModel.songs;
    notifyListeners();
  }

 

  


  @override
  void updateLoadState(LoaderState state) {
    loaderState = state;
    notifyListeners();
  }
}
// To parse this JSON data, do
//
//     final getSongsModel = getSongsModelFromJson(jsonString);

import 'dart:convert';

GetSongsModel getSongsModelFromJson(String str) => GetSongsModel.fromJson(json.decode(str));

String getSongsModelToJson(GetSongsModel data) => json.encode(data.toJson());

class GetSongsModel {
    bool status;
    List<SongList> songs;
    Pagination pagination;

    GetSongsModel({
        required this.status,
        required this.songs,
        required this.pagination,
    });

    factory GetSongsModel.fromJson(Map<String, dynamic> json) => GetSongsModel(
        status: json["status"],
        songs: List<SongList>.from(json["songs"].map((x) => SongList.fromJson(x))),
        pagination: Pagination.fromJson(json["pagination"]),
    );

    Map<String, dynamic> toJson() => {
        "status": status,
        "songs": List<dynamic>.from(songs.map((x) => x.toJson())),
        "pagination": pagination.toJson(),
    };
}

class Pagination {
    int currentPage;
    int lastPage;
    int perPage;
    int total;
    dynamic nextPageUrl;

    Pagination({
        required this.currentPage,
        required this.lastPage,
        required this.perPage,
        required this.total,
        required this.nextPageUrl,
    });

    factory Pagination.fromJson(Map<String, dynamic> json) => Pagination(
        currentPage: json["current_page"],
        lastPage: json["last_page"],
        perPage: json["per_page"],
        total: json["total"],
        nextPageUrl: json["next_page_url"],
    );

    Map<String, dynamic> toJson() => {
        "current_page": currentPage,
        "last_page": lastPage,
        "per_page": perPage,
        "total": total,
        "next_page_url": nextPageUrl,
    };
}

class SongList {
    int id;
    String title;
    LanguageSong? language;
    GenreSong? genre;
    GenreSong? vibe;
    GenreSong? uploadedBy;
    bool isVideo;
    String mediaUrl;
    int? duration;
    String? durationLabel;
    int? fileSize;
    String? fileSizeLabel;
    String? coverImageUrl;
    String status;
    int downloadCount;
    bool isFavorite;
    DateTime createdAt;

    SongList({
        required this.id,
        required this.title,
        required this.language,
        required this.genre,
        required this.vibe,
        required this.uploadedBy,
        required this.isVideo,
        required this.mediaUrl,
        required this.duration,
        required this.durationLabel,
        required this.fileSize,
        required this.fileSizeLabel,
        required this.coverImageUrl,
        required this.status,
        required this.downloadCount,
        required this.isFavorite,
        required this.createdAt,
    });

    factory SongList.fromJson(Map<String, dynamic> json) => SongList(
        id: json["id"],
        title: json["title"],
        // Genre and vibe are optional on upload, so the API can send null.
        language: json["language"] == null ? null : LanguageSong.fromJson(json["language"]),
        genre: json["genre"] == null ? null : GenreSong.fromJson(json["genre"]),
        vibe: json["vibe"] == null ? null : GenreSong.fromJson(json["vibe"]),
        uploadedBy: json["uploaded_by"] == null ? null : GenreSong.fromJson(json["uploaded_by"]),
        isVideo: json["is_video"] ?? false,
        mediaUrl: json["media_url"] ?? "",
        duration: json["duration"],
        durationLabel: json["duration_label"],
        fileSize: json["file_size"],
        fileSizeLabel: json["file_size_label"],
        coverImageUrl: json["cover_image_url"],
        status: json["status"] ?? "",
        downloadCount: json["download_count"] ?? 0,
        isFavorite: json["is_favorite"] ?? false,
        createdAt: DateTime.parse(json["created_at"]),
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "title": title,
        "language": language?.toJson(),
        "genre": genre?.toJson(),
        "vibe": vibe?.toJson(),
        "uploaded_by": uploadedBy?.toJson(),
        "is_video": isVideo,
        "media_url": mediaUrl,
        "duration": duration,
        "duration_label": durationLabel,
        "file_size": fileSize,
        "file_size_label": fileSizeLabel,
        "cover_image_url": coverImageUrl,
        "status": status,
        "download_count": downloadCount,
        "is_favorite": isFavorite,
        "created_at": createdAt.toIso8601String(),
    };
}

class GenreSong {
  int id;
  String name;

  GenreSong({
    required this.id,
    required this.name,
  });

  factory GenreSong.fromJson(Map<String, dynamic> json) => GenreSong(
        id: json["id"],
        name: json["name"] ?? "",
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
      };
}



class LanguageSong {
    int id;
    String name;
    String code;

    LanguageSong({
        required this.id,
        required this.name,
        required this.code,
    });

    factory LanguageSong.fromJson(Map<String, dynamic> json) => LanguageSong(
        id: json["id"],
        name: json["name"],
        code: json["code"],
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "code": code,
    };
}




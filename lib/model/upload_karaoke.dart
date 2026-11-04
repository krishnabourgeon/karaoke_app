// To parse this JSON data, do
//
//     final uploadKaraoke = uploadKaraokeFromJson(jsonString);

import 'dart:convert';

UploadKaraoke uploadKaraokeFromJson(String str) => UploadKaraoke.fromJson(json.decode(str));

String uploadKaraokeToJson(UploadKaraoke data) => json.encode(data.toJson());

class UploadKaraoke {
    bool status;
    String message;
    SongUpload song;

    UploadKaraoke({
        required this.status,
        required this.message,
        required this.song,
    });

    factory UploadKaraoke.fromJson(Map<String, dynamic> json) => UploadKaraoke(
        status: json["status"],
        message: json["message"],
        song: SongUpload.fromJson(json["song"]),
    );

    Map<String, dynamic> toJson() => {
        "status": status,
        "message": message,
        "song": song.toJson(),
    };
}

class SongUpload {
    int id;
    String title;
    LanguageUpload language;
    GenreUpload genre;
    GenreUpload vibe;
    GenreUpload uploadedBy;
    bool isVideo;
    String mediaUrl;
    int duration;
    String durationLabel;
    int fileSize;
    String fileSizeLabel;
    dynamic coverImageUrl;
    String status;
    int downloadCount;
    bool isFavorite;
    DateTime createdAt;

    SongUpload({
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

    factory SongUpload.fromJson(Map<String, dynamic> json) => SongUpload(
        id: json["id"],
        title: json["title"],
        language: LanguageUpload.fromJson(json["language"]),
        genre: GenreUpload.fromJson(json["genre"]),
        vibe: GenreUpload.fromJson(json["vibe"]),
        uploadedBy: GenreUpload.fromJson(json["uploaded_by"]),
        isVideo: json["is_video"],
        mediaUrl: json["media_url"],
        duration: json["duration"],
        durationLabel: json["duration_label"],
        fileSize: json["file_size"],
        fileSizeLabel: json["file_size_label"],
        coverImageUrl: json["cover_image_url"],
        status: json["status"],
        downloadCount: json["download_count"],
        isFavorite: json["is_favorite"],
        createdAt: DateTime.parse(json["created_at"]),
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "title": title,
        "language": language.toJson(),
        "genre": genre.toJson(),
        "vibe": vibe.toJson(),
        "uploaded_by": uploadedBy.toJson(),
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

class GenreUpload {
    int id;
    String name;

    GenreUpload({
        required this.id,
        required this.name,
    });

    factory GenreUpload.fromJson(Map<String, dynamic> json) => GenreUpload(
        id: json["id"],
        name: json["name"],
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
    };
}

class LanguageUpload {
    int id;
    String name;
    String code;

    LanguageUpload({
        required this.id,
        required this.name,
        required this.code,
    });

    factory LanguageUpload.fromJson(Map<String, dynamic> json) => LanguageUpload(
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

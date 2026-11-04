import 'dart:convert';

SearchModel searchFromJson(String str) => SearchModel.fromJson(json.decode(str));

String searchToJson(SearchModel data) => json.encode(data.toJson());

class SearchModel {
  bool status;
  List<SongSearch> songs;
  Pagination pagination;

  SearchModel({
    required this.status,
    required this.songs,
    required this.pagination,
  });

  factory SearchModel.fromJson(Map<String, dynamic> json) => SearchModel(
        status: json["status"],
        songs: List<SongSearch>.from(
          json["songs"].map((x) => SongSearch.fromJson(x)),
        ),
        pagination: Pagination.fromJson(json["pagination"]),
      );

  Map<String, dynamic> toJson() => {
        "status": status,
        "songs": List<dynamic>.from(
          songs.map((x) => x.toJson()),
        ),
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

class SongSearch {
  int id;
  String title;
  LanguageSearch language;
  GenreSearch genre;
  GenreSearch vibe;
  GenreSearch uploadedBy;
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

  SongSearch({
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

  factory SongSearch.fromJson(Map<String, dynamic> json) => SongSearch(
        id: json["id"],
        title: json["title"],
        language: LanguageSearch.fromJson(json["language"]),
        genre: GenreSearch.fromJson(json["genre"]),
        vibe: GenreSearch.fromJson(json["vibe"]),
        uploadedBy: GenreSearch.fromJson(json["uploaded_by"]),
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

class GenreSearch {
  int id;
  String name;

  GenreSearch({
    required this.id,
    required this.name,
  });

  factory GenreSearch.fromJson(Map<String, dynamic> json) => GenreSearch(
        id: json["id"],
        name: json["name"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
      };
}

class LanguageSearch {
  int id;
  String name;
  String code;

  LanguageSearch({
    required this.id,
    required this.name,
    required this.code,
  });

  factory LanguageSearch.fromJson(Map<String, dynamic> json) => LanguageSearch(
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
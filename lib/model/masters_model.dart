// To parse this JSON data, do
//
//     final mastersModel = mastersModelFromJson(jsonString);

import 'dart:convert';

MastersModel mastersModelFromJson(String str) => MastersModel.fromJson(json.decode(str));

String mastersModelToJson(MastersModel data) => json.encode(data.toJson());

class MastersModel {
    List<Language> languages;
    List<Genre> genres;
    List<Genre> vibes;

    MastersModel({
        required this.languages,
        required this.genres,
        required this.vibes,
    });

    factory MastersModel.fromJson(Map<String, dynamic> json) => MastersModel(
        languages: List<Language>.from(json["languages"].map((x) => Language.fromJson(x))),
        genres: List<Genre>.from(json["genres"].map((x) => Genre.fromJson(x))),
        vibes: List<Genre>.from(json["vibes"].map((x) => Genre.fromJson(x))),
    );

    Map<String, dynamic> toJson() => {
        "languages": List<dynamic>.from(languages.map((x) => x.toJson())),
        "genres": List<dynamic>.from(genres.map((x) => x.toJson())),
        "vibes": List<dynamic>.from(vibes.map((x) => x.toJson())),
    };
}

class Genre {
    int id;
    String name;

    Genre({
        required this.id,
        required this.name,
    });

    factory Genre.fromJson(Map<String, dynamic> json) => Genre(
        id: json["id"],
        name: json["name"],
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
    };
}

class Language {
    int id;
    String name;
    String code;

    Language({
        required this.id,
        required this.name,
        required this.code,
    });

    factory Language.fromJson(Map<String, dynamic> json) => Language(
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

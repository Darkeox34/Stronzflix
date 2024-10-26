import 'package:flutter/material.dart' show showDialog;
import 'package:stronzflix/backend/api/player.dart';
import 'package:stronzflix/backend/api/site.dart';

import 'package:stronz_video_player/stronz_video_player.dart' show Playable;
import 'package:stronzflix/backend/storage/settings.dart';
import 'package:stronzflix/dialogs/sources_dialog.dart';
import 'package:stronzflix/stronzflix.dart';

class TitleMetadata {
    final String name;
    final Uri uri;
    final Site site;
    final Uri poster;

    const TitleMetadata({
        required this.name,
        required this.uri,
        required this.site,
        required this.poster
    });
}

class WatchOption {
    final Player player;
    final Uri uri;
    final String displayName;

    Future<Uri> get source => this.player.getSource(this.uri);

    WatchOption({
        required this.player,
        required this.uri,
        String? displayName
    }) : this.displayName = displayName ?? player.name;
}

mixin Watchable implements Playable {
    Uri get uri;
    Site get site;
    TitleMetadata get metadata;

    @override
    Future<Uri> get source async {
        List<WatchOption> options = await this.site.getOptions(this);

        if(Settings.pickSource && options.length > 1) {
            WatchOption opt = await showDialog(
                context: Stronzflix.navigatorKey.currentContext!,
                barrierDismissible: false,
                builder: (context) => SourcesDialog(
                    options: options,
                )
            );
            return await opt.source;
        }

        for(WatchOption opt in options) {
            try {
                return await opt.source;
            } catch(e) {
                continue;
            }
        }
        throw Exception("No valid sources found");
    }

    @override
    Playable? get next => null;

    static String genInfo(Watchable watchable) {
        if (watchable is Film)
            return "";
        else if (watchable is Episode)
            return "${watchable.season.seasonNo}x${watchable.episodeNo}";
        
        throw Exception("Invalid watchable type");
    }

    static Map<String, dynamic> serialize(Watchable watchable) {
        TitleMetadata data = watchable.metadata;
        return {
            "metadata":  {
                "name": data.name,
                "uri": data.uri,
                "site": data.site.name,
                "poster": data.poster
            },
            "info": Watchable.genInfo(watchable)
        };
    }

    static Future<Watchable> unserialize(TitleMetadata metadata, String info, {Title? title}) async {
        title ??= await metadata.site.getTitle(metadata);
        if (title is Film)
            return title;
        else if (title is Series) {
            int seasonNo = int.parse(info.split("x")[0]);
            int episodeNo = int.parse(info.split("x")[1]);

            return title.seasons.firstWhere((season) => season.seasonNo == seasonNo)
                .episodes.firstWhere((episode) => episode.episodeNo == episodeNo);
        }
        
        throw Exception("Invalid title type");
    }
}

abstract class Title {
    final Uri banner;
    final String description;
    final TitleMetadata metadata;
    final DateTime? comingSoon;

    String get name => metadata.name;
    Site get site => metadata.site;

    const Title({
        required this.banner,
        required this.description,
        required this.metadata,
        this.comingSoon
    });
}

class Film extends Title with Watchable {
    @override
    final Uri uri;

    @override
    String get title => this.name;

    @override
    Uri get thumbnail => this.banner;

    const Film({
        required super.banner,
        required super.description,
        required super.metadata,
        super.comingSoon,
        required this.uri
    });
}

class Episode with Watchable {
    final String name;
    final Uri cover;
    final Season season;
    final int episodeNo;

    @override
    final Uri uri;

    @override
    String get title => "${this.season.series.name} S${this.season.seasonNo}:E${this.episodeNo} - ${this.name}";

    @override
    TitleMetadata get metadata => season.series.metadata;

    @override
    Uri get thumbnail => this.cover;

    @override
    Site get site => this.season.series.site;

    @override
    Watchable? get next {
        Season season = this.season;
        Series series = season.series;

        for(Episode episode in season.episodes)
            if (episode.episodeNo > this.episodeNo)
                return episode;

       for(Season season in series.seasons)
            if (season.seasonNo > this.season.seasonNo)
                return season.episodes.first;

        return null;
    }

    const Episode({
        required this.name,
        required this.cover,
        required this.uri,
        required this.season,
        required this.episodeNo
    });
}

class Season {
    final String? name;
    final int seasonNo;
    final Series series;
    final List<Episode> episodes;

    const Season({
        this.name,
        required this.series,
        required this.episodes,
        required this.seasonNo
    });
}

class Series extends Title {
    final List<Season> seasons;
    
    const Series({
        required super.banner,
        required super.description,
        super.comingSoon,
        required this.seasons,
        required super.metadata
    });
}

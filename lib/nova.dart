import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'bandcamp.dart';
import 'helpers.dart';

import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:html_unescape/html_unescape.dart';
import 'package:html/parser.dart' as parser;

const String radioNova = 'https://www.nova.fr/wp-json/radios/';

class Nova extends Channel {
  static List<dynamic> subchannels = [
    {
      "code": "radio-nova",
      "name": "Radio Nova",
      "id": "910",
      "image": "/2/2022/12/Radio-Nova-en-direct.png"
    },
    {
      "code": "nouvo-nova",
      "name": "Nouvo Nova",
      "id": "79676",
      "image": "/2/2022/11/Web-radio--Nouvo-Nova.png"
    },
    {
      "code": "nova-la-nuit",
      "name": "Nova la Nuit",
      "id": "916",
      "image": "/2/2022/11/Web-radio--Nova-la-Nuit.png"
    },
    {
      "code": "nova-classics",
      "name": "Nova Classics",
      "id": "913",
      "image": "/2/2020/10/Web-radio--Nova-Classics.png"
    },
    {
      "code": "nova-danse",
      "name": "Nova Danse",
      "id": "560",
      "image": "/2/2020/09/Web-radio--Nova-Danse.png"
    },
  ];

  // datetime until which the last update request is valid according to cache-control(max-age) header, age and date
  static DateTime validity =
      DateTime.now().subtract(const Duration(minutes: 1));

  Nova(String code, String name, String imageUrl, String id)
      : super(radio: 'Radio Nova') {
    subchannel.codename = code;
    subchannel.title = name;
    subchannel.id = id;
    subchannel.imageUrl =
        'https://www.nova.fr/wp-content/uploads/sites$imageUrl';
    subchannel.bigImageUrl = subchannel.imageUrl;
    show.description = "";
  }

  @override
  String toString() {
    return 'Nova(subchannel: ${subchannel.toString()}';
  }

  int updateFromJson(Map<String, dynamic> json) {
    int ret = 0;

    final ct = json['currentTrack'];
    if (ct != null) {
      if (currentTrack.title != ct['title']) {
        ret += 1;
        currentTrack.id = int.parse(ct['id']);
        currentTrack.artist = ct['artist'];
        currentTrack.title = ct['title'];
        currentTrack.imageUrl = ct['image'] is String ? ct['image'] : '';
        if (currentTrack.imageUrl.endsWith('nova-default.png')) {
          currentTrack.imageUrl = '';
        }
        currentTrack.diffusionDate = ct['diffusion_date'];
        currentTrack.duration = ct['duration'];
        //final ds = currentTrack.duration.split(':');
        debugPrint('debug: ${subchannel.id}');
        if (subchannel.id == '910') {
          // WTF: why does the datetime always late for around 10 minutes??
          // add 10 minutes for Radio Nova
          currentTrack.diffusionDate = DateTime.parse(
                  currentTrack.diffusionDate)
              .add(const Duration(minutes: 10))
              // but subtract track length
              //.subtract(
              //    Duration(minutes: int.parse(ds[0]), seconds: int.parse(ds[1])))
              .toIso8601String();
        } else {
          currentTrack.diffusionDate =
              DateTime.parse(currentTrack.diffusionDate).toIso8601String();
        }
      }
    }
    final cs = json['currentShow'];
    if (cs != null) {
      show.name = cs['title'];
      show.author = HtmlUnescape().convert(cs['author']);
      show.airingTime = '${cs["start_time"]} - ${cs["end_time"]}';
    }
    final radio = json['radio'];
    if (radio != null) {
      show.imageUrl = radio['thumbnail'];
    }
    return ret;
  }

  @override
  Future<int> fetchCurrentTrack([bool manual = false]) async {
    int ret = 0;

    final http.Response resp;
    // update if cache is old
    if (DateTime.now().compareTo(validity) >= 0) {
      try {
        resp = await http.get(Uri.parse('$radioNova${subchannel.codename}'));
        //print(resp.statusCode);
      } catch (e) {
        debugPrint('debug: $e');
        return 0;
      }

      if (resp.statusCode == 200) {
        ret = updateFromJson(jsonDecode(resp.body));
        // try to get an image cover if there is none
        if (currentTrack.artist != 'Artist' && currentTrack.imageUrl.isEmpty) {
          ResponseBandcamp resp = await searchBandcamp(
              '${currentTrack.artist} ${currentTrack.title}', 't');
          if (resp.imageUrl.isNotEmpty) {
            currentTrack.imageUrl = resp.imageUrl;
          }
        }
        // update validity variable
        int age = 0;
        if (ret > 0) {
          // parse age header
          String? ageHeader = resp.headers['age'];
          if (ageHeader != null) {
            age = int.parse(ageHeader);
          }
          int maxAge = 0;
          // parse cache-control header
          String? cacheControl = resp.headers['cache-control'];
          if (cacheControl != null) {
            final cc = cacheControl.split(',');
            for (var element in cc) {
              String e = element.trim().toLowerCase();
              if (e.startsWith('max-age=')) {
                maxAge = int.parse(e.replaceFirst('max-age=', ''));
                break;
              }
            }
          }
          // add cache age to date header
          String? date = resp.headers['date'];
          if (date != null) {
            validity = DateFormat('EEE, d MMM y HH:mm:ss Z', 'en_US')
                .parse(date.replaceAll('GMT', '+0000'), true)
                .add(Duration(seconds: maxAge - age));
          }
        }
      }
    } else {
      ret = 0;
    }
    recentTracks = await getRecentTracks();
    // if ajax call returned nothing but last track list is more up to date
    if (recentTracks.isNotEmpty) {
      Track lastTrack = recentTracks[0];
      final DateTime ltd = DateTime.parse(lastTrack.diffusionDate);
      final DateTime cd = DateTime.parse(currentTrack.diffusionDate);
      if (cd.compareTo(ltd) == -1) {
        debugPrint('Late update');
        currentTrack.updateFrom(lastTrack);
      }
    }
    notifyListeners();

    return ret;
  }

  @override
  Future<List<Track>> getRecentTracks() async {
    String url = 'https://www.nova.fr/wp-admin/admin-ajax.php';
    List<Track> ret = <Track>[];

    // 20 minutes from now
    String now = DateTime.now().toString();
    String startTime = now.substring(11, 16);
    // action=loadmore_programs&date=&time=18%3A08&page=1&radio=910
    String radioId = subchannel.id;
    final rawData = {
      'action': 'loadmore_programs',
      'date': '',
      'time': startTime,
      'page': '1',
      'radio': radioId
    };
    final headers = {
      'x-requested-with': 'XMLHttpRequest',
      'content-type': 'application/x-www-form-urlencoded; charset=UTF-8',
      'user-agent': AppConfig.userAgent,
    };
    final http.Response resp;
    try {
      resp = await http.post(Uri.parse(url), body: rawData, headers: headers);
      //print(resp.statusCode);
    } catch (e) {
      debugPrint('debug: $e');
      return ret;
    }

    if (resp.statusCode != 200) {
      return ret;
    }
    final document = parser.parse(resp.body);
    for (var element in document.getElementsByClassName('wwtt_right')) {
      final time = element.querySelector('p.time')?.text;
      final dd = '${now.substring(0, 10)}T$time:00';
      String diffusionDate;
      if (subchannel.id == '910') {
        // add 10 minutes
        diffusionDate = DateTime.parse(dd)
            .add(const Duration(minutes: 10))
            .toIso8601String();
      } else {
        diffusionDate = DateTime.parse(dd).toIso8601String();
      }
      final title = element.querySelectorAll('p')[1].text;
      final artist = element.querySelector('h2');
      final imgWwtt = element.querySelector('.img_wwtt');
      final img = imgWwtt?.getElementsByTagName('img');
      String imageUrl = '';
      if (img != null && img.isNotEmpty) {
        imageUrl = img.first.attributes['src']!;
      }

      Track track = Track(
          diffusionDate: diffusionDate,
          title: title,
          artist: artist != null ? artist.text : 'Artist',
          imageUrl: imageUrl);
      //debugPrint('$track');
      ret.add(track);
    }
    //debugPrint(ret);
    return ret;
  }
}

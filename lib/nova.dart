import 'dart:convert';

import 'package:nova_title/bandcamp.dart';

import 'track.dart';

import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:html_unescape/html_unescape.dart';

const String radioNova = 'https://www.nova.fr/wp-json/radios/radio-nova';
const String defaultShowImageUrl =
    'https://www.nova.fr/wp-content/uploads/sites/2/2022/12/Radio-Nova-en-direct.png';

class NovaTrack extends Track {
  // datetime until which the last update request is valid according to cache-control(max-age) header, age and date
  static DateTime validity =
      DateTime.now().subtract(const Duration(minutes: 1));

  int updateFromJson(Map<String, dynamic> json) {
    int ret = 0;
    currentShow.imageUrl = json['radio']['thumbnail'];

    Map<String, dynamic>? ct = json['currentTrack'];
    if (ct != null) {
      int oldId = id;
      id = int.parse(ct['id']);
      if (oldId != id) {
        ret += 1;
        artist = ct['artist'];
        title = ct['title'];
        imageUrl = ct['image'] is String ? ct['image'] : '';
        diffusionDate = ct['diffusion_date'];
        duration = ct['duration'];
        final ds = duration.split(':');
        // WTF: why does the datetime always late for around 10 minutes??
        diffusionDate = DateTime.parse(diffusionDate)
            // add 10 minutes
            .add(const Duration(minutes: 10))
            // but subtract track length
            .subtract(
                Duration(minutes: int.parse(ds[0]), seconds: int.parse(ds[1])))
            .toIso8601String();
      }
    }
    Map<String, dynamic>? cs = json['currentShow'];
    if (cs != null) {
      currentShow.title = cs['title'];
      currentShow.author = HtmlUnescape().convert(cs['author']);
      currentShow.airingTime = '${cs["start_time"]} - ${cs["end_time"]}';
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
        resp = await http.get(Uri.parse(radioNova));
      } catch (e) {
        return 0;
      }

      if (resp.statusCode == 200) {
        ret = updateFromJson(jsonDecode(resp.body));
        // try to get an image cover if there is none
        if (id != -1 && imageUrl.isEmpty) {
          ResponseBandcamp resp = await searchBandcamp('$artist $title', 't');
          if (resp.imageUrl.isNotEmpty) {
            imageUrl = resp.imageUrl;
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
    notifyListeners();

    return ret;
  }
}

import 'dart:convert';

import 'bandcamp.dart';
import 'helpers.dart';

import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:html_unescape/html_unescape.dart';
import 'package:web_scraper/web_scraper.dart';

const String radioNova = 'https://www.nova.fr/wp-json/radios/radio-nova';
const String defaultShowImageUrl =
    'https://www.nova.fr/wp-content/uploads/sites/2/2022/12/Radio-Nova-en-direct.png';

class Nova extends Channel {
  // datetime until which the last update request is valid according to cache-control(max-age) header, age and date
  static DateTime validity =
      DateTime.now().subtract(const Duration(minutes: 1));

  Nova() {
    radio = 'Radio Nova';
    subchannel = '';
    imageUrl = defaultShowImageUrl;
  }

  int updateFromJson(Map<String, dynamic> json) {
    int ret = 0;

    final ct = json['currentTrack'];
    if (ct != null) {
      int oldId = currentTrack.id;
      currentTrack.id = int.parse(ct['id']);
      if (oldId != currentTrack.id) {
        ret += 1;
        currentTrack.artist = ct['artist'];
        currentTrack.title = ct['title'];
        currentTrack.imageUrl = ct['image'] is String ? ct['image'] : '';
        currentTrack.diffusionDate = ct['diffusion_date'];
        currentTrack.duration = ct['duration'];
        final ds = currentTrack.duration.split(':');
        // WTF: why does the datetime always late for around 10 minutes??
        currentTrack.diffusionDate = DateTime.parse(currentTrack.diffusionDate)
            // add 10 minutes
            .add(const Duration(minutes: 10))
            // but subtract track length
            .subtract(
                Duration(minutes: int.parse(ds[0]), seconds: int.parse(ds[1])))
            .toIso8601String();
      }
    }
    final cs = json['currentShow'];
    if (cs != null) {
      title = cs['title'];
      author = HtmlUnescape().convert(cs['author']);
      airingTime = '${cs["start_time"]} - ${cs["end_time"]}';
      subchannel = '';
    }
    final radio = json['radio'];
    if (radio != null) {
      imageUrl = radio['thumbnail'];
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
        if (currentTrack.id != -1 && currentTrack.imageUrl.isEmpty) {
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
    notifyListeners();

    return ret;
  }

  @override
  Future<List<Track>> getRecentTracks() async {
    String url = 'https://www.nova.fr/wp-admin/admin-ajax.php';
    WebScraper webScraper = WebScraper();
    List<Track> ret = <Track>[];

    // 20 minutes from now
    String startTime = DateTime.now().toString().substring(11, 16);
    // action=loadmore_programs&date=&time=18%3A08&page=1&radio=910
    String rawData =
        'action=loadmore_programs&date=&time=$startTime&page=1&radio=910';

    http.Request req = http.Request('POST', Uri.parse(url));
    req.body = Uri.encodeFull(rawData);
    req.headers.addAll({
      'x-requested-with': 'XMLHttpRequest',
      'content-type': 'application/x-www-form-urlencoded; charset=UTF-8',
    });
    http.StreamedResponse streamedResponse = await req.send();
    final resp = await http.Response.fromStream(streamedResponse);

    if (resp.statusCode == 200) {
      if (webScraper.loadFromString(resp.body)) {
        List<Map<String, dynamic>> elements =
            webScraper.getElement('div.wwtt_right p', ['class']);
        //print(elements);
        String dd = '', title = '';
        for (var e in elements) {
          //print(e);
          if (e['attributes']['class'] != null &&
              e['attributes']['class'].split(' ').contains('time')) {
            dd = '2000-01-01T${e["title"]}:00';
          } else {
            title = e['title'];
          }
          if (dd != '' && title != '') {
            Track track = Track(diffusionDate: dd, title: title);
            //print(track);
            ret.add(track);
            dd = '';
            title = '';
          }
        }
        elements = webScraper.getElement('div.wwtt_right h2', []);
        //print(elements);
        int indx = 0;
        for (var e in elements) {
          ret[indx].artist = e['title'];
          indx++;
        }
      }
    }
    //print(ret);
    return ret;
  }
}

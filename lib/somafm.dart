import 'package:web_scraper/web_scraper.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

import 'track.dart';
import 'bandcamp.dart';

class SomaFmTrack extends Track {
  static const channels = {
    "groovesalad": {"name": "Groove Salad", "image": "groovesalad120.png"},
    "gsclassic": {"name": "Groove Salad Classic", "image": "gsclassic120.jpg"},
    "synphaera": {"name": "Synphaera Radio", "image": "synphaera120.jpg"},
    "dronezone": {"name": "Drone Zone", "image": "dronezone120.jpg"},
    "darkzone": {"name": "The Dark Zone", "image": "darkzone-120.jpg"},
    "metal": {"name": "Metal Detector", "image": "metal120.png"},
    "illstreet": {"name": "Illinois Street Lounge", "image": "illstreet.jpg"},
    "suburbsofgoa": {"name": "Suburbs of Goa", "image": "sog120.jpg"},
    "bootliquor": {"name": "Boot Liquor", "image": "bootliquor120.jpg"},
    "7soul": {"name": "Seven Inch Soul", "image": "7soul120.png"},
    "seventies": {"name": "Left Coast 70s", "image": "seventies120.jpg"},
    "u80s": {"name": "Underground 80s", "image": "u80s-120.png"},
    "defcon": {"name": "DEF CON Radio", "image": "defcon120.png"},
    "fluid": {"name": "Fluid", "image": "fluid120.jpg"},
    "lush": {"name": "Lush", "image": "lush120.jpg"},
    "poptron": {"name": "PopTron", "image": "poptron120.png"},
    "covers": {"name": "Covers", "image": "covers120.jpg"},
    "cliqhop": {"name": "cliqhop idm", "image": "cliqhop120.png"},
    "dubstep": {"name": "Dub Step Beyond", "image": "dubstep120.png"},
    "beatblender": {"name": "Beat Blender", "image": "blender120.png"},
    "deepspaceone": {"name": "Deep Space One", "image": "deepspaceone120.gif"},
    "spacestation": {"name": "Space Station Soma", "image": "sss.jpg"},
    "n5md": {"name": "n5MD Radio", "image": "n5md120.png"},
    "vaporwaves": {"name": "Vaporwaves", "image": "vaporwaves120.jpg"},
    "secretagent": {"name": "Secret Agent", "image": "secretagent120.jpg"},
    "reggae": {"name": "Heavyweight Reggae", "image": "reggae120.png"},
    "thetrip": {"name": "The Trip", "image": "thetrip120.jpg"},
    "sonicuniverse": {
      "name": "Sonic Universe",
      "image": "sonicuniverse120.jpg"
    },
    "missioncontrol": {
      "name": "Mission Control",
      "image": "missioncontrol120.jpg"
    },
    "indiepop": {"name": "Indie Pop Rocks!", "image": "indychick.jpg"},
    "digitalis": {"name": "Digitalis", "image": "digitalis120.png"},
    "folkfwd": {"name": "Folk Forward", "image": "folkfwd120.jpg"},
    "thistle": {"name": "ThistleRadio", "image": "thistle120.png"},
    "brfm": {"name": "Black Rock FM", "image": "1023brc.jpg"},
    "sf1033": {"name": "SF 10-33", "image": "sf1033120.png"},
    "scanner": {"name": "SF Police Scanner", "image": "sf1033120.png"},
    "live": {"name": "SomaFM Live", "image": "SomaFMDJSquare120.jpg"},
    "xmasinfrisko": {"name": "Xmas in Frisko", "image": "xmasinfrisco120.jpg"},
    "christmas": {
      "name": "Christmas Lounge",
      "image": "christmaslounge120.png"
    },
    "xmasrocks": {"name": "Christmas Rocks!", "image": "xmasrocks120.png"},
    "jollysoul": {"name": "Jolly Ol' Soul", "image": "jollysoul120.png"},
    "specials": {
      "name": "Department Store Christmas",
      "image": "deptstorexmas120.jpg"
    },
  };

  @override
  Future<int> fetchCurrentTrack([bool manual = false]) async {
    int ret = 0;
    Track track = await SomaFmTrack.getLastTrack(currentShow.channel);
    if (track.title != title && track.artist != artist) {
      updateFrom(track);
      String newImageUrl =
          await searchBandcamp('${track.title} ${track.artist}', 't');
      if (newImageUrl.isNotEmpty) {
        imageUrl = newImageUrl;
      } else {
        newImageUrl =
            await searchBandcamp('${track.album} ${track.artist}', 'a');
        if (newImageUrl.isNotEmpty) {
          imageUrl = newImageUrl;
        }
      }
      notifyListeners();
      ret += 1;
    }
    return ret;
  }

  static Future<Track> getLastTrack(String channel) async {
    List<Track> recentTracks = await SomaFmTrack.getRecentTrack(channel);
    if (recentTracks.isNotEmpty) {
      return recentTracks.elementAt(0);
    } else {
      return Track();
    }
  }

  static Future<List<Track>> getRecentTrack(String channel) async {
    // get timezone and current date of San Francisco
    tz.initializeTimeZones();
    tz.Location sanFrancisco = tz.getLocation('America/Los_Angeles');
    tz.TZDateTime now = tz.TZDateTime.now(sanFrancisco);
    String timeZone = convertSecondsToHours(
        sanFrancisco.timeZone(now.millisecondsSinceEpoch).offset ~/ 1000);
    String currentDate = now.toString().substring(0, 10);

    WebScraper webScraper = WebScraper('https://somafm.com');

    List<Track> ret = <Track>[];
    String page = '/recent/$channel.html';
    if (await webScraper.loadWebPage(page)) {
      List<Map<String, dynamic>> elements =
          webScraper.getElement('#playinc table tr td', ['colspan']);
      //print(elements);
      List<String> columns = [];
      for (var e in elements) {
        //print(e);
        if (e['attributes']['colspan'] != null) {
          columns.clear();
          continue;
        }
        columns.add(e['title'].replaceFirst(' (Now) ', '').trim());
        if (columns.length == 5) {
          if (!columns[0].startsWith('Played At')) {
            // convert SF local time to our local time
            // add current SF date in front of parsed hour
            DateTime diffusionDate =
                DateTime.parse('${currentDate}T${columns[0]} $timeZone');
            Track track = Track(
                diffusionDate:
                    diffusionDate.toLocal().toString().replaceFirst(' ', 'T'),
                artist: columns[1],
                title: columns[2],
                album: columns[3],
                radio: 'Soma FM');
            ret.add(track);
            //print(
            //     '${track.diffusionDate} ${track.title} - ${track.artist} [${track.album}]');
          }
          columns.clear();
        }
        //print(count);
      }
    }
    return ret;
  }
}

String convertSecondsToHours(int offset) {
  int minutes = offset ~/ 60;
  int hours = minutes ~/ 60;
  String sh = hours.abs().toString().padLeft(2, '0');
  String sign = '';
  if (hours / hours.abs() < 0) sign = '-';
  String sm = (minutes % 60).toString().padLeft(2, '0');
  return '$sign$sh$sm';
}

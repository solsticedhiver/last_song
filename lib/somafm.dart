import 'package:web_scraper/web_scraper.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

import 'track.dart';
import 'bandcamp.dart';

class SomaFmTrack extends Track {
  static const channels = {
    "Groove Salad": {"code": "groovesalad", "image": "groovesalad120.png"},
    "Groove Salad Classic": {"code": "gsclassic", "image": "gsclassic120.jpg"},
    "Synphaera Radio": {"code": "synphaera", "image": "synphaera120.jpg"},
    "Drone Zone": {"code": "dronezone", "image": "dronezone120.jpg"},
    "The Dark Zone": {"code": "darkzone", "image": "darkzone-120.jpg"},
    "Metal Detector": {"code": "metal", "image": "metal120.png"},
    "Illinois Street Lounge": {"code": "illstreet", "image": "illstreet.jpg"},
    "Suburbs of Goa": {"code": "suburbsofgoa", "image": "sog120.jpg"},
    "Boot Liquor": {"code": "bootliquor", "image": "bootliquor120.jpg"},
    "Seven Inch Soul": {"code": "7soul", "image": "7soul120.png"},
    "Left Coast 70s": {"code": "seventies", "image": "seventies120.jpg"},
    "Underground 80s": {"code": "u80s", "image": "u80s-120.png"},
    "DEF CON Radio": {"code": "defcon", "image": "defcon120.png"},
    "Fluid": {"code": "fluid", "image": "fluid120.jpg"},
    "Lush": {"code": "lush", "image": "lush120.jpg"},
    "PopTron": {"code": "poptron", "image": "poptron120.png"},
    "Covers": {"code": "covers", "image": "covers120.jpg"},
    "cliqhop idm": {"code": "cliqhop", "image": "cliqhop120.png"},
    "Dub Step Beyond": {"code": "dubstep", "image": "dubstep120.png"},
    "Beat Blender": {"code": "beatblender", "image": "blender120.png"},
    "Deep Space One": {"code": "deepspaceone", "image": "deepspaceone120.gif"},
    "Space Station Soma": {"code": "spacestation", "image": "sss.jpg"},
    "n5MD Radio": {"code": "n5md", "image": "n5md120.png"},
    "Vaporwaves": {"code": "vaporwaves", "image": "vaporwaves120.jpg"},
    "Secret Agent": {"code": "secretagent", "image": "secretagent120.jpg"},
    "Heavyweight Reggae": {"code": "reggae", "image": "reggae120.png"},
    "The Trip": {"code": "thetrip", "image": "thetrip120.jpg"},
    "Sonic Universe": {
      "code": "sonicuniverse",
      "image": "sonicuniverse120.jpg"
    },
    "Mission Control": {
      "code": "missioncontrol",
      "image": "missioncontrol120.jpg"
    },
    "Indie Pop Rocks!": {"code": "indiepop", "image": "indychick.jpg"},
    "Digitalis": {"code": "digitalis", "image": "digitalis120.png"},
    "Folk Forward": {"code": "folkfwd", "image": "folkfwd120.jpg"},
    "ThistleRadio": {"code": "thistle", "image": "thistle120.png"},
    "Black Rock FM": {"code": "brfm", "image": "1023brc.jpg"},
    "SF 10-33": {"code": "sf1033", "image": "sf1033120.png"},
    "SF Police Scanner": {"code": "scanner", "image": "sf1033120.png"},
    "SomaFM Live": {"code": "live", "image": "SomaFMDJSquare120.jpg"},
    "Xmas in Frisko": {"code": "xmasinfrisko", "image": "xmasinfrisco120.jpg"},
    "Christmas Lounge": {
      "code": "christmas",
      "image": "christmaslounge120.png"
    },
    "Christmas Rocks!": {"code": "xmasrocks", "image": "xmasrocks120.png"},
    "Jolly Ol' Soul": {"code": "jollysoul", "image": "jollysoul120.png"},
    "Department Store Christmas": {
      "code": "specials",
      "image": "deptstorexmas120.jpg"
    },
  };

  @override
  Future<int> fetchCurrentTrack([bool manual = false]) async {
    int ret = 0;
    Track track = await SomaFmTrack.getLastTrack(currentShow.title);
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

  static Future<Track> getLastTrack(String radio) async {
    List<Track> recentTracks = await SomaFmTrack.getRecentTrack(radio);
    if (recentTracks.isNotEmpty) {
      return recentTracks.elementAt(0);
    } else {
      return Track();
    }
  }

  static Future<List<Track>> getRecentTrack(String radio) async {
    // get timezone and current date of San Francisco
    tz.initializeTimeZones();
    tz.Location sanFrancisco = tz.getLocation('America/Los_Angeles');
    tz.TZDateTime now = tz.TZDateTime.now(sanFrancisco);
    String timeZone = convertSecondsToHours(
        sanFrancisco.timeZone(now.millisecondsSinceEpoch).offset ~/ 1000);
    String currentDate = now.toString().substring(0, 10);

    WebScraper webScraper = WebScraper('https://somafm.com');

    List<Track> ret = <Track>[];
    String page = '/recent/${SomaFmTrack.channels[radio]?["code"]}.html';
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

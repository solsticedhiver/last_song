import 'package:web_scraper/web_scraper.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

import 'helpers.dart';
import 'bandcamp.dart';
import 'discogs.dart';

class SomaFm extends Channel {
  static const _subchannels = {
    "groovesalad": {
      "name": "Groove Salad",
      "image": "/img/groovesalad120.png",
      "big": "/img3/groovesalad-400.png",
      "descr": "A nicely chilled plate of ambient/downtempo beats and grooves."
    },
    "gsclassic": {
      "name": "Groove Salad Classic",
      "image": "/img3/gsclassic120.jpg",
      "big": "/img3/gsclassic400.jpg",
      "descr":
          "The classic (early 2000s) version of a nicely chilled plate of ambient/downtempo beats and grooves."
    },
    "synphaera": {
      "name": "Synphaera Radio",
      "image": "/img3/synphaera120.jpg",
      "big": "/img3/synphaera400.jpg",
      "descr":
          "Featuring the music from an independent record label focused on modern electronic ambient and space music."
    },
    "dronezone": {
      "name": "Drone Zone",
      "image": "/img/dronezone120.jpg",
      "big": "/img3/dronezone-400.png",
      "descr":
          "Served best chilled, safe with most medications. Atmospheric textures with minimal beats."
    },
    "darkzone": {
      "name": "The Dark Zone",
      "image": "/img/darkzone-120.jpg",
      "big": "/img/darkzone-400.jpg",
      "descr": "",
    },
    "metal": {
      "name": "Metal Detector",
      "image": "/img3/metal120.png",
      "big": "/img3/metal-400.png",
      "descr": "",
    },
    "illstreet": {
      "name": "Illinois Street Lounge",
      "image": "/img/illstreet.jpg",
      "big": "/img3/illstreet-400.jpg",
      "descr": "",
    },
    "suburbsofgoa": {
      "name": "Suburbs of Goa",
      "image": "/img/sog120.jpg",
      "big": "/img3/suburbsofgoa-400.png",
      "descr": "",
    },
    "bootliquor": {
      "name": "Boot Liquor",
      "image": "/img/bootliquor120.jpg",
      "big": "/img3/bootliquor-400.png",
      "descr": "",
    },
    "7soul": {
      "name": "Seven Inch Soul",
      "image": "/img/7soul120.png",
      "big": "/img3/7soul-400.jpg",
      "descr": "",
    },
    "seventies": {
      "name": "Left Coast 70s",
      "image": "/img/seventies120.jpg",
      "big": "/img3/seventies400.jpg",
      "descr": "",
    },
    "u80s": {
      "name": "Underground 80s",
      "image": "/img/u80s-120.png",
      "big": "/img3/u80s-400.png",
      "descr": "",
    },
    "defcon": {
      "name": "DEF CON Radio",
      "image": "/img/defcon120.png",
      "big": "/img3/defcon-400.png",
      "descr": "",
    },
    "fluid": {
      "name": "Fluid",
      "image": "/img/fluid120.jpg",
      "big": "/img3/fluid-400.jpg",
      "descr": "",
    },
    "lush": {
      "name": "Lush",
      "image": "/img/lush120.jpg",
      "big": "/img3/lush-400.jpg",
      "descr": "",
    },
    "poptron": {
      "name": "PopTron",
      "image": "/img/poptron120.png",
      "big": "/img3/poptron-400.png",
      "descr": "",
    },
    "covers": {
      "name": "Covers",
      "image": "/img/covers120.jpg",
      "big": "/img3/covers-400.png",
      "descr": "",
    },
    "cliqhop": {
      "name": "cliqhop idm",
      "image": "/img/cliqhop120.png",
      "big": "/img3/cliqhop-400.png",
      "descr": "",
    },
    "dubstep": {
      "name": "Dub Step Beyond",
      "image": "/img/dubstep120.png",
      "big": "/img3/dubstep-400.png",
      "descr": "",
    },
    "beatblender": {
      "name": "Beat Blender",
      "image": "/img/blender120.png",
      "big": "/img3/beatblender-400.png",
      "descr": "",
    },
    "deepspaceone": {
      "name": "Deep Space One",
      "image": "/img/deepspaceone120.gif",
      "big": "/img3/deepspaceone-400.png",
      "descr": "",
    },
    "spacestation": {
      "name": "Space Station Soma",
      "image": "/img/sss.jpg",
      "big": "/img3/spacestation-400.png",
      "descr": "",
    },
    "n5md": {
      "name": "n5MD Radio",
      "image": "/img/n5md120.png",
      "big": "/img3/n5md-400.png",
      "descr": "",
    },
    "vaporwaves": {
      "name": "Vaporwaves",
      "image": "/img/vaporwaves120.jpg",
      "big": "/img3/vaporwaves400.png",
      "descr": "",
    },
    "secretagent": {
      "name": "Secret Agent",
      "image": "/img/secretagent120.jpg",
      "big": "/img3/secretagent-400.png",
      "descr": "",
    },
    "reggae": {
      "name": "Heavyweight Reggae",
      "image": "/img3/reggae120.png",
      "big": "/img3/reggae400.png",
      "descr": "",
    },
    "thetrip": {
      "name": "The Trip",
      "image": "/img/thetrip120.jpg",
      "big": "/img3/thetrip-400.jpg",
      "descr": "",
    },
    "sonicuniverse": {
      "name": "Sonic Universe",
      "image": "/img/sonicuniverse120.jpg",
      "big": "/img3/sonicuniverse-400.png",
      "descr": "",
    },
    "missioncontrol": {
      "name": "Mission Control",
      "image": "/img/missioncontrol120.jpg",
      "big": "/img3/missioncontrol-400.png",
      "descr": "",
    },
    "indiepop": {
      "name": "Indie Pop Rocks!",
      "image": "/img/indychick.jpg",
      "big": "/img3/indiepop-400.png",
      "descr": "",
    },
    "digitalis": {
      "name": "Digitalis",
      "image": "/img/digitalis120.png",
      "big": "/img3/digitalis-400.png",
      "descr": "",
    },
    "folkfwd": {
      "name": "Folk Forward",
      "image": "/img/folkfwd120.jpg",
      "big": "/img3/folkfwd-400.jpg",
      "descr": "",
    },
    "thistle": {
      "name": "ThistleRadio",
      "image": "/img/thistle120.png",
      "big": "/img3/thistle-400.jpg",
      "descr": "",
    },
    "brfm": {
      "name": "Black Rock FM",
      "image": "/img/1023brc.jpg",
      "big": "/img3/brfm-400.png",
      "descr": "",
    },
    "sf1033": {
      "name": "SF 10-33",
      "image": "/img/sf1033120.png",
      "big": "/img3/sf1033-400.png",
      "descr": "",
    },
    "scanner": {
      "name": "SF Police Scanner",
      "image": "/img/sf1033120.png",
      "big": "/img3/sf1033-400.png",
      "descr": "",
    },
    "live": {
      "name": "SomaFM Live",
      "image": "/img/SomaFMDJSquare120.jpg",
      "big": "/img3/live-400.jpg",
      "descr": "",
    },
    "xmasinfrisko": {
      "name": "Xmas in Frisko",
      "image": "/img/xmasinfrisco120.jpg",
      "big": "/img3/live-400.jpg",
      "descr": "",
    },
    "christmas": {
      "name": "Christmas Lounge",
      "image": "/img/christmaslounge120.png",
      "big": "/img3/christmas-400.jpg",
      "descr": "",
    },
    "xmasrocks": {
      "name": "Christmas Rocks!",
      "image": "/img/xmasrocks120.png",
      "big": "/img3/xmasrocks-400.png",
      "descr": "",
    },
    "jollysoul": {
      "name": "Jolly Ol' Soul",
      "image": "/img/jollysoul120.png",
      "big": "/img3/jollysoul-400.png",
      "descr": "",
    },
    /*
    "specials": {
      "name": "Department Store Christmas",
      "image": "/img3/deptstorexmas120.jpg",
      "big": "/img3/deptstorexmas-400.png",
    "descr":"",
},
    */
  };

  @override
  Map<String, dynamic> get subchannels => _subchannels;

  static Map<String, dynamic> get getSubchannels => _subchannels;

  SomaFm(String subchannel) : super(radio: 'Some FM') {
    String? scn = subchannels[subchannel]?['name'];
    if (scn != null) {
      this.subchannel.title = scn;
    }
    String? sci = subchannels[subchannel]?['image'];
    if (sci != null) {
      this.subchannel.imageUrl = 'https://somafm.com$sci';
    }
    String? scb = subchannels[subchannel]?['big'];
    if (scb != null) {
      this.subchannel.bigImageUrl = 'https://somafm.com$scb';
    }
    this.subchannel.codename = subchannel;
    show.author = 'Rusty Hodge';
    show.airingTime = '';
    show.imageUrl = this.subchannel.bigImageUrl;
    show.name = this.subchannel.title;
    show.description = subchannels[subchannel]?['descr'];
  }

  @override
  Future<int> fetchCurrentTrack([bool manual = false]) async {
    int ret = 0;
    Track track;

    recentTracks = await getRecentTracks();
    if (recentTracks.isNotEmpty) {
      track = recentTracks.elementAt(0);
    } else {
      track = Track();
    }

    if (track.title != currentTrack.title &&
        track.artist != currentTrack.artist) {
      currentTrack.updateFrom(track);
      // search for an image cover
      ResponseBandcamp resp = await searchBandcamp(
          '${track.title} ${track.album} ${track.artist}', 't');
      if (resp.imageUrl.isNotEmpty) {
        currentTrack.imageUrl = resp.imageUrl;
        if (resp.duration.isNotEmpty) {
          currentTrack.duration = resp.duration;
        }
      } else {
        resp = await searchBandcamp('${track.title} ${track.artist}', 't');
        if (resp.imageUrl.isNotEmpty) {
          currentTrack.imageUrl = resp.imageUrl;
        } else {
          resp = await searchBandcamp('${track.album} ${track.artist}', 'a');
          if (resp.imageUrl.isNotEmpty) {
            currentTrack.imageUrl = resp.imageUrl;
          } else {
            // try with discogs
            ResponseDiscogs resp = await searchDiscogs({
              'artist': track.artist,
              'q': track.album,
            });
            if (resp.imageUrl.isNotEmpty) {
              currentTrack.imageUrl = resp.imageUrl;
            }
          }
        }
      }
      notifyListeners();
      ret += 1;
    }
    return ret;
  }

  @override
  Future<List<Track>> getRecentTracks() async {
    // get timezone and current date of San Francisco
    tz.initializeTimeZones();
    tz.Location sanFrancisco = tz.getLocation('America/Los_Angeles');
    tz.TZDateTime now = tz.TZDateTime.now(sanFrancisco);
    String timeZone = convertSecondsToHours(
        sanFrancisco.timeZone(now.millisecondsSinceEpoch).offset ~/ 1000);
    String currentDate = now.toString().substring(0, 10);

    WebScraper webScraper = WebScraper('https://somafm.com');

    List<Track> ret = <Track>[];
    String page = '/recent/${subchannel.codename}.html';
    bool isLoaded = false;
    try {
      isLoaded = await webScraper.loadWebPage(page);
    } on WebScraperException catch (e) {
      print(e.errorMessage());
    }
    if (isLoaded) {
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
            );
            ret.add(track);
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

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'helpers.dart';
import 'myextensions.dart';

class LastSongListRoute extends StatelessWidget {
  const LastSongListRoute({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ChannelManager>(
      builder: (context, cm, child) {
        final recentTracks = cm.currentChannel.recentTracks;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Recently played songs'),
          ),
          body: Container(
            alignment: recentTracks.isNotEmpty
                ? Alignment.topCenter
                : Alignment.center,
            child: recentTracks.isNotEmpty
                //? _buildListItemSong(recentTracks)
                ? SingleChildScrollView(
                    child: DataTableSong(
                        tracks: recentTracks, channel: cm.currentChannel))
                : const Text('Nothing to show here'),
          ),
        );
      },
    );
  }
}

class DataTableSong extends StatelessWidget {
  final List<Track> tracks;
  final Channel channel;
  const DataTableSong({super.key, required this.tracks, required this.channel});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      bool isSmallScreen;
      if (constraints.maxWidth > 1000) {
        isSmallScreen = false;
      } else {
        isSmallScreen = true;
      }
      final int empties = tracks.where((e) => e.album == 'Album').length;
      // remove last column (Album) if none is defined
      if (empties == tracks.length) {
        isSmallScreen = true;
      }
      List<DataColumn> columns = <DataColumn>[
        DataColumn(
          label: Expanded(
            child: Text(
              'Time',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Theme.of(context).primaryColor),
            ),
          ),
        ),
        const DataColumn(
          label: Expanded(
            child: Text(
              'Artist',
              style: TextStyle(
                  fontStyle: FontStyle.normal,
                  fontWeight: FontWeight.bold,
                  fontSize: 20),
            ),
          ),
        ),
        const DataColumn(
          label: Expanded(
            child: Text(
              'Title',
              style: TextStyle(
                  fontStyle: FontStyle.normal,
                  fontWeight: FontWeight.normal,
                  fontSize: 20),
            ),
          ),
        ),
      ];
      if (!isSmallScreen) {
        columns.add(
          const DataColumn(
            label: Expanded(
              child: Text(
                'Album',
                style: TextStyle(
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.normal,
                    fontSize: 20),
              ),
            ),
          ),
        );
      }
      final rows = <DataRow>[];
      for (var track in tracks) {
        String dd = track.diffusionDate.split('T')[1].substring(0, 8);
        List<DataCell> cells = [
          DataCell(Text(dd,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor))),
          DataCell(Text(track.artist.toTitleCase(),
              style: const TextStyle(fontWeight: FontWeight.bold))),
          DataCell(Text(track.title.toTitleCase())),
        ];
        // add album only is screen is large enough
        if (!isSmallScreen) {
          cells.add(DataCell(Text(track.album != 'Album' ? track.album : '---',
              style: const TextStyle(fontStyle: FontStyle.italic))));
        }
        rows.add(DataRow(cells: cells));
      }
      return Column(
        children: [
          Center(
              child: Container(
                  padding: const EdgeInsets.all(15),
                  child: Text('${channel.radio} / ${channel.show.name}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 20)))),
          DataTable(
              headingRowColor: MaterialStateProperty.resolveWith<Color?>(
                  (Set<MaterialState> states) {
                return Theme.of(context).secondaryHeaderColor;
              }),
              columns: columns,
              rows: rows),
        ],
      );
    });
  }
}

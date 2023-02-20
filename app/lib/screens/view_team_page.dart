import 'dart:convert';
import 'dart:typed_data';

import 'package:app/datasheet.dart';
import 'package:app/edit_lock.dart';
import 'package:app/fieldwidget.dart';
import 'package:app/helpers.dart';
import 'package:app/main.dart';
import 'package:app/match_card.dart';
import 'package:app/screens/match_page.dart';
import 'package:app/screens/scout_team.dart';
import 'package:app/scouting_tools/scouting_tool.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:snout_db/event/pitscoutresult.dart';
import 'package:snout_db/config/surveyitem.dart';
import 'package:snout_db/snout_db.dart';

class TeamViewPage extends StatefulWidget {
  final int teamNumber;

  const TeamViewPage({Key? key, required this.teamNumber}) : super(key: key);

  @override
  State<TeamViewPage> createState() => _TeamViewPageState();
}

class _TeamViewPageState extends State<TeamViewPage> {
  @override
  Widget build(BuildContext context) {
    final snoutData = context.watch<EventDB>();
    return Scaffold(
        appBar: AppBar(
          actions: [
            TextButton(
                onPressed: () async {
                  //Get existing scouting data.
                  var result = await navigateWithEditLock(
                      context,
                      "scoutteam:${widget.teamNumber}",
                      () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => PitScoutTeamPage(
                                    team: widget.teamNumber,
                                    config: snoutData.db.config,
                                    oldData: snoutData.db.pitscouting[
                                        widget.teamNumber.toString()])),
                          ));
                  if (result != null) {
                    //Data has been saved
                    setState(() {});
                  }
                },
                child: const Text("Scout"))
          ],
          title: Text("Team ${widget.teamNumber}"),
        ),
        body: ListView(
          shrinkWrap: true,
          children: [
            ScoutingResultsViewer(
                teamNumber: widget.teamNumber, snoutData: snoutData),
            const Divider(height: 32),
            //Display this teams matches

            Center(
                child: Text("Average Metrics",
                    style: Theme.of(context).textTheme.titleLarge)),
            for (final eventType in snoutData.db.config.matchscouting.events)
              ListTile(
                title: Text(eventType.label),
                subtitle: Text(numDisplay((snoutData.db
                        .matchesWithTeam(widget.teamNumber)
                        .fold<int>(
                            0,
                            (previousValue, match) =>
                                previousValue +
                                (match.robot[widget.teamNumber.toString()]
                                        ?.timeline
                                        .where(
                                            (event) => event.id == eventType.id)
                                        .length ??
                                    0)) /
                    snoutData.db
                        .matchesWithTeam(widget.teamNumber)
                        .where((element) =>
                            element.robot[widget.teamNumber.toString()] != null)
                        .length))),
              ),

            const Divider(height: 32),

            Center(
                child: Text("Per Match Metrics",
                    style: Theme.of(context).textTheme.titleLarge)),

            DataSheet(
              //Data is a list of rows and columns
              columns: [
                DataItem.fromText("Match"),
                for (final event in snoutData.db.config.matchscouting.events)
                  DataItem.fromText(event.label),
                for (final pitSurvey in snoutData
                    .db.config.matchscouting.postgame
                    .where((element) => element.type != SurveyItemType.picture))
                  DataItem.fromText(pitSurvey.label),
              ],
              rows: [
                for (final match
                    in snoutData.db.matchesWithTeam(widget.teamNumber))
                  [
                    DataItem(
                        displayValue: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => MatchPage(
                                        matchid: snoutData.db
                                            .matchIDFromMatch(match))),
                              );
                            },
                            child: Text(
                              match.description,
                              style: TextStyle(
                                  color: getAllianceColor(
                                      match.getAllianceOf(widget.teamNumber))),
                            )),
                        exportValue: match.description,
                        sortingValue: match.scheduledTime),
                    for (final eventId
                        in snoutData.db.config.matchscouting.events)
                      DataItem.fromNumber(match
                          .robot[widget.teamNumber.toString()]?.timeline
                          .where((event) => event.id == eventId.id)
                          .length
                          .toDouble()),
                    for (final pitSurvey in snoutData
                        .db.config.matchscouting.postgame
                        .where((element) =>
                            element.type != SurveyItemType.picture))
                      DataItem.fromText(match
                          .robot[widget.teamNumber.toString()]
                          ?.survey[pitSurvey.id]
                          ?.toString()),
                  ],
              ],
            ),

            const Divider(height: 32),

            Column(
              children: [
                Text("Starting Positions",
                    style: Theme.of(context).textTheme.titleLarge),
                FieldHeatMap(
                    useRedNormalized: true,
                    events:
                        snoutData.db.matchesWithTeam(widget.teamNumber).fold(
                            [],
                            (previousValue, element) => [
                                  ...previousValue,
                                  ...?element
                                      .robot[widget.teamNumber.toString()]
                                      ?.timeline
                                      .where((event) =>
                                          event.id == "robot_position" &&
                                          event.time == 0)
                                ])),
                const SizedBox(height: 16),
                Text("Auto Positions",
                    style: Theme.of(context).textTheme.titleLarge),
                FieldHeatMap(
                    useRedNormalized: true,
                    events:
                        snoutData.db.matchesWithTeam(widget.teamNumber).fold(
                            [],
                            (previousValue, element) => [
                                  ...previousValue,
                                  ...?element
                                      .robot[widget.teamNumber.toString()]
                                      ?.timelineInterpolated()
                                      .where((event) =>
                                          event.id == "robot_position" &&
                                          event.isInAuto)
                                ])),
                const SizedBox(height: 16),
                for (final eventType
                    in snoutData.db.config.matchscouting.events) ...[
                  const SizedBox(height: 16),
                  Text(eventType.label,
                      style: Theme.of(context).textTheme.titleLarge),
                  FieldHeatMap(
                      useRedNormalized: true,
                      events:
                          snoutData.db.matchesWithTeam(widget.teamNumber).fold(
                              [],
                              (previousValue, element) => [
                                    ...previousValue,
                                    ...?element
                                        .robot[widget.teamNumber.toString()]
                                        ?.timeline
                                        .where(
                                            (event) => event.id == eventType.id)
                                  ])),
                ],
                const Divider(height: 32),
                Center(
                    child: Text("Schedule",
                        style: Theme.of(context).textTheme.titleLarge)),
                for (var match
                    in snoutData.db.matchesWithTeam(widget.teamNumber))
                  MatchCard(match: match, focusTeam: widget.teamNumber),
              ],
            ),
          ],
        ));
  }
}

class ScoutingResultsViewer extends StatelessWidget {
  final int teamNumber;
  final EventDB snoutData;

  const ScoutingResultsViewer(
      {Key? key, required this.teamNumber, required this.snoutData})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    var data = snoutData.db.pitscouting[teamNumber.toString()];

    if (data == null) {
      return const ListTile(title: Text("Team has no pit scouting data"));
    }

    return Column(
      children: [
        for (var item in snoutData.db.config.pitscouting)
          ScoutingResult(item: item, survey: data)
      ],
    );
  }
}

class ScoutingResult extends StatelessWidget {
  final SurveyItem item;
  final PitScoutResult survey;

  const ScoutingResult({Key? key, required this.item, required this.survey})
      : super(key: key);

  dynamic get value => survey[item.id];

  @override
  Widget build(BuildContext context) {
    if (value == null) {
      return Container();
    }

    // print(item.type);

    if (item.type == SurveyItemType.picture) {
      return ListTile(
        title: Text(item.label),
        subtitle: SizedBox(
            height: scoutImageSize,
            child: Image.memory(
              Uint8List.fromList(base64Decode(value).cast<int>()),
            )),
      );
    }

    return ListTile(
      title: Text(value.toString()),
      subtitle: Text(item.label),
    );
  }
}

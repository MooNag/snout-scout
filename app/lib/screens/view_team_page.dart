import 'dart:convert';
import 'dart:typed_data';

import 'package:app/widgets/datasheet.dart';
import 'package:app/edit_lock.dart';
import 'package:app/providers/data_provider.dart';
import 'package:app/widgets/edit_audit.dart';
import 'package:app/widgets/fieldwidget.dart';
import 'package:app/style.dart';
import 'package:app/screens/match_page.dart';
import 'package:app/screens/scout_team.dart';
import 'package:app/widgets/image_view.dart';
import 'package:app/widgets/timeduration.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:snout_db/event/match.dart';
import 'package:snout_db/event/pitscoutresult.dart';
import 'package:snout_db/config/surveyitem.dart';
import 'package:snout_db/patch.dart';

// Reserved pit scouting IDs that are used within the app
const String teamNameReserved = 'team_name';
const String robotPictureReserved = 'robot_picture';
const String teamNotesReserved = 'team_notes';

class TeamViewPage extends StatefulWidget {
  final int teamNumber;

  const TeamViewPage({super.key, required this.teamNumber});

  @override
  State<TeamViewPage> createState() => _TeamViewPageState();
}

class _TeamViewPageState extends State<TeamViewPage> {
  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();

    String? teamName =
        data.event.pitscouting[widget.teamNumber.toString()]?[teamNameReserved];
    String? robotPicture = data.event.pitscouting[widget.teamNumber.toString()]
        ?[robotPictureReserved];
    String? teamNotes = data.event.pitscouting[widget.teamNumber.toString()]
        ?[teamNotesReserved];

    FRCMatch? teamNextMatch = data.event.nextMatchForTeam(widget.teamNumber);
    Duration? scheduleDelay = data.event.scheduleDelay;

    return Scaffold(
        appBar: AppBar(
          actions: [
            TextButton(
                onPressed: () async {
                  await navigateWithEditLock(
                      context,
                      "scoutteam:${widget.teamNumber}",
                      (context) => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => PitScoutTeamPage(
                                    team: widget.teamNumber,
                                    config: data.event.config,
                                    initialData: data.event.pitscouting[
                                        widget.teamNumber.toString()])),
                          ));
                },
                child: const Text("Scout"))
          ],
          title: Text("Team ${widget.teamNumber}"),
        ),
        body: ListView(
          cacheExtent: 5000,
          children: [
            Center(
              child: Text(
                teamName ?? teamNameReserved,
                style: Theme.of(context).textTheme.headlineLarge,
              ),
            ),
            if (teamNextMatch != null && scheduleDelay != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("next match"),
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => MatchPage(
                              matchid:
                                  data.event.matchIDFromMatch(teamNextMatch))),
                    ),
                    child: Text(
                      teamNextMatch.description,
                      style: TextStyle(
                          color: getAllianceColor(
                              teamNextMatch.getAllianceOf(widget.teamNumber))),
                    ),
                  ),
                  TimeDuration(
                      time: teamNextMatch.scheduledTime.add(scheduleDelay),
                      displayDurationDefault: true),
                ],
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(teamNotes ?? "No $teamNotesReserved value"),
                        ],
                      )),
                ),
                if (robotPicture != null)
                  SizedBox(
                    width: 240,
                    height: 240,
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: ImageViewer(
                        child: Image.memory(
                          fit: BoxFit.cover,
                          Uint8List.fromList(
                              base64Decode(robotPicture).cast<int>()),
                        ),
                      ),
                    ),
                  ),
                if (robotPicture == null)
                  const Text("No $robotPictureReserved :("),
              ],
            ),

            const Divider(),
            //Display this teams matches

            DataSheet(
              title: 'Metrics',
              //Data is a list of rows and columns
              columns: [
                DataItem.fromText("Metric"),
                for (final event in data.event.config.matchscouting.events)
                  DataItem.fromText(event.label),
              ],
              rows: [
                [
                  DataItem.fromText("All"),
                  for (final event in data.event.config.matchscouting.events)
                    DataItem.fromNumber(data.event
                        .teamAverageMetric(widget.teamNumber, event.id)),
                ],
                [
                  DataItem.fromText("Auto"),
                  for (final eventType
                      in data.event.config.matchscouting.events)
                    DataItem.fromNumber(data.event.teamAverageMetric(
                        widget.teamNumber,
                        eventType.id,
                        (event) => event.isInAuto)),
                ]
              ],
            ),

            const Divider(height: 16),

            Wrap(
              spacing: 12,
              alignment: WrapAlignment.center,
              children: [
                Column(
                  children: [
                    const SizedBox(height: 16),
                    Text("Autos",
                        style: Theme.of(context).textTheme.titleMedium),
                    AutoPathsViewer(
                      // Make it larger since its the team page so BIG
                      size: 600,
                      paths: [
                        for (final match in data.event
                            .teamRecordedMatches(widget.teamNumber))
                          match.value.robot[widget.teamNumber.toString()]!
                              .timelineInterpolatedRedNormalized(
                                  data.event.config.fieldStyle)
                              .where((element) => element.isInAuto)
                              .toList()
                      ],
                    ),
                  ],
                ),
                const Divider(height: 32),
                Center(
                    child: Text("Pit Scouting",
                        style: Theme.of(context).textTheme.titleLarge)),
                ScoutingResultsViewer(
                    teamNumber: widget.teamNumber, snoutData: data),
                const Divider(height: 32),
                DataSheet(
                  title: 'Matches',
                  //Data is a list of rows and columns
                  columns: [
                    DataItem.fromText("Match"),
                    for (final item
                        in data.event.config.matchscouting.processes)
                      DataItem.fromText(item.label),
                    for (final pitSurvey in data
                        .event.config.matchscouting.survey
                        .where((element) =>
                            element.type != SurveyItemType.picture))
                      DataItem.fromText(pitSurvey.label),
                    DataItem.fromText("Scout"),
                  ],
                  rows: [
                    //Show ALL matches the team is scheduled for ALONG with all matches they played regardless of it it is scheduled sorted
                    for (final match in <FRCMatch>{
                      ...data.event.matchesWithTeam(widget.teamNumber),
                      ...data.event
                          .teamRecordedMatches(widget.teamNumber)
                          .map((e) => e.value)
                    }.sorted((a, b) => Comparable.compare(a, b)))
                      [
                        DataItem(
                            displayValue: TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => MatchPage(
                                            matchid: data.event
                                                .matchIDFromMatch(match))),
                                  );
                                },
                                child: Text(
                                  match.description,
                                  style: TextStyle(
                                      color: getAllianceColor(match
                                          .getAllianceOf(widget.teamNumber))),
                                )),
                            exportValue: match.description,
                            sortingValue: match),
                        for (final item
                            in data.event.config.matchscouting.processes)
                          DataItem.fromErrorNumber(data.event
                                  .runMatchResultsProcess(
                                      item,
                                      match.robot[widget.teamNumber.toString()],
                                      widget.teamNumber) ??
                              //Missing results, this is not an error
                              (value: null, error: null)),
                        for (final pitSurvey in data
                            .event.config.matchscouting.survey
                            .where((element) =>
                                element.type != SurveyItemType.picture))
                          DataItem.fromText(match
                              .robot[widget.teamNumber.toString()]
                              ?.survey[pitSurvey.id]
                              ?.toString()),
                        DataItem.fromText(getAuditString(context
                            .watch<DataProvider>()
                            .database
                            .getLastPatchFor(Patch.buildPath([
                              'matches',
                              data.event.matchIDFromMatch(match),
                              'robot',
                              '${widget.teamNumber}'
                            ])))),
                      ],
                  ],
                ),
                const Divider(),
                for (final eventType in data.event.config.matchscouting.events)
                  Column(children: [
                    const SizedBox(height: 16),
                    Text(eventType.label,
                        style: Theme.of(context).textTheme.titleMedium),
                    FieldHeatMap(
                        events: data.event
                            .teamRecordedMatches(widget.teamNumber)
                            .fold(
                                [],
                                (previousValue, element) => [
                                      ...previousValue,
                                      ...?element.value
                                          .robot[widget.teamNumber.toString()]
                                          ?.timelineRedNormalized(
                                              data.event.config.fieldStyle)
                                          .where((event) =>
                                              event.id == eventType.id)
                                    ])),
                  ]),
                Column(
                  children: [
                    const SizedBox(height: 16),
                    Text("Driving Tendencies",
                        style: Theme.of(context).textTheme.titleMedium),
                    FieldHeatMap(
                        events: data.event
                            .teamRecordedMatches(widget.teamNumber)
                            .fold(
                                [],
                                (previousValue, element) => [
                                      ...previousValue,
                                      ...?element.value
                                          .robot[widget.teamNumber.toString()]
                                          ?.timelineInterpolatedRedNormalized(
                                              data.event.config.fieldStyle)
                                          .where(
                                              (event) => event.isPositionEvent)
                                    ])),
                  ],
                ),
              ],
            ),
          ],
        ));
  }
}

class ScoutingResultsViewer extends StatelessWidget {
  final int teamNumber;
  final DataProvider snoutData;

  const ScoutingResultsViewer(
      {super.key, required this.teamNumber, required this.snoutData});

  @override
  Widget build(BuildContext context) {
    final data = snoutData.event.pitscouting[teamNumber.toString()];
    if (data == null) {
      return const ListTile(title: Text("Team has no pit scouting data"));
    }
    return Column(
      children: [
        for (final item in snoutData.event.config.pitscouting) ...[
          ScoutingResult(item: item, survey: data),
          Container(
              padding: const EdgeInsets.only(right: 16),
              alignment: Alignment.centerRight,
              child: EditAudit(
                  path: Patch.buildPath(
                      ['pitscouting', '$teamNumber', item.id]))),
        ]
      ],
    );
  }
}

class ScoutingResult extends StatelessWidget {
  final SurveyItem item;
  final PitScoutResult survey;

  const ScoutingResult({super.key, required this.item, required this.survey});

  dynamic get value => survey[item.id];

  @override
  Widget build(BuildContext context) {
    if (value == null) {
      return ListTile(
        title: Text(item.label),
        subtitle: const Text(
          "NOT SET",
          style: TextStyle(color: warningColor),
        ),
      );
    }

    if (item.type == SurveyItemType.picture) {
      return ListTile(
        title: Text(item.label),
        subtitle: ImageViewer(
          child: Image.memory(
            height: 500,
            fit: BoxFit.contain,
            Uint8List.fromList(base64Decode(value).cast<int>()),
          ),
        ),
      );
    }

    return ListTile(
      title: Text(item.label),
      subtitle: Text(value.toString()),
    );
  }
}

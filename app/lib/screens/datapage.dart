import 'package:app/datasheet.dart';
import 'package:app/helpers.dart';
import 'package:app/main.dart';
import 'package:app/screens/match_page.dart';
import 'package:app/screens/view_team_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:snout_db/config/surveyitem.dart';

class DataTablePage extends StatefulWidget {
  const DataTablePage({super.key});

  @override
  State<DataTablePage> createState() => _DataTablePageState();
}

class _DataTablePageState extends State<DataTablePage> {
  @override
  Widget build(BuildContext context) {
    final data = context.watch<EventDB>();
    return ListView(
      shrinkWrap: true,
      children: [
        SingleChildScrollView(
          child: DataSheet(
            title: 'Teams',
            columns: [
            DataItem.fromText("Team"),
            DataItem.fromText("Played"),
            for (final eventType in data.db.config.matchscouting.events)
              DataItem.fromText("avg\n${eventType.label}"),
            for (final pitSurvey in data.db.config.pitscouting
                .where((element) => element.type != SurveyItemType.picture))
              DataItem.fromText(pitSurvey.label),
          ], rows: [
            for (final team in data.db.teams)
              [
                DataItem(
                    displayValue: TextButton(
                      child: Text(team.toString()),
                      onPressed: () {
                        //Open this teams scouting page
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => TeamViewPage(teamNumber: team)),
                        );
                      },
                    ),
                    exportValue: team.toString(),
                    sortingValue: team),
                DataItem.fromNumber(data.db
                    .matchesWithTeam(team)
                    .where((element) => element.results != null)
                    .length
                    .toDouble()),
                for (final eventType in data.db.config.matchscouting.events)
                  DataItem.fromNumber(data.db.teamAverageMetric(team, eventType.id)),
                for (final pitSurvey in data.db.config.pitscouting
                    .where((element) => element.type != SurveyItemType.picture))
                  DataItem.fromText(data
                          .db.pitscouting[team.toString()]?[pitSurvey.id]
                          ?.toString())
              ]
          ]),
        ),


        DataSheet(
            title: 'Match Recordings',
            //Data is a list of rows and columns
            columns: [
              DataItem.fromText("Match"),
              DataItem.fromText("Team"),
              for (final item in data.db.config.matchscouting.events)
                DataItem.fromText(item.label),
              for (final item in data.db.config.matchscouting.postgame)
                DataItem.fromText(item.label),
            ],
            rows: [
              for (final match in data.db.matches.entries)
                for(final robot in match.value.robot.entries)
                [
                  DataItem(
                      displayValue: TextButton(
                        child: Text(match.value.description),
                        onPressed: () {
                          //Open this teams scouting page
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    MatchPage(matchid: match.key)),
                          );
                        },
                      ),
                      exportValue: match.value.description,
                      sortingValue: match.value.scheduledTime),
                  DataItem(
                      displayValue: TextButton(
                        child: Text(robot.key,
                            style: TextStyle(
                                color: getAllianceColor(
                                    match.value.getAllianceOf(int.parse(robot.key))))),
                        onPressed: () {
                          //Open this teams scouting page
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    TeamViewPage(teamNumber: int.parse(robot.key))),
                          );
                        },
                      ),
                      exportValue: robot.key,
                      sortingValue: robot.key),
                  for (final item in data.db.config.matchscouting.events)
                    DataItem.fromNumber(match.value.robot[robot.key]?.timeline
                        .where((event) => event.id == item.id)
                        .length
                        .toDouble()),
                  for (final item in data.db.config.matchscouting.postgame
                      .where(
                          (element) => element.type != SurveyItemType.picture))
                    DataItem.fromText(match.value
                        .robot[robot.key]?.survey[item.id]
                        ?.toString()),
                ],
            ],
          ),

      ],
    );
  }
}

import 'package:app/screens/analysis/boxplot_analysis.dart';
import 'package:app/screens/analysis/events_heatmaps.dart';
import 'package:app/screens/analysis/heatmap_event_type.dart';
import 'package:app/screens/analysis/match_preview.dart';
import 'package:app/screens/analysis/pitscout_survey_analysis.dart';
import 'package:app/screens/analysis/postmatch_survey_analysis.dart';
import 'package:app/screens/analysis/table_match_recordings.dart';
import 'package:app/screens/analysis/table_team_averages.dart';
import 'package:app/screens/analysis/table_team_scouting.dart';
import 'package:flutter/material.dart';

class AnalysisPage extends StatefulWidget {
  const AnalysisPage({super.key});

  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage> {
  @override
  Widget build(BuildContext context) {
    return ListView(children: [
      const Text(
          "Scoreboard (shows average value of all metrics for each team, like heatmaps) - Metrics Explorer - Maybe allow for more 'sql' like queries here?? - Scatter plot!!! AND PLOT FOR METRIC OVER TIME"),
      ListTile(
        title: const Text("Pit Survey"),
        leading: const Icon(Icons.table_chart),
        onTap: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (builder) => const TableTeamPitSurvey()));
        },
      ),
      ListTile(
        title: const Text("Team Averages"),
        leading: const Icon(Icons.table_chart),
        onTap: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (builder) => const TableTeamAveragesPage()));
        },
      ),
      ListTile(
        title: const Text("Match Recordings"),
        leading: const Icon(Icons.table_chart),
        onTap: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (builder) => const TableMatchRecordingsPage()));
        },
      ),
      ListTile(
        title: const Text("Consistency Analysis"),
        leading: const Icon(Icons.candlestick_chart_outlined),
        onTap: () {
          Navigator.push(context,
              MaterialPageRoute(builder: (builder) => const BoxPlotAnalysis()));
        },
      ),
      ListTile(
        title: const Text("Match Preview"),
        leading: const Icon(Icons.preview),
        onTap: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (builder) =>
                      const AnalysisMatchPreview(red: [], blue: [])));
        },
      ),
      ListTile(
        title: const Text("Heatmap by Event Type"),
        leading: const Icon(Icons.map),
        onTap: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (builder) => const AnalysisHeatMapByEventType()));
        },
      ),
      ListTile(
        title: const Text("Event Heatmap Analysis"),
        leading: const Icon(Icons.map),
        onTap: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (builder) => const AnalysisEventsHeatmap()));
        },
      ),
      ListTile(
        title: const Text("Pit Survey Analysis"),
        leading: const Icon(Icons.pie_chart),
        onTap: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (builder) => const AnalysisPitScouting()));
        },
      ),
      ListTile(
        title: const Text("Match Recording Survey Analysis"),
        leading: const Icon(Icons.pie_chart),
        onTap: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (builder) => const AnalysisPostMatchSurvey()));
        },
      ),
    ]);
  }
}

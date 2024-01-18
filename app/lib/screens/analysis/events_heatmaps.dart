import 'package:app/providers/data_provider.dart';
import 'package:app/widgets/fieldwidget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AnalysisEventsHeatmap extends StatelessWidget {
  const AnalysisEventsHeatmap({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text("Events Heatmap Analysis"),
      ),
      body: ListView(
        children: [
          Text("Autos", style: Theme.of(context).textTheme.titleMedium),
          AutoPathsViewer(
            paths: [
              for (final match in data.event.matches.values)
                for (final robot in match.robot.entries)
                  match.robot[robot.key]!.timelineInterpolated
                      .where((element) => element.isInAuto)
                      .toList()
            ],
          ),
          for (final eventType in data.event.config.matchscouting.events) ...[
            const SizedBox(height: 16),
            Text(eventType.label,
                style: Theme.of(context).textTheme.titleMedium),
            FieldHeatMap(
                events: data.event.matches.values.fold(
                    [],
                    (previousValue, element) => [
                          ...previousValue,
                          ...element.robot.values.fold(
                              [],
                              (previousValue, element) => [
                                    ...previousValue,
                                    ...element
                                        .timelineRedNormalized(
                                            data.event.config.fieldStyle)
                                        .where(
                                            (event) => event.id == eventType.id)
                                  ])
                        ])),
          ],
        ],
      ),
    );
  }
}

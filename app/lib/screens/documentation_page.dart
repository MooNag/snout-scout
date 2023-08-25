import 'dart:convert';
import 'dart:typed_data';

import 'package:app/providers/data_provider.dart';
import 'package:app/screens/debug_field_position.dart';
import 'package:app/widgets/markdown_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher_string.dart';

class DocumentationScreen extends StatefulWidget {
  const DocumentationScreen({super.key});

  @override
  State<DocumentationScreen> createState() => _DocumentationScreenState();
}

class _DocumentationScreenState extends State<DocumentationScreen> {
  bool _showDetails = false;

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>().event.config;

    final pitMap = context.watch<DataProvider>().event.pitmap;

    return ListView(
      //helps keep the scrollbar consistent at the cost of performance
      cacheExtent: 5000,
      children: [
        ListTile(
          title: const Text("Snout Scout docs"),
          leading: const Icon(Icons.menu_book),
          onTap: () => launchUrlString(
              "https://github.com/mootw/snout-scout/blob/main/readme.md"),
        ),
        ListTile(
          title: const Text("DEBUG Field position"),
          leading: const Icon(Icons.crop_square_sharp),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const DebugFieldPosition()),
            );
          },
        ),
        const Divider(),
        if (pitMap != null)
          ListTile(
            title: const Text("VIEW PIT MAP"),
            leading: const Icon(Icons.map),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => Scaffold(
                          appBar: AppBar(
                            title: const Text("Pit Map"),
                          ),
                          body: SingleChildScrollView(
                            child: Image.memory(
                              fit: BoxFit.fitWidth,
                              scale: 0.5,
                              Uint8List.fromList(
                                  base64Decode(pitMap).cast<int>()),
                            ),
                          ),
                        )),
              );
            },
          ),
        if (pitMap == null)
          const ListTile(title: Text("No pit map has been added yet :(")),
        const Divider(),
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 16),
          child: MarkdownText(
              data: data.docs.isNotEmpty
                  ? data.docs
                  : "# Welcome to the docs for ${data.name}\n**this is a temporary message that will be replaced once you set the docs property in the event config**\n\neverything that you collect should be defined in here, all 'docs' properties in the configuration support markdown"),
        ),
        const Divider(),
        ListTile(
          title: const Text("Show Technical Details"),
          trailing: Switch(
            value: _showDetails,
            onChanged: (value) => setState(() {
              _showDetails = value;
            }),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Text("Pit Scouting",
              style: Theme.of(context).textTheme.titleLarge),
        ),
        for (final item in data.pitscouting) ...[
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 16),
            child: Text(item.label,
                style: Theme.of(context).textTheme.titleMedium),
          ),
          if (_showDetails)
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Text("id: ${item.id}",
                  style: Theme.of(context).textTheme.bodySmall),
            ),
          if (_showDetails)
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Text("type: ${item.type}",
                  style: Theme.of(context).textTheme.bodySmall),
            ),
          if (_showDetails)
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Text("options: ${item.options}",
                  style: Theme.of(context).textTheme.bodySmall),
            ),
          Padding(
            padding: const EdgeInsets.only(left: 32, top: 4, right: 16),
            child: MarkdownText(data: item.docs),
          )
        ],
        const Divider(),
        Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Text("Match Events",
              style: Theme.of(context).textTheme.titleLarge),
        ),
        for (final item in data.matchscouting.events) ...[
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 16),
            child: Text(item.label,
                style: Theme.of(context).textTheme.titleMedium),
          ),
          if (_showDetails)
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Text("color: ${item.color}",
                  style: Theme.of(context).textTheme.bodySmall),
            ),
          if (_showDetails)
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Text("id: ${item.id}",
                  style: Theme.of(context).textTheme.bodySmall),
            ),
          Padding(
            padding: const EdgeInsets.only(left: 32, top: 4, right: 16),
            child: MarkdownText(data: item.docs),
          )
        ],
        const Divider(),
        Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Text("Match Survey",
              style: Theme.of(context).textTheme.titleLarge),
        ),
        for (final item in data.matchscouting.survey) ...[
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 16),
            child: Text(item.label,
                style: Theme.of(context).textTheme.titleMedium),
          ),
          if (_showDetails)
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Text("id: ${item.id}",
                  style: Theme.of(context).textTheme.bodySmall),
            ),
          if (_showDetails)
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Text("type: ${item.type}",
                  style: Theme.of(context).textTheme.bodySmall),
            ),
          if (_showDetails)
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Text("options: ${item.options}",
                  style: Theme.of(context).textTheme.bodySmall),
            ),
          Padding(
            padding: const EdgeInsets.only(left: 32, top: 4, right: 16),
            child: MarkdownText(data: item.docs),
          )
        ],
        const Divider(),
        Padding(
          padding: const EdgeInsets.only(left: 16),
          child:
              Text("Processes", style: Theme.of(context).textTheme.titleLarge),
        ),
        for (final item in data.matchscouting.processes) ...[
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 16),
            child: Text(item.label,
                style: Theme.of(context).textTheme.titleMedium),
          ),
          if (_showDetails)
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Text("id: ${item.id}",
                  style: Theme.of(context).textTheme.bodySmall),
            ),
          if (_showDetails)
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Text("expression: ${item.expression}",
                  style: Theme.of(context).textTheme.bodySmall),
            ),
          Padding(
            padding: const EdgeInsets.only(left: 32, top: 4, right: 16),
            child: MarkdownText(data: item.docs),
          )
        ],
      ],
    );
  }
}

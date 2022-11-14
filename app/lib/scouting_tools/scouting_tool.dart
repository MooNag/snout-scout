//Data class that handles scouting tool things

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:snout_db/event/pitscoutresult.dart';
import 'package:snout_db/config/surveyitem.dart';

double scoutImageSize = 420;

class ScoutingToolWidget extends StatefulWidget {
  final SurveyItem tool;
  final PitScoutResult survey;

  const ScoutingToolWidget({Key? key, required this.tool, required this.survey})
      : super(key: key);

  @override
  State<ScoutingToolWidget> createState() => _ScoutingToolWidgetState();
}

class _ScoutingToolWidgetState extends State<ScoutingToolWidget> {
  final myController = TextEditingController();

  get value => widget.survey[widget.tool.id];
  set value (dynamic newValue) => widget.survey[widget.tool.id] = newValue;

  @override
  void initState() {
    super.initState();
    if (value == null && widget.tool.type == SurveyItemType.toggle) {
      value = false;
    }
    if (widget.tool.type == SurveyItemType.text || widget.tool.type == SurveyItemType.number) {
      myController.text = value?.toString() ?? "";
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.tool.type == SurveyItemType.text) {
      return TextField(
        controller: myController,
        onChanged: (text) {
          value = text;
          //TO prevent previously filled but now unfilled data from showing as empty.
          if (text == "") {
            value = null;
          }
        },
        minLines: 1,
        maxLines: 4,
        decoration: InputDecoration(
          label: Text(widget.tool.label),
          border: const OutlineInputBorder(),
        ),
      );
    }

    if (widget.tool.type == SurveyItemType.number) {
      return TextField(
        controller: myController,
        onChanged: (text) {
          value = num.tryParse(text);
        },
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          label: Text(widget.tool.label),
          border: const OutlineInputBorder(),
        ),
      );
    }

    if (widget.tool.type == SurveyItemType.selector) {
      return ListTile(
        title: Text(widget.tool.label),
        trailing: DropdownButton<String>(
          value: value,
          icon: const Icon(Icons.arrow_downward),
          onChanged: (String? newValue) {
            setState(() {
              value = newValue!;
            });
          },
          items: widget.tool.options!
              .map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        ),
      );
    }

    if (widget.tool.type == SurveyItemType.toggle) {
      return ListTile(
        title: Text(widget.tool.label),
        trailing: Switch(
            value: value,
            onChanged: (newValue) {
              setState(() {
                value = newValue;
              });
            }),
      );
    }

    if (widget.tool.type == SurveyItemType.picture) {
      return ListTile(
        leading: IconButton(
            icon: const Icon(Icons.camera_alt),
            onPressed: () async {
              //TAKE PHOTO
              final ImagePicker picker = ImagePicker();
              final XFile? photo = await picker.pickImage(source: ImageSource.camera, maxWidth: scoutImageSize, maxHeight: scoutImageSize, imageQuality: 50);
              if(photo != null) {
                Uint8List bytes = await photo.readAsBytes();
                setState(() {
                  value = base64Encode(bytes);
                });
              }
            }),
        title: Text(widget.tool.label),
        subtitle: value == null ? const Text("No Image") : SizedBox(height: scoutImageSize, child: Image.memory(Uint8List.fromList(base64Decode(value).cast<int>()))),
      );
    }

    return Text("Unknown tool ${widget.tool.id}");
  }
}

import 'package:json_annotation/json_annotation.dart';
import 'package:snout_db/event/pitscoutresult.dart';
import 'match.dart';
import 'package:collection/collection.dart';

part 'frcevent.g.dart';

@JsonSerializable()
class FRCEvent {
  
  ///Human readable name for this event (the one displayed on the status bar)
  String name;
  ///List of teams in the event, ideally ordered smallest number to largest
  List<int> teams;
  ///List of matches
  List<FRCMatch> matches;
  Map<String, PitScoutResult> pitscouting;


  //Returns sorted matches
  get sortedMatches => matches.sort((a, b) => a.scheduledTime.difference(b.scheduledTime).inMilliseconds);

  FRCEvent({required this.name, required this.teams, required this.matches, required this.pitscouting});

  factory FRCEvent.fromJson(Map<String, dynamic> json) => _$FRCEventFromJson(json);
  Map<String, dynamic> toJson() => _$FRCEventToJson(this);

  
  List<FRCMatch> matchesWithTeam (int team) => matches.where((match) => match.hasTeam(team)).toList();
  //returns the match after the last match with results
  FRCMatch? get nextMatch => matches.reversed.lastWhereOrNull((match) => match.results == null);

  FRCMatch? nextMatchForTeam (int team) => matchesWithTeam(team).reversed.lastWhereOrNull((match) => match.results == null);

  //Calculates the schedule delay by using the delay of the last match with results actual time versus the scheduled time.
  Duration? get scheduleDelay => matches.lastWhereOrNull((match) => match.results != null)?.scheduleDelay;
}
